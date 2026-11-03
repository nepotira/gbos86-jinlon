# Hardware Test Report: Internal NVMe SSD Dual-Boot on HP Elite c1030 (Jinlon)

- **Date**: 2026-11-03
- **Hardware**: HP Elite c1030 Chromebook (`jinlon`, rev5, Intel Core i7-10610U, Comet Lake)
- **BIOS / Firmware**: MrChromebox-2603.2 (EDK2 UEFI)
- **Target Storage**: NVMe SSD (`/dev/nvme0n1p4` `GBOSSYS`, `nvme0n1p5` `GBOS_META`, `nvme0n1p6` `GBOS_DATA`)
- **Image**: `gbOS86-20261029.img` installed via `scripts/install-to-partition.sh`
- **Upstream Version**: `linuxkid473/gbos-x86` (kernel `6.18.21-gbos-whl` #42)

## Component Test Matrix

| Component | Status | Notes / Evidence |
| :--- | :--- | :--- |
| Boot (NVMe dedicated partitions) | **Works** | Boot succeeded into desktop environment from SSD (`boot-2` and `boot-3` recorded). |
| Display & Graphics Acceleration | **Works** | Hardware accelerated via Intel UHD Graphics (CML GT2) through Skia Graphite Vulkan pipeline at native 1920x1280. |
| UI Rendering & DPI Scaling | **Partial** | Functional, but non-integer scaling from `DENSITY=180` (1.125x) induces fractional scaling blurriness. Recommending clean 160 or integer-aligned density. |
| Fan Control & Thermals | **Broken** | Fan runs at ~100% full speed. ACPI/DPTF thermal modules failed to load (`Exec format error`), causing ChromeOS EC to trigger emergency fail-safe fan cooling. |
| Gamepad (Bluetooth) | **Works** | Gamesir Nova Lite connects and functions via Bluetooth userspace HID (`uhid`). |
| Gamepad (2.4G USB Wireless Dongle) | **Broken** | Wireless USB dongle (vendor `3537`, product `1040` / vendor `3151`, product `3020`) recognized, but `joydev.ko` module failed to load (`Exec format error`). |
| 64-bit ARM Applications (`arm64-v8a`) | **Works** | Clash Royale and Ibis Paint X operate normally through native bridge. |
| 32-bit ARM Applications (`armeabi-v7a`) | **Broken** | System ABI whitelist strictly enforces `x86_64,arm64-v8a` (`ro.product.cpu.abilist32` is empty). 32-bit ARM apps crash or fail to open. |
| Heavy Multimedia Video Editors (CapCut) | **Broken** | Native hardware video encoding/decoding hooks and NDK translation dependencies cause ANR (Application Not Responding) stalls. |
| Linux Terminal Virtualization (`crosvm`) | **Works** | Debian environment starts via `com.android.virtualization.terminal` (`crosvm_debian`), though with high CPU consumption. |

## Detailed Technical Analysis

### 1. Fan Noise & Thermal Governor Failure
In `kmsg.log`, core thermal management kernel modules failed to insmod:
```text
module int340x_thermal_zone: .gnu.linkonce.this_module section size must match the kernel's built struct module size at run time
ueventd: Failed to insmod '/vendor/lib/modules/int340x_thermal_zone.ko': Exec format error
ueventd: Failed to insmod '/vendor/lib/modules/acpi_thermal_rel.ko': Exec format error
ueventd: Failed to insmod '/vendor/lib/modules/processor_thermal_mbox.ko': Exec format error
ueventd: Failed to insmod '/vendor/lib/modules/x86_pkg_temp_thermal.ko': Exec format error
```
Because the OS kernel does not register active ACPI DPTF trip points, the Chromebook Embedded Controller (EC) runs the cooling fan at maximum speed to prevent thermal runaway.

### 2. USB Gamepad Dongle Failure vs Bluetooth Success
When connecting the Gamesir Nova Lite 2.4GHz USB receiver:
```text
usb 1-3: New USB device found, idVendor=3537, idProduct=1040
Product: XBOX 360 For Windows
input: Generic X-Box pad as ...
ueventd: Loading module /vendor/lib/modules/joydev.ko with args ''
module joydev: .gnu.linkonce.this_module section size must match the kernel's built struct module size at run time
ueventd: Failed to insmod '/vendor/lib/modules/joydev.ko' with args '': Exec format error
```
The kernel module `joydev.ko` suffers from the same `struct module` size mismatch as the thermal drivers. Conversely, Bluetooth connection bypasses the kernel module entirely using the userspace Android Bluetooth HID stack.

### 3. Display Density and Rendering
SurfaceFlinger operates with hardware acceleration:
```text
------------RE Vulkan (Graphite)----------
Vulkan device initialized: 1
Name: Intel(R) UHD Graphics (CML GT2)
DisplayViewport: logical width=1920, logical height=1280, densityDpi=180
```
However, setting `DENSITY=180` forces a scale factor of `180 / 160 = 1.125`. Android UI assets and text glyphs rendered at fractional 1.125x magnification exhibit visual blurriness.

### 4. Application Architecture and ABI Compatibility
System properties confirmed:
```text
ro.product.cpu.abilist: x86_64,arm64-v8a
ro.product.cpu.abilist32: <empty>
ro.product.cpu.abilist64: x86_64,arm64-v8a
```
There is zero 32-bit ARM support. Only pure 64-bit APKs run. Furthermore, video editing software relying on camera HAL and proprietary MediaCodec extensions experiences unhandled translation stalls.
