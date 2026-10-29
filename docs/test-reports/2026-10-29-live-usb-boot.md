# Hardware Test Report: Live USB Boot on HP Elite c1030 (Jinlon)

- **Date**: 2026-10-29
- **Hardware**: HP Elite c1030 Chromebook (`jinlon`, rev5, Intel Core i7-10610U, Comet Lake)
- **BIOS / Firmware**: MrChromebox-2603.2
- **Image**: `gbOS86-20261029.img` (build standard, `MODE=live`, `DENSITY=180`)
- **Upstream Version**: `linuxkid473/gbos-x86` (kernel `6.18.21-gbos-whl` #42)
- **Repository Tag**: `v0.1.0`

## Component Test Matrix

| Component | Status | Notes / Evidence |
| :--- | :--- | :--- |
| Boot (Live USB) | **Works** | Clean boot into desktop without errors (`boot-1` recorded). |
| Display (3:2 panel) | **Works** | Native 1920x1280 resolution confirmed via DRM state (`crtc-pos=1920x1280`), scaling with `DENSITY=180` reported perfect. |
| Touchpad | **Works** | Responsive and fully functional with gestures. |
| Touchscreen | **Works** | Multi-touch input responsive and accurate. |
| USI Stylus | **Not tested** | Hardware not available during test. |
| Audio (Speakers) | **Works** | Maxim `max98357a` sound output confirmed functional by user. |
| Audio (Headset Jack) | **Works** | Realtek `rt5682` audio path functional. |
| Audio (Microphone) | **Works** | Digital microphone input (SOF DMIC) functional. |
| Wi-Fi | **Works** | Intel AX201 (`iwlwifi` / `iwlmvm`) connects and operates normally. |
| Bluetooth | **Works** | Intel BT (`btusb` `8087:0026`) fully functional. |
| Auto-Rotate / Gyroscope / Accelerometer | **Broken** | Auto-rotate does not respond in tablet or clamshell orientation. Android logcat reports `OrientationEventListener: Cannot detect sensors. Invalid disable`. |

## Sanitized Evidence / Logs

### Kernel and DMI (`hwdetect.txt`)
```text
== kernel
Linux (none) 6.18.21-gbos-whl #42 SMP PREEMPT Fri Oct 23 22:40:29 UTC 2026 x86_64 GNU/Linux
== cpu
model name	: Intel(R) Core(TM) i7-10610U CPU @ 1.80GHz
avx yes
avx2 yes
fma yes
bmi2 yes
== dmi
sys_vendor=Google
product_name=Jinlon
product_version=rev5
bios_version=MrChromebox-2603.2
board_name=Jinlon
```

### Audio Subsystem (`audio.txt`)
```text
==> cards <==
 0 [sofrt5682      ]: sof-rt5682 - sof-rt5682
                      HP-Jinlon-rev5

==> pcm <==
00-00: Port1 (*) :  : playback 1 : capture 1
00-01: DMIC (*) :  : capture 1
00-02: HDMI1 (*) :  : playback 1
00-03: HDMI2 (*) :  : playback 1
00-04: HDMI3 (*) :  : playback 1
00-05: Speakers (*) :  : playback 1
00-08: DMIC16kHz (*) :  : capture 1
```

### Sensor Failure Log (`logcat.txt`)
```text
W OrientationEventListener: Cannot detect sensors. Invalid disable
```
