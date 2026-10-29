# gbos86-jinlon

[Português do Brasil](README.pt-BR.md)

Independent documentation, scripts, and hardware test reports for running **GooglebookOS (`gbos86`)** on the **HP Elite c1030 Chromebook (`jinlon`)** alongside an existing Linux installation.

> [!IMPORTANT]
> **Disclaimer**: This is an independent community documentation and tooling project. It has **no affiliation** with Google LLC, HP Inc., or the upstream GooglebookOS (`gbos86`) authors. This repository **does not host or distribute** any recovery images, proprietary firmware, topology binaries (`.tplg`, `.ri`, `.bin`), libraries, or third-party copyrighted files. Users must build images locally from publicly available official sources.

## Target Hardware

- **Device**: HP Elite c1030 Chromebook (board codename: `jinlon`, Hatch family)
- **SoC / CPU**: 10th Gen Intel Core (Comet Lake-U)
- **Display**: 13.5" 3:2 WUXGA+ (1920x1280) eDP touchscreen with USI stylus support
- **Audio**: Intel Smart Sound Technology (SOF `sof-cml_rt1011_rt5682` / `sof-hda-dsp`) + Realtek `rt5682` headset codec + Maxim `max98357a` speaker amplifiers + digital microphone array (DMIC)
- **Wireless**: Intel Wi-Fi 6 AX201 (CNVi) + Bluetooth
- **Storage**: NVMe SSD (`/dev/nvme0n1`) in dual-boot / multi-partition layout

## Hardware Status Matrix

Every component below defaults to `not tested` until verified on real hardware with sanitized logs documented in [`docs/test-reports/`](docs/test-reports/).

| Component | Status | Notes / Evidence |
| :--- | :--- | :--- |
| Boot (USB live / installer) | **Works** | Verified in live USB test ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Boot (NVMe dedicated partition) | `not tested` | Pending partition installation test |
| Display (3:2 panel, resolution, scaling) | **Works** | Verified at 1920x1280 (`DENSITY=180`) ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Backlight control (screen & keyboard) | `not tested` | Pending explicit verification |
| Touchscreen & USI stylus | **Partial** | Touchscreen works; USI stylus not tested (no hardware) ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Touchpad & keyboard | **Works** | Touchpad responsive with gestures ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Audio — Internal speakers (`max98357a`) | **Works** | Verified working in live USB ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Audio — 3.5mm headset jack (`rt5682`) | **Works** | Verified working in live USB ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Audio — Internal microphone (SOF DMIC) | **Works** | Verified working in live USB ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Wi-Fi (`iwlwifi` / AX201) | **Works** | Verified working in live USB ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Bluetooth | **Works** | Verified working in live USB (`8087:0026`) ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Auto-Rotate / Gyroscope | **Broken** | Sensor HAL fails to detect orientation sensors ([report](docs/test-reports/2026-10-29-live-usb-boot.md)) |
| Webcam | `not tested` | Pending hardware test |
| USB-C / Thunderbolt / PD charging | `not tested` | Pending hardware test |
| Suspend / Resume (S0ix) | `not tested` | Pending hardware test |
| Android container (ARC / Waydroid) | `not tested` | Pending hardware test |

## How to Reproduce

1. **Upstream Project**: Visit [gbos86.com](https://gbos86.com) and the original upstream GooglebookOS repository for base build scripts and requirements.
2. **Official Recovery Image**: Download the official public ChromeOS recovery image for `hatch` / `jinlon` directly from Google's public recovery servers in an external build directory outside this repository (e.g., `~/gbos-work/build`).
3. **Local Build & Partitioning**: Follow the step-by-step instructions in:
   - [`docs/INSTALL.md`](docs/INSTALL.md) — Building the image locally and preparing the boot media.
   - [`docs/PARTITIONING.md`](docs/PARTITIONING.md) — Safe non-destructive partitioning in unallocated NVMe space alongside Linux.
   - [`docs/HARDWARE.md`](docs/HARDWARE.md) — Hardware profile for `jinlon`.
   - [`docs/AUDIO.md`](docs/AUDIO.md) — SOF + `rt5682` + `max98357a` audio architecture and troubleshooting.
   - [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — Known issues and recovery steps.

## Contributing

1. Create a feature, fix, documentation, or test branch (`feat/*`, `fix/*`, `docs/*`, `test/*`, `chore/*`).
2. Follow [Conventional Commits](https://www.conventionalcommits.org/) in English.
3. Ensure `.githooks/pre-commit` (`scripts/scan-sensitive.sh`) is enabled via `git config core.hooksPath .githooks`. Never commit binaries, firmware, or unsanitized logs.
4. Open a Pull Request targeting `main`.

## License

All original scripts and documentation authored in this repository are licensed under the [MIT License](LICENSE).
