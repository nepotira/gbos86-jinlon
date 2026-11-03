# Project State (PROJECT_STATE) — gbOS86 on HP Elite c1030 (`jinlon`)

> **Última Atualização**: 2026-11-03  
> **Branch Ativa**: `feat/isolated-install`  
> **Pull Request Aberto**: [#6 (Isolated dual-boot partition installer and hardware optimizations)](https://github.com/nepotira/gbos86-jinlon/pull/6)  
> **Versão SemVer**: `0.2.0` (Trabalho atual acumulado em `[Unreleased]` rumo à `v0.3.0`)

---

## 1. Visão Geral do Projeto

Port e otimização do **GooglebookOS (`gbOS86`)** — ambiente Android 17 Desktop GSI — para o Chromebook corporativo **HP Elite c1030 (`jinlon`)**, equipado com processador Intel Core i7-10610U (Comet Lake-U), 16 GB de RAM LPDDR4x, tela 3:2 de 1920x1280 sensível ao toque, firmware UEFI MrChromebox e dual-boot isolado e não destrutivo com o sistema operacional anfitrião (Zorin OS 17.3).

---

## 2. Estado Atual das Etapas

| Etapa | Descrição | Status | Evidência / Documento |
| :--- | :--- | :--- | :--- |
| **ETAPA 0** | Fundação do repositório, regras, git hooks e baseline | **Concluído** | Tag `v0.1.0`, commits `29b8802` e `c981f11` |
| **ETAPA 1** | Reconhecimento de hardware, diagnóstico e build de imagem padrão | **Concluído** | Imagem `gbOS86-20261029.img`, SHA256 verificado |
| **ETAPA 2** | Gravação e verificação byte a byte no pendrive USB | **Concluído** | `cmp` com exit code 0 |
| **ETAPA 3** | Teste de inicialização pelo Live USB e validação de áudio SOF | **Concluído** | [`docs/test-reports/2026-10-29-live-usb-boot.md`](test-reports/2026-10-29-live-usb-boot.md), Release `v0.2.0` |
| **ETAPA 4** | Planejamento da instalação em partição isolada no SSD NVMe | **Concluído** | [`docs/decisions/0002-isolated-install.md`](decisions/0002-isolated-install.md) (ADR-0002) |
| **ETAPA 5** | Desenvolvimento do script de particionamento e instalação | **Concluído** | [`scripts/install-to-partition.sh`](../scripts/install-to-partition.sh) |
| **ETAPA 6** | Execução da instalação no SSD (`nvme0n1p4`, `p5`, `p6`) | **Concluído** | `GBOSSYS` (8 GiB FAT32), `GBOS_META` (64 MiB), `GBOS_DATA` (37.1 GiB ext4) |
| **ETAPA 7** | Configuração do bootloader UEFI e registro no firmware | **Concluído** | Entrada UEFI `Boot0006` (`\EFI\gbos\BOOTX64.EFI`) |
| **ETAPA 7B**| Resolução de incidente de tela preta no host (UEFI GOP / GRUB) | **Concluído** | [`docs/decisions/0003-uefi-gop-grub-black-screen.md`](decisions/0003-uefi-gop-grub-black-screen.md) (ADR-0003) |
| **ETAPA 8** | Investigação forense do primeiro boot no SSD e relatório | **Concluído** | [`docs/test-reports/2026-11-03-ssd-nvme-boot.md`](test-reports/2026-11-03-ssd-nvme-boot.md) |
| **ETAPA 8.1**| Ajuste de resolução/densidade para 1:1 nativo | **Concluído** | `DENSITY=160` em `gbos/gbos.cfg` na partição `GBOSSYS` |
| **ETAPA 8.2**| Compilação do kernel customizado #44 no GitHub Actions | **Concluído** | [Run 41600493295](https://github.com/nepotira/gbos86-jinlon/actions/runs/41600493295) (SHA256: `96bceca948446...`), drivers `xpad`/`joydev` built-in, módulos térmicos ACPI sincronizados |
| **ETAPA 8.3**| Arquitetura e implantação do serviço de desempenho absoluto | **Concluído** | [`docs/PERFORMANCE-TUNING.md`](PERFORMANCE-TUNING.md), [`docs/decisions/0004-hardware-optimization-and-custom-kernel.md`](decisions/0004-hardware-optimization-and-custom-kernel.md), [`scripts/optimize.sh`](../scripts/optimize.sh) implantado em `GBOSSYS` |

---

## 3. Matriz de Compatibilidade de Hardware Atual

| Componente / Recurso | Status | Observações / Evidência |
| :--- | :--- | :--- |
| **Boot Live USB** | **Funciona** | Validado em `docs/test-reports/2026-10-29-live-usb-boot.md` |
| **Boot SSD NVMe Dual-Boot** | **Funciona** | Validado em `docs/test-reports/2026-11-03-ssd-nvme-boot.md` |
| **Display 3:2 (1920x1280)** | **Funciona** | Aceleração Vulkan Graphite; `DENSITY=160` para nitidez inteira |
| **Touchpad & Touchscreen** | **Funciona** | Reconhecido nativamente via driver i2c-hid |
| **Áudio Integrado SOF** | **Funciona** | Alto-falantes estéreo e fone de ouvido validados |
| **Microfone Digital (DMIC)**| **Funciona** | PCH DMIC via Intel SOF |
| **Wi-Fi 6 (Intel AX201)** | **Funciona** | `iwlwifi` carrega firmware e conecta a redes 2.4/5 GHz |
| **Bluetooth (Intel AX201)**| **Funciona** | Emparelhamento com periféricos ativo |
| **Controle Bluetooth (Gamesir Nova Lite)** | **Funciona** | Funcional via stack userspace `uhid` |
| **Controle USB Dongle 2.4G (Gamesir)** | **Corrigido (Build #44)** | `CONFIG_JOYSTICK_XPAD=y` e `joydev=y` embutidos no kernel |
| **Controle Térmico / Ventoinha EC** | **Corrigido (Build #44)** | Módulos térmicos ACPI sincronizados com a struct da build #44 |
| **Apps ARM64 (Houdini)** | **Otimizado (Build #44)** | CPU HWP/EPP `balance_performance`, RAPL 22W/35W e eliminação de ftrace |
| **Giroscópio / Acelerômetro** | **Quebrado** | Requer `CONFIG_IIO_CROS_EC_SENSORS` para rotação de tela |
| **Apps 32-bit (`armeabi-v7a`)** | **Incompatível** | Whitelist do Android GSI é estritamente 64 bits |

---

## 4. Próximas Ações Imediatas

1. **Teste Prático do Usuário**: Reiniciar o computador e selecionar **Googlebook OS** para validação em hardware real:
   - Resfriamento e desativação do modo 100% da ventoinha.
   - Funcionamento do receptor USB 2.4G do Gamesir Nova Lite.
   - Nitidez do display com `DENSITY=160`.
   - Inicialização e fluidez dos aplicativos ARM64 (CapCut, Cutwire, Concat).
2. **Merge do PR #6 e Publicação da Release `v0.3.0`**: Após o relato do usuário, consolidar os commits no ramo `main`, gerar as notas de versão do `CHANGELOG.md` e criar a tag `v0.3.0`.
