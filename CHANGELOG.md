# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Second hardware test report documenting SSD NVMe dual-boot execution and troubleshooting on HP Elite c1030 (`jinlon`) in `docs/test-reports/2026-11-03-ssd-nvme-boot.md`.
- Isolated dual-boot installation script `scripts/install-to-partition.sh` with non-destructive guards and automated EFI GOP framebuffer protection.
- Architecture Decision Records:
  - `docs/decisions/0002-isolated-install.md` (ADR-0002: Isolated NVMe SSD dual-boot).
  - `docs/decisions/0003-uefi-gop-grub-black-screen.md` (ADR-0003: UEFI GOP Framebuffer Preservation and GRUB recordfail Mitigation).
- Comprehensive troubleshooting and emergency recovery documentation in `docs/TROUBLESHOOTING.md` and `docs/INSTALL-ISOLATED.md`.

### Changed
- Updated hardware matrix in `README.md` and `README.pt-BR.md`:
  - NVMe SSD partition boot: marked as **Works**.
  - Bluetooth Gamepad (Gamesir Nova Lite): marked as **Works**.
  - Thermal / fan control: marked as **Broken** (module `Exec format error`, EC running fan at 100%).
  - USB Gamepad 2.4G wireless dongle: marked as **Broken** (`joydev.ko` module load failure).
  - 64-bit ARM apps (`arm64-v8a`): marked as **Works** (Clash Royale, Ibis Paint X).
  - 32-bit ARM apps (`armeabi-v7a`): marked as **Broken** (ABI whitelist is pure 64-bit).

### Fixed
- Hardened GRUB configuration with `GRUB_GFXPAYLOAD_LINUX=keep` to prevent host OS black screen upon reboot from gbOS86.

## [0.2.0] - 2026-10-29

### Added
- First hardware test report from live USB boot on HP Elite c1030 (`jinlon`) in `docs/test-reports/2026-10-29-live-usb-boot.md`.

### Changed
- Updated hardware compatibility tables in `README.md`, `README.pt-BR.md`, and `docs/AUDIO.md` with verified status:
  - Works: live USB boot, 3:2 display (1920x1280), touchpad, touchscreen, SOF audio (speakers, headset jack, internal DMIC), Wi-Fi (AX201), Bluetooth.
  - Partial: Touchscreen & USI stylus (touchscreen works; USI stylus not tested).
  - Broken: Accelerometer / Gyroscope auto-rotation (sensor HAL reports `Cannot detect sensors`).

### Fixed
- Recorded resolution of GitHub issue #1 (Live USB boot test) and updated issue #2 (Audio verification).


