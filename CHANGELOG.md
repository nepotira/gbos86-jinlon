# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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


