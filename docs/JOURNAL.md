# Engineering Journal (JOURNAL) — GooglebookOS on HP Elite c1030 (`jinlon`)

Este diário registra formalmente todas as decisões técnicas, descobertas forenses, comandos executados e alterações de sistema ao longo do ciclo de vida do projeto, em estrita conformidade com a Constituição de Desenvolvimento.

---

## [2026-10-29] Sessão 1 — Fundação do Projeto e Regras de Desenvolvimento
- **Agente**: Argon (Gemini 4 Argon, Medium)
- **Ações**:
  - Inicialização do repositório Git local em `~/gbos-work/gbos86-jinlon` no ramo `main`.
  - Configuração da identidade Git (`user.name=nepotira`, `user.email=132780217+nepotira@users.noreply.github.com`).
  - Estabelecimento das regras locais e globais do Antigravity (`~/.gemini/GEMINI.md`, `.agents/rules/`).
  - Criação do script de auditoria de segurança [`scripts/scan-sensitive.sh`](../scripts/scan-sensitive.sh) e gancho de pré-commit `.githooks/pre-commit`.
  - Coleta inicial da tabela de partições do SSD NVMe (`/dev/nvme0n1`).

---

## [2026-10-29] Sessão 2 — Diagnóstico de Hardware e Geração da Imagem USB
- **Agente**: Flash (Gemini 3.8 Flash, High)
- **Ações**:
  - Coleta do pacote de diagnóstico do HP c1030 (`jinlon-pack.tar.gz`) contendo ACPI DSDT, topologia PCI, codecs de áudio SOF e registradores de barramento.
  - Verificação de espaço em disco no SSD NVMe: confirmados 45,17 GiB não alocados no final do disco (`75852 MiB` a `122104 MiB`).
  - Clonagem dos fontes upstream do `gbos-x86` e construção em contêiner Docker da imagem `gbOS86-20261029.img` (tamanho: 6.712.983.552 bytes, SHA-256: `b748cc3068a2dc4fcf9778cce983d39c700e850d05ab6ba1893c4c6ca3131180`).
  - Gravação byte a byte no pendrive USB `/dev/sda` via `dd` e verificação com `cmp` (exit code 0).

---

## [2026-10-29] Sessão 3 — Teste em Hardware do Live USB e Validação de Áudio
- **Agente**: Flash / Argon
- **Ações**:
  - Usuário efetuou boot pelo pendrive USB no firmware MrChromebox UEFI.
  - Validados: display 1920x1280 3:2 com aceleração de hardware Vulkan Graphite, touchscreen, touchpad, alto-falantes estéreo via Intel SOF, conector P2 para fones e microfone digital (DMIC).
  - Elaboração do relatório de teste em hardware [`docs/test-reports/2026-10-29-live-usb-boot.md`](test-reports/2026-10-29-live-usb-boot.md).
  - Publicação da Release `v0.2.0` no GitHub.

---

## [2026-10-29] Sessão 4 — Instalação Dual-Boot Isolada no SSD NVMe
- **Agente**: Flash / Argon
- **Ações**:
  - Elaborado ADR-0002 ([`docs/decisions/0002-isolated-install.md`](decisions/0002-isolated-install.md)).
  - Desenvolvimento e teste rigoroso do script [`scripts/install-to-partition.sh`](../scripts/install-to-partition.sh).
  - Criação segura das partições dentro do espaço não alocado do SSD:
    - `nvme0n1p4`: `GBOSSYS` (8.0 GiB FAT32)
    - `nvme0n1p5`: `GBOS_META` (64 MiB ext4)
    - `nvme0n1p6`: `GBOS_DATA` (37.1 GiB ext4)
  - Partições originais do Zorin OS (`p1` a `p3`) permaneceram 100% intocadas (0 setores alterados).
  - Registro de entrada UEFI no firmware (`Boot0006`: `\EFI\gbos\BOOTX64.EFI`).

---

