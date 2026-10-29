# gbos86-jinlon

[English](README.md)

Documentação independente, scripts e relatórios de teste de hardware para execução do **GooglebookOS (`gbos86`)** no **HP Elite c1030 Chromebook (`jinlon`)** em convivência com uma instalação Linux existente.

> [!IMPORTANT]
> **Aviso Legal**: Este é um projeto independente de documentação e automação. **Não possui qualquer vínculo** com a Google LLC, HP Inc. ou com os autores do projeto upstream GooglebookOS (`gbos86`). Este repositório **não hospeda nem distribui** imagens de recuperação, firmwares proprietários, binários de topologia (`.tplg`, `.ri`, `.bin`), bibliotecas ou quaisquer arquivos de terceiros protegidos por direitos autorais. Cada usuário deve gerar sua própria imagem localmente a partir das fontes públicas oficiais.

## Hardware Alvo

- **Dispositivo**: HP Elite c1030 Chromebook (codinome da placa: `jinlon`, família Hatch)
- **SoC / CPU**: Intel Core de 10ª Geração (Comet Lake-U)
- **Tela**: 13.5" proporção 3:2 WUXGA+ (1920x1280) eDP touchscreen com suporte a caneta USI
- **Áudio**: Intel Smart Sound Technology (SOF `sof-cml_rt1011_rt5682` / `sof-hda-dsp`) + codec de fone Realtek `rt5682` + amplificadores de alto-falante Maxim `max98357a` + matriz de microfones digitais (DMIC)
- **Conectividade Sem Fio**: Intel Wi-Fi 6 AX201 (CNVi) + Bluetooth
- **Armazenamento**: SSD NVMe (`/dev/nvme0n1`) em layout multi-partição não destrutivo

## Matriz de Status de Hardware

Todos os componentes abaixo permanecem como `not tested` até que sejam verificados no hardware real com logs sanitizados documentados em [`docs/test-reports/`](docs/test-reports/).

| Componente | Status | Notas / Evidências |
| :--- | :--- | :--- |
| Boot (USB live / instalador) | **Works** | Verificado em teste de live USB ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Boot (partição dedicada no NVMe) | `not tested` | Aguardando teste de instalação em partição |
| Tela (painel 3:2, resolução, escala) | **Works** | Verificado em 1920x1280 (`DENSITY=180`) ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Controle de brilho (tela e teclado) | `not tested` | Aguardando verificação explícita |
| Touchscreen e caneta USI | **Partial** | Touchscreen funcionando; caneta USI não testada (sem hardware) ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Touchpad e teclado | **Works** | Touchpad responsivo com suporte a gestos ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Áudio — Alto-falantes internos (`max98357a`) | **Works** | Verificado em funcionamento no live USB ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Áudio — Conector P2 3.5mm (`rt5682`) | **Works** | Verificado em funcionamento no live USB ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Áudio — Microfone interno (SOF DMIC) | **Works** | Verificado em funcionamento no live USB ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Wi-Fi (`iwlwifi` / AX201) | **Works** | Verificado em funcionamento no live USB ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Bluetooth | **Works** | Verificado em funcionamento no live USB (`8087:0026`) ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Giroscópio / Auto-rotação de tela | **Broken** | HAL de sensores falha ao detectar sensores de orientação ([relatório](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Webcam | `not tested` | Aguardando teste em hardware |
| USB-C / Thunderbolt / carregamento PD | `not tested` | Aguardando teste em hardware |
| Suspensão / Retomada (S0ix) | `not tested` | Aguardando teste em hardware |
| Container Android (ARC / Waydroid) | `not tested` | Aguardando teste em hardware |

## Como Reproduzir

1. **Projeto Upstream**: Consulte [gbos86.com](https://gbos86.com) e o repositório original do GooglebookOS para obter os scripts base de construção e pré-requisitos.
2. **Imagem Oficial da Google**: Baixe a imagem pública de recuperação do ChromeOS para `hatch` / `jinlon` diretamente dos servidores públicos da Google em uma pasta de trabalho fora deste repositório (ex.: `~/gbos-work/build`).
3. **Build Local e Particionamento**: Siga as instruções detalhadas em:
   - [`docs/INSTALL.md`](docs/INSTALL.md) — Construção local da imagem e preparação da mídia de boot.
   - [`docs/PARTITIONING.md`](docs/PARTITIONING.md) — Particionamento seguro e não destrutivo no espaço não alocado do NVMe.
   - [`docs/HARDWARE.md`](docs/HARDWARE.md) — Perfil de hardware do `jinlon`.
   - [`docs/AUDIO.md`](docs/AUDIO.md) — Arquitetura de áudio SOF + `rt5682` + `max98357a` e diagnóstico.
   - [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — Problemas conhecidos e procedimentos de recuperação.

## Contribuição

1. Crie uma branch por tarefa (`feat/*`, `fix/*`, `docs/*`, `test/*`, `chore/*`).
2. Utilize [Conventional Commits](https://www.conventionalcommits.org/) em inglês.
3. Mantenha o hook `.githooks/pre-commit` (`scripts/scan-sensitive.sh`) ativo via `git config core.hooksPath .githooks`. Nunca commite binários, firmwares ou logs sem sanitização.
4. Abra um Pull Request para a branch `main`.

## Licença

Todos os scripts e documentações autorais deste repositório são distribuídos sob a [Licença MIT](LICENSE).
