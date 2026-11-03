# Hardware Performance Architecture & Optimization — HP Elite c1030 (`jinlon`)

> **Document Version**: 1.0.0  
> **Target Hardware**: HP Elite c1030 Chromebook (`jinlon` / Comet Lake-U i7-10610U / 16 GB LPDDR4x / WDC SN520 NVMe)  
> **OS Environment**: GooglebookOS (`gbOS86` Android 17 Desktop GSI) dual-boot alongside Zorin OS 17.3  
> **Kernel Version**: `6.18.21-gbos-whl #44` (Custom build compiled via GitHub Actions)

---

## 1. Contexto e Diagnóstico Forense da Sessão de Boot

Após a instalação isolada do GooglebookOS no SSD interno (`nvme0n1p4`), o usuário realizou o primeiro teste prático de uso contínuo (registrado nos logs de `nvme0n1p4/gbos/logs/boot-3/`) e relatou cinco sintomas críticos de desempenho e compatibilidade:

1. **Desempenho lento e sensação de que o computador estava "sofrendo"**.
2. **Ventoinha em rotação máxima (100%) ininterrupta**.
3. **Receptor USB 2.4G do controle Gamesir Nova Lite inoperante** (enquanto o Bluetooth funcionou).
4. **Resolução borrada e estranha** em fontes e ícones.
5. **Comportamento discrepante entre aplicativos**:
   - *Clash Royale*: Funcionou perfeitamente a 60 FPS.
   - *Ibis Paint X*: Funcionou perfeitamente.
   - *CapCut PAD Pro*: Fechava instantaneamente na versão modificada; na versão da Play Store abria mas travava em loop contínuo de *"CapCut não está respondendo"* (ANR).
   - *Cutwire Drift* e *Concat*: Não abriam (tela preta e fechamento repentino).

A investigação forense conduzida nas partições `GBOSSYS` (`nvme0n1p4`) e `GBOS_DATA` (`nvme0n1p6`), bem como nos registros de kernel (`kmsg.log`), despejos do Android (`logcat`, `tombstones/` e `anr/`), revelou as causas técnicas exatas para cada sintoma.

---

## 2. Causas Técnicas Identificadas