## [2026-10-29] Sessão 5 — Resolução do Incidente de Tela Preta no Host (UEFI GOP / GRUB)
- **Agente**: Flash (Gemini 3.8 Flash, High)
- **Ações**:
  - Investigado incidente após retorno do gbOS86 ao Zorin OS: o GRUB marcava `recordfail=1`, forçando modo de texto que desativava o framebuffer EFI GOP no firmware MrChromebox EDK2 UEFI.
  - Correção aplicada no host: limpeza da variável `recordfail` via `grub-editenv`, configuração de `GRUB_GFXPAYLOAD_LINUX=keep` e `GRUB_RECORDFAIL_TIMEOUT=10` em `/etc/default/grub`.
  - Elaborado ADR-0003 ([`docs/decisions/0003-uefi-gop-grub-black-screen.md`](decisions/0003-uefi-gop-grub-black-screen.md)) e guia de contingência em [`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

---

## [2026-11-03] Sessão 6 — Diagnóstico Forense da Sessão de Uso Real (Boot-3)
- **Agente**: Flash (Gemini 3.8 Flash, High)
- **Ações**:
  - Inspeção dos logs da partição `GBOSSYS` (`/gbos/logs/boot-3/`) e dados (`GBOS_DATA`).
  - Descobertas:
    1. Ventoinha a 100%: Módulos térmicos ACPI com `Exec format error` por incompatibilidade com a `struct module` do kernel, acionando modo fail-safe do EC.
    2. Dongle Gamesir Nova Lite 2.4G: Módulo `joydev.ko` com `Exec format error`.
    3. Resolução borrada: `DENSITY=180` causava escala fracionada (1.125x).
    4. Aplicativos: Clash Royale e Ibis Paint X rodavam nativos em x86_64; CapCut, Cutwire Drift e Concat travavam em timeout de compilação JIT na camada `libhoudini.so` ARM64.
    5. Carga parasita: KVM ftrace gerando 17,6 MB de log em disco, máquina virtual Debian ativa em segundo plano e prints síncronos no framebuffer.
  - Ajustado `DENSITY=160` em `gbos/gbos.cfg` na partição `GBOSSYS`.
  - Elaborado relatório [`docs/test-reports/2026-11-03-ssd-nvme-boot.md`](test-reports/2026-11-03-ssd-nvme-boot.md).

---

## [2026-11-03] Sessão 7 — Compilação do Kernel #44 na Nuvem e Otimização Absoluta
- **Agente**: Argon / Flash
- **Ações**:
  - Criação do workflow de CI cloud [`.github/workflows/build-kernel.yml`](../.github/workflows/build-kernel.yml) e script [`scripts/patch-upstream-kernel.py`](../scripts/patch-upstream-kernel.py).
  - Executada a compilação no GitHub Actions ([Run 41600493295](https://github.com/nepotira/gbos86-jinlon/actions/runs/41600493295)) em 48m23s.
  - Drivers de controle e joystick embutidos estaticamente no kernel (`=y`): `CONFIG_INPUT_JOYDEV=y`, `CONFIG_JOYSTICK_XPAD=y`, `CONFIG_INPUT_UINPUT=y`.
  - Módulos térmicos ACPI sincronizados e assinados para a build #44 (`build-id: 6c5cc6d87ca5...`).
  - Deploy no SSD interno com validação de hash SHA-256 (`96bceca9484468fead7cfb55b2571a1a18698339e455a24120c5618060ba42a9`).
  - Desativado o loop KVM ftrace em `hook.sh`.
  - Criado e implantado o serviço de desempenho de hardware [`scripts/optimize.sh`](../scripts/optimize.sh) em `GBOSSYS/gbos/optimize.sh` (Intel Speed Shift EPP `balance_performance`, RAPL 22W/35W, GPU piso 500 MHz, RAM 16 GB cache retention, NVMe `none` scheduler, DEX threading 8-way).
  - Elaborados [`docs/PERFORMANCE-TUNING.md`](PERFORMANCE-TUNING.md), ADR-0004 ([`docs/decisions/0004-hardware-optimization-and-custom-kernel.md`](decisions/0004-hardware-optimization-and-custom-kernel.md)) e [`docs/PROJECT_STATE.md`](PROJECT_STATE.md).
