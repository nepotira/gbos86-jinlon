# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Hardware Optimization Service `scripts/optimize.sh` deployed to `GBOSSYS/gbos/optimize.sh`, automatically executed as root on `sys.boot_completed=1` to tune CPU Intel P-State/EPP, Intel RAPL limits (PL1 22W / PL2 35W), Intel UHD 620 GPU clock floor (500 MHz), RAM (vm.swappiness=10, vfs_cache_pressure=50), and NVMe I/O queue (`none` scheduler, 512 KB read-ahead).
- Cloud CI kernel build workflow `.github/workflows/build-kernel.yml` and patch script `scripts/patch-upstream-kernel.py` to compile custom Linux kernel `6.18.21-gbos-whl` build #44 on GitHub Actions.
- Second hardware test report documenting SSD NVMe dual-boot execution and troubleshooting on HP Elite c1030 (`jinlon`) in `docs/test-reports/2026-11-03-ssd-nvme-boot.md`.
- Isolated dual-boot installation script `scripts/install-to-partition.sh` with non-destructive guards and automated EFI GOP framebuffer protection.
- Architecture Decision Records:
  - `docs/decisions/0002-isolated-install.md` (ADR-0002: Isolated NVMe SSD dual-boot).
  - `docs/decisions/0003-uefi-gop-grub-black-screen.md` (ADR-0003: UEFI GOP Framebuffer Preservation and GRUB recordfail Mitigation).
- Comprehensive troubleshooting and emergency recovery documentation in `docs/TROUBLESHOOTING.md` and `docs/INSTALL-ISOLATED.md`.

### Changed
- Deactivated parasitic KVM exit ftrace loop in `GBOSSYS/gbos/hook.sh` (guarded with `KVM_TRACE=1`), eliminating 17.6 MB disk I/O and continuous CPU context-switch overhead during boot.
- Built-in kernel configuration:
  - Built-in gamepad support: `CONFIG_INPUT_JOYDEV=y`, `CONFIG_JOYSTICK_XPAD=y`, `CONFIG_JOYSTICK_XPAD_FF=y`, `CONFIG_JOYSTICK_XPAD_LEDS=y`, `CONFIG_INPUT_UINPUT=y` in `BOOTX64.EFI`.
  - Compiled and synchronized matching modules for ACPI thermal management (`int340x_thermal_zone`, `acpi_thermal_rel`, `processor_thermal_mbox`, `x86_pkg_temp_thermal`, `intel_rapl`) matching build ID `6c5cc6d87ca56a8f9f8824dad71209a893d64e43a565a317a99879075dc9b855`.
- Framebuffer scaling:
  - Set `DENSITY=160` (1:1 integer pixel mapping) in `gbos.cfg` on `GBOSSYS` to eliminate font blur caused by fractional 1.125x scaling (`DENSITY=180`).
- Updated hardware matrix in `README.md` and `README.pt-BR.md`:
  - NVMe SSD partition boot: marked as **Works**.
  - Bluetooth Gamepad (Gamesir Nova Lite): marked as **Works**.
  - Thermal / fan control: marked as **Fixed in build #44** (awaiting boot verification).
  - USB Gamepad 2.4G wireless dongle: marked as **Fixed in build #44** (awaiting boot verification).
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