### 2.1. Ventoinha a 100% e Modo de Emergência Térmica do EC
- **Causa Raiz**: O ChromeOS Embedded Controller (EC) do Chromebook monitora as zonas térmicas da placa-mãe via barramento LPC e ACPI (`INT3400`, `INT3403`, `intel_pch_thermal`). No kernel padrão (#42/#43), os módulos de gerenciamento térmico da Intel (`int340x_thermal_zone.ko`, `acpi_thermal_rel.ko`, `processor_thermal_mbox.ko`, `x86_pkg_temp_thermal.ko`) falharam ao carregar com o erro:
  ```text
  module int340x_thermal_zone: .gnu.linkonce.this_module section size must match the kernel's built struct module size at run time
  ueventd: Failed to insmod '/vendor/lib/modules/int340x_thermal_zone.ko': Exec format error
  ```
- **Consequência**: Sem receber telemetria de temperatura do sistema operacional, o firmware do ChromeOS EC entra imediatamente em **modo fail-safe de emergência**, travando a ventoinha em 100% da rotação e forçando o processador a um estado de economia e proteção térmica.

### 2.2. Falha do Dongle USB Gamesir Nova Lite 2.4G
- **Causa Raiz**: O receptor USB foi detectado na porta xHCI, mas o driver de joystick do Linux (`joydev.ko` e `xpad.ko`) também estava configurado como módulo externo (`.ko`) e sofreu o mesmo `Exec format error` por incompatibilidade de versão de struct de módulo.
- **Por que o Bluetooth funcionou?**: O Bluetooth opera na camada de espaço de usuário do Android através do driver genérico `uhid` (`/dev/uhid`), sem depender do módulo `joydev.ko` do kernel.

### 2.3. Resolução Borrada (Escala Fracionada a 1.125x)
- **Causa Raiz**: O painel eDP do HP c1030 possui proporção 3:2 com resolução nativa de **1920x1280** pixels (170 DPI físico).
- O arquivo de configuração original `gbos/gbos.cfg` definia `DENSITY=180`. Isso forçava o Android a aplicar uma escala fracionada de $180 / 160 = 1.125\times$, gerando interpolação bilinear contínua e blur evidente em todas as fontes e bordas da interface.

### 2.4. A Realidade dos Aplicativos: x86_64 Nativo vs ARM64 Houdini
A análise da partição de dados (`GBOS_DATA/app/` e `GBOS_DATA/anr/`) desvendou a disparidade entre os aplicativos:
- **Clash Royale e Ibis Paint X**: A Google Play Store detectou a arquitetura do processador e instalou pacotes divididos nativos para x86_64 (`split_config.x86_64.apk`). Os dois jogos rodaram código de máquina nativo Intel Core i7, com aceleração Vulkan Graphite completa.
- **CapCut PAD Pro, Cutwire Drift e Concat**: Todos contêm exclusivamente bibliotecas binárias compiladas para ARM64 (`arm64-v8a`). Eles são executados através da camada de tradução binária proprietária da Intel para Android, a **`libhoudini.so`**.
- Nos relatórios de ANR (`/data/anr/anr_*`), o processo principal de cada um desses aplicativos parou em:
  ```text
  "g.cutwire.drift" sysTid=29559
      #00 pc 0000000000321bc6  /system/lib64/libhoudini.so (BuildId: 2747b95bd407148e139ca403d595f9f954561741)
  Subject: Input dispatching timed out (... is not responding. Waited 5000ms for MotionEvent)
  ```
- **Por que o Houdini travava?**: A tradução JIT de bibliotecas ARM pesadas exige rajadas curtas de alta frequência de CPU. Com a CPU estrangulada pelos processos parasitas e pelo modo térmico de emergência, a compilação JIT inicial demorava mais que os 5.000 ms permitidos pelo Android para responder a eventos de toque, disparando o diálogo *"O app não está respondendo"*.

### 2.5. Processos Parasitas em Segundo Plano
- **Rastreamento KVM ftrace**: No arquivo `hook.sh` (linhas 656-667), o sistema ativava o rastreamento síncrono de todos os eventos de saída KVM (`kvm_exit`), gravando **17,6 MB** de dados brutos de ftrace em disco (`kvmtrace.txt`) através de um comando `dd` em segundo plano contínuo.
- **Máquina Virtual Debian**: O aplicativo de sistema `com.android.virtualization.terminal` subia uma máquina virtual Linux Debian via `crosvm` automaticamente em segundo plano, gerando milhares de saídas `EPT_VIOLATION` e disputando recursos com o Android.
- **Inundação de Printk no Framebuffer (`fbcon`)**: A linha de comando do kernel continha `ignore_loglevel loglevel=8 printk.devkmsg=on earlyprintk=efi,keep`. Cada mensagem de log do sistema era impressa na tela física, segurando travas síncronas (`console_lock`) no driver gráfico Intel i915 e gerando micro-travamentos na CPU.

---

## 3. Otimizações Implementadas

### 3.1. Kernel Customizado `6.18.21-gbos-whl #44` (Compilação Cloud)
Compilado na nuvem via **GitHub Actions** ([Workflow Run 41600493295](https://github.com/nepotira/gbos86-jinlon/actions/runs/41600493295)) para respeitar a Constituição de Desenvolvimento (Regra 7) sem sobrecarregar o hardware local:
- **Drivers de Gamepad Built-in (`=y`)**:
  - `CONFIG_INPUT_JOYDEV=y`
  - `CONFIG_JOYSTICK_XPAD=y`
  - `CONFIG_JOYSTICK_XPAD_FF=y`
  - `CONFIG_JOYSTICK_XPAD_LEDS=y`
  - `CONFIG_INPUT_UINPUT=y`
- **Módulos Térmicos Assinados**: Módulos ACPI `int340x_thermal_zone.ko`, `acpi_thermal_rel.ko`, `processor_thermal_mbox.ko`, `x86_pkg_temp_thermal.ko` e `intel_rapl_msr.ko` compilados rigorosamente contra a mesma assinatura de `struct module` da build #44 (`gbos-build-id: 6c5cc6d87ca5...`).
- **Integridade Criptográfica**: Imagem binária `BOOTX64.EFI` gerada com hash SHA-256 `96bceca9484468fead7cfb55b2571a1a18698339e455a24120c5618060ba42a9`, validada e implantada na ESP (`/boot/efi/EFI/gbos/BOOTX64.EFI`) e na partição `GBOSSYS` (`/EFI/BOOT/BOOTX64.EFI`).

### 3.2. Eliminação do Rastreamento KVM Parasita
No script `hook.sh`, o bloco de rastreamento síncrono KVM ftrace foi blindado com condicional:
```bash
if [ "${KVM_TRACE:-0}" = "1" ]; then
  # Executa rastreamento se expressamente solicitado para depuração
  ...
else
  log "hook: kvm tracing disabled (performance optimization)"
fi
```
Isso elimina **17,6 MB** de escrita contínua em disco durante cada inicialização e reduz a contenção de interrupções de CPU.

### 3.3. Serviço Nativo de Desempenho e Hardware (`scripts/optimize.sh`)
Criado o script executado pelo init do Android como `root` no evento `property:sys.boot_completed=1`:
1. **CPU Intel Speed Shift (HWP) & EPP**:
   - Forçado `energy_performance_preference=balance_performance` em todos os 8 núcleos lógicos.
   - Garantido `no_turbo=0` para desbloquear o Turbo Boost dinâmico até **4.90 GHz**.
   - Governor `schedutil` ajustado para resposta imediata a picos de carga.
2. **Intel RAPL Power Limits**:
   - PL1 (potência contínua): Elevado de 15W para **22W**.
   - PL2 (potência de pico): Elevado para **35W**, evitando que a CPU sofra redução agressiva para 800 MHz durante a inicialização de aplicativos pesados.
3. **Intel UHD 620 GPU Scaling**:
   - Piso de clock (`gt_min_freq_mhz`) elevado de 300 MHz para **500 MHz**, eliminando engasgos ao arrastar janelas e alternar tarefas.
   - Teto mantido em **1.150 MHz**.
4. **Memória LPDDR4x (16 GB) e Cache**:
   - `vm.swappiness=10`: Evita compressão desnecessária de memória RAM quando há mais de 14 GB livres.
   - `vm.vfs_cache_pressure=50`: Mantém os metadados de arquivos e bibliotecas de apps em cache de memória em vez de relê-los do SSD.
5. **SSD NVMe (Western Digital PC SN520)**:
   - Agendador de I/O definido como `none` (envio direto pela fila de hardware PCIe Gen3 x2 sem overhead de escalonador de CPU).
   - Leitura antecipada (`read_ahead_kb`) configurada para **512 KB** para acelerar carregamento de arquivos DEX e APKs grandes.
6. **Silenciamento de Printk**:
   - Nível do console ajustado para `echo "3 4 1 3" > /proc/sys/kernel/printk`, silenciando logs de debug e eliminando a disputa pela trava `console_lock` no framebuffer.
7. **Parada da VM Debian**:
   - Execução de `am force-stop com.android.virtualization.terminal` para desativar a máquina virtual parasita.
8. **Paralelismo do Compilador ART**:
   - `dalvik.vm.dex2oat-cpu-set=0,1,2,3,4,5,6,7` e `dalvik.vm.dex2oat-threads=8` para compilar código Java/Kotlin utilizando todos os 8 threads do i7.

### 3.4. Nitidez Visual e Resolução Nativa
- Ajustado `DENSITY=160` em `gbos/gbos.cfg`, estabelecendo proporção de pixels exata de 1:1 com o painel 1920x1280 e eliminando o borrado de renderização.

---

## 4. Matriz Comparativa de Comportamento

| Subsistema / Recurso | Estado Anterior (Boot-3) | Estado Atual Otimizado (Build #44) |
| :--- | :--- | :--- |
| **Controle Térmico / Ventoinha** | EC em modo fail-safe a 100% contínuo | Módulos térmicos carregados, EC regula dinamicamente |
| **Controle USB (Gamesir Nova Lite)** | Quebrado (`joydev.ko Exec format error`) | Funcional (`CONFIG_JOYSTICK_XPAD=y` e `joydev=y` built-in) |
| **Resolução / Fontes** | Borradas (`DENSITY=180`, escala 1.125x) | Nítidas (`DENSITY=160`, escala inteira 1:1) |
| **Piso de Clock da GPU** | 300 MHz (micro-travamentos de interface) | 500 MHz (fluidez em animações e janelas) |
| **Frequência e Turbo da CPU** | Frequência hesitante / conservadora | Speed Shift EPP `balance_performance` (até 4.90 GHz) |
| **Teto de Potência (PL1/PL2)** | Padrão restritivo de 10-15W | PL1 22W / PL2 35W via Intel RAPL |
| **Rastreamento KVM ftrace** | Ativo gravando 17,6 MB de log em disco | Desativado por padrão |
| **Máquina Virtual Debian** | Rodando em segundo plano (`crosvm`) | Finalizada no boot |
| **Uso da Memória RAM (16 GB)** | Políticas agressivas de descarte de cache | `swappiness=10` e retenção de cache na RAM |
| **Compilação ARM (Houdini)** | ANR por timeout de 5s sob sobrecarga | CPU com potência e folga térmica para tradução JIT |
