# ADR-0003: UEFI GOP Framebuffer Preservation and GRUB recordfail Mitigation

- **Date**: 2026-10-29
- **Status**: Accepted

## Context

Following the initial test boot of GooglebookOS (`gbOS86`) from the internal NVMe SSD on the HP Elite c1030 Chromebook (`jinlon`), restarting the system to boot back into the host operating system (Zorin OS 18.1) resulted in a black screen: the device powered on and status LEDs engaged, but the display remained blank and no kernel or systemd logs were written to disk.

A forensic investigation conducted via a Live recovery environment confirmed that:
1. All partition tables and filesystems (`nvme0n1p1` through `nvme0n1p6`) were 100% intact with 0 errors on filesystem integrity checks.
2. The root cause was the Debian/Ubuntu GRUB fallback mechanism triggered by `recordfail=1` in `/boot/grub/grubenv`.
3. In standard Ubuntu/Zorin GRUB templates (`/etc/grub.d/10_linux`), encountering `recordfail=1` forces `set linux_gfx_mode=text`.
4. The HP Elite c1030 runs coreboot with MrChromebox-2603.2 EDK2 UEFI firmware. Like modern UEFI implementations, it relies entirely on the **UEFI Graphics Output Protocol (GOP)** and lacks legacy 16-bit VGA BIOS emulation.
5. Invoking `gfxmode text` tears down the UEFI GOP framebuffer. When the Linux kernel launches with `quiet splash`, early graphics drivers (`simpledrm`) and the Plymouth splash daemon encounter an absent or invalid framebuffer, resulting in a hang with a dark screen before `systemd-journald` starts.
6. Additionally, gbOS86 graphics power management can place the Intel UHD controller into deep power state `DC6`, meaning an immediate reboot without a brief cold power-off can leave the eDP panel backlight timing desynchronized.

## Decision

1. **Host GRUB Hardening**:
   Ensure the following settings are present in `/etc/default/grub` on the host Linux OS:
   ```sh
   GRUB_GFXPAYLOAD_LINUX=keep
   GRUB_RECORDFAIL_TIMEOUT=10
   GRUB_GFXMODE=1920x1280,auto
   ```
   Setting `GRUB_GFXPAYLOAD_LINUX=keep` ensures that GRUB preserves the active UEFI GOP framebuffer handover to the Linux kernel unconditionally, bypassing the `linux_gfx_mode=text` fallback branch during boot.

2. **Installer Automation**:
   Update `scripts/install-to-partition.sh` so that when executed on Debian/Ubuntu/Zorin host environments, it inspects `/etc/default/grub` and ensures `GRUB_GFXPAYLOAD_LINUX=keep` is active before or during bootloader setup.

3. **Troubleshooting and Operational Runbook**:
   Document the exact chroot recovery procedure (using `grub-editenv unset recordfail`) in `docs/TROUBLESHOOTING.md`, along with the recommendation to allow a 5-second cold power-down when switching between Android and Linux environments.

## Consequences

- The host OS is shielded against unbootable black screen conditions caused by UEFI GOP framebuffer teardown.
- GRUB menu and kernel splash transitions remain smooth and native at 1920x1280 resolution.
- Dual-boot operation between gbOS86 and Linux on MrChromebox UEFI firmware is stable and predictable.
