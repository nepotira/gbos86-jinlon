# Audio Architecture and Status (`jinlon`)

> **Status**: `not tested` — No audio output or input has been verified under GooglebookOS on this machine yet.

## Hardware Topology

- **Platform Driver**: Sound Open Firmware (`snd-soc-sof-hda-dsp` / `sof-cml_rt1011_rt5682` or board-specific Comet Lake machine driver)
- **Headset Jack Codec**: Realtek `rt5682`
- **Speaker Amplifier**: Maxim `max98357a`
- **Internal Microphone**: SOF PCH DMIC

## Component Matrix

| Audio Path | Codec / Driver | Status | Notes |
| :--- | :--- | :--- | :--- |
| Internal Speakers | `max98357a` + SOF | **Works** | Verified working in live USB test ([report](test-reports/2026-10-29-live-usb-boot.md)) |
| 3.5mm Headset Output | `rt5682` + SOF | **Works** | Verified working in live USB test ([report](test-reports/2026-10-29-live-usb-boot.md)) |
| 3.5mm Headset Mic | `rt5682` + SOF | `not tested` | Headphone output verified; mic jack path unverified |
| Internal DMIC | SOF DMIC | **Works** | Verified working in live USB test ([report](test-reports/2026-10-29-live-usb-boot.md)) |
| HDMI / USB-C DP Audio | `snd_hda_codec_hdmi` | `not tested` | Pending hardware test |

> [!NOTE]
> Firmware `.ri` and topology `.tplg` binaries must **never** be committed to this repository. Document only file paths, SHA-256 checksums, UCM2 configuration steps, and kernel module parameters.
