# ADR-0004: Custom Cloud Kernel Build and Hardware Performance Architecture

- **Status**: Aceito (Accepted)
- **Data**: 2026-11-03
- **Decisores**: Nepo (Usuário / Product Owner), Antigravity (Argon / Flash)
- **Contexto Técnico**: HP Elite c1030 Chromebook (`jinlon`), Intel Core i7-10610U Comet Lake-U, GooglebookOS (`gbOS86`).

---

## Contexto e Problema

Durante a validação prática do GooglebookOS instalado no SSD interno NVMe (`nvme0n1p4`), foram diagnosticados problemas graves de controle térmico, ruído de ventoinha (100%), incompatibilidade de dongle USB de gamepad, desfoque de tela e travamentos por timeout (ANR) em aplicativos ARM64 (CapCut, Cutwire Drift, Concat):
1. Os módulos térmicos ACPI e o driver de joystick do Linux falhavam com `Exec format error` por incompatibilidade com a `struct module` do kernel pré-compilado upstream #42/#43.
2. O firmware do ChromeOS EC entrava em modo de emergência térmica, mantendo a ventoinha em 100% o tempo todo.
3. Um processo contínuo de rastreamento KVM ftrace gerava 17,6 MB de I/O contínuo em disco, enquanto uma máquina virtual Debian rodava em segundo plano disputando CPU.
4. O console printk síncrono no framebuffer i915 causava contenção de travas e micro-travamentos na interface.
5. As regras do projeto (Constituição de Desenvolvimento, Regra 7) proíbem expressamente a compilação local de artefatos pesados quando for possível utilizar a infraestrutura de nuvem do GitHub Actions via GitHub CLI (`gh`).

---

## Decisão

1. **Compilação do Kernel via GitHub Actions Cloud**:
   - Implementar o workflow `.github/workflows/build-kernel.yml` e o script de patch [`scripts/patch-upstream-kernel.py`](../../scripts/patch-upstream-kernel.py).
   - Utilizar o protocolo Git nativo com clone raso (`git fetch --depth 1 origin $KSRC_COMMIT`) em vez de downloads de tarballs dinâmicos do Google Gitiles (que sofrem de truncamento e falhas de checksum).
   - Compilar o kernel customizado `6.18.21-gbos-whl #44` com os drivers de controle e joystick embutidos estaticamente no binário (`=y`):
     - `CONFIG_INPUT_JOYDEV=y`
     - `CONFIG_JOYSTICK_XPAD=y`
     - `CONFIG_JOYSTICK_XPAD_FF=y`
     - `CONFIG_JOYSTICK_XPAD_LEDS=y`
     - `CONFIG_INPUT_UINPUT=y`
   - Gerar a árvore completa de módulos térmicos ACPI (`int340x_thermal`, `intel_rapl_msr`, `processor_thermal_mbox`, `x86_pkg_temp_thermal`) assinados sob a mesma chave e struct da build #44 (`gbos-build-id: 6c5cc6d87ca5...`).

2. **Eliminação de Parasitas no Script de Boot (`hook.sh`)**:
   - Desativar a coleta contínua de `kvmtrace.txt` (KVM exit ftrace loop) por padrão, mantendo-a disponível apenas sob demanda com `KVM_TRACE=1`.

3. **Criação do Serviço Nativo de Desempenho ([`scripts/optimize.sh`](../../scripts/optimize.sh))**:
   - Criar e implantar o script acionado automaticamente pelo init do Android no evento `property:sys.boot_completed=1` como `root`:
     - **CPU**: Intel Speed Shift HWP EPP em `balance_performance` e Turbo Boost ativo até 4.90 GHz.
     - **Térmico / RAPL**: Limites de potência PL1 em 22W e PL2 em 35W para evitar estrangulamento térmico prematuro da CPU.
     - **GPU**: Piso de frequência elevado para 500 MHz na Intel UHD 620 para garantir 60 FPS estáveis na interface.
     - **RAM (16 GB)**: `vm.swappiness=10` e `vm.vfs_cache_pressure=50` para retenção máxima de aplicativos em cache de memória.
     - **SSD NVMe**: Escalonador de I/O em `none` e read-ahead em 512 KB.
     - **Printk**: Silenciamento do console para loglevel 3 em tempo de execução.
     - **VMs**: Finalização da máquina virtual Debian parasita (`com.android.virtualization.terminal`).
     - **ART DEX**: Threading de compilação fixado em 8 threads para o i7-10610U.

4. **Ajuste de Resolução Inteira 1:1**:
   - Alterar `DENSITY=160` em `gbos/gbos.cfg` para eliminar o borrado da escala fracionada (1.125x) no painel de 1920x1280.

---

## Consequências

### Positivas
- Respeito integral à Constituição de Desenvolvimento: 0% de uso de CPU local durante a compilação do kernel (48 minutos de build executados inteiramente na infraestrutura do GitHub Actions).
- Controle térmico restaurado: o ChromeOS EC recebe a telemetria térmica das zonas ACPI e controla a rotação da ventoinha dinamicamente, eliminando o ruído de turbina contínuo.
- Suporte imediato ao controle Gamesir Nova Lite via dongle 2.4G sem depender do carregamento tardio de módulos pelo userspace do Android.
- Aceleração substantiva da camada de tradução ARM (Houdini), prevenindo estouro de timeout (ANRs) em aplicativos como CapCut, Concat e Cutwire Drift.
- Imagem e módulos anteriores preservados com sufixo `.bak` no SSD para rollback instantâneo caso necessário.

### Negativas / Limitações
- Aplicativos puramente de 32 bits (`armeabi-v7a`) continuam inoperantes devido ao ABI do sistema operacional GSI ser estritamente 64 bits (`ro.product.cpu.abilist: x86_64,arm64-v8a; ro.product.cpu.abilist32: ''`).
- A compilação do kernel exige conexão com a internet para acionar o GitHub Actions e baixar os artefatos gerados.
