# Hardware Profile — HP Elite c1030 Chromebook (`jinlon`)

> **Status**: `not tested` — Baseline hardware specification for `jinlon`.

## Specifications

- **Board / Family**: `jinlon` (`hatch` reference board)
- **Processor**: Intel Core i3/i5/i7 10th Gen (Comet Lake-U)
- **Graphics**: Intel UHD Graphics (Comet Lake GT2)
- **Display**: 13.5" 1920x1280 (3:2 aspect ratio) eDP panel with multi-touch and USI stylus support
- **Audio Subsystem**:
  - DSP: Intel Smart Sound Technology (SOF)
  - Headset Codec: Realtek `rt5682` (I2C)
  - Speaker Amplifiers: Maxim `max98357a` (ACPI `MX98357A`)
  - Microphone: Digital Microphone array (PCH DMIC via SOF)
- **Wireless**: Intel Wi-Fi 6 AX201 160MHz + Bluetooth 5.x
- **Storage**: NVMe PCIe SSD (`/dev/nvme0n1`, 119.2 GiB)
