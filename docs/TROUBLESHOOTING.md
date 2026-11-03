# Troubleshooting Guide

> **Status**: Verified — Hardware-specific troubleshooting for HP Elite c1030 Chromebook (`jinlon`).

## Common Scenarios

### Boot Media Issues
- **Do not use Ventoy for raw image booting**: The standard build image must be written directly to a dedicated USB drive via `dd` after verifying the block device name and ensuring no partitions are mounted.

### Host OS Safety and Boot Order
- If boot order changes unexpectedly in UEFI/MrChromebox firmware, select the Zorin OS EFI entry directly from the firmware boot menu without modifying `/boot/efi` from untested scripts.

---

### Black Screen on Host OS Boot (GRUB / UEFI GOP)

#### Symptoms
- After running or restarting from gbOS86, booting into the host Linux OS (Zorin OS / Ubuntu / Debian) displays a completely black/dark screen.
- The machine is powered on, LEDs are illuminated, but no boot messages or Plymouth splash screens appear.
- Checking system journals after recovery shows zero log entries written during the failed boot attempt.

#### Cause
- **Firmware Architecture**: The MrChromebox coreboot/EDK2 UEFI firmware operates via **UEFI GOP (Graphics Output Protocol)** and contains no legacy 16-bit VGA BIOS emulation.
- **GRUB Recordfail Trigger**: If the host OS is rebooted before the user-space `grub-common.service` clears the boot status, GRUB leaves `recordfail=1` in `/boot/grub/grubenv`.
- **Framebuffer Teardown**: Standard Debian/Ubuntu GRUB scripts evaluate `recordfail=1` and force `set linux_gfx_mode=text`. Under UEFI GOP, requesting text mode disables the active linear EFI framebuffer. When the kernel boots with `quiet splash`, early display drivers (`simpledrm`) and Plymouth fail to bind to a valid display surface, freezing with a dark screen.
- **Display Controller Power States**: In addition, gbOS86 configures Intel UHD graphics into deep power-saving state `DC6`. Switching operating systems without a brief power pause can leave panel backlight timing uninitialized.

#### Prevention
Add the following directives to `/etc/default/grub` on the host Linux OS:
```sh
# Retain the EFI GOP framebuffer across kernel handover
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_RECORDFAIL_TIMEOUT=10
GRUB_GFXMODE=1920x1280,auto
```
Then execute:
```bash
sudo update-grub
```

#### Cold Power-Down Recommendation
When shutting down Googlebook OS to return to Linux (or vice-versa), allow a **5-second cold power pause** before pressing the power button. This ensures the eDP panel timing controller and Intel GPU power planes fully discharge from `DC6` state.

#### Emergency Recovery Procedure via Live USB
If a system encounters this black screen condition:
1. Boot any 64-bit Linux Live USB (e.g., CachyOS, Ubuntu, Fedora).
2. Open a terminal and mount the host partitions and virtual filesystems:
   ```bash
   sudo mount /dev/nvme0n1p3 /mnt
   sudo mount /dev/nvme0n1p1 /mnt/boot/efi
   for d in /dev /dev/pts /proc /sys /sys/firmware/efi/efivars; do
       sudo mount --bind "$d" "/mnt$d"
   done
   ```
3. Clear the `recordfail` flag:
   ```bash
   sudo chroot /mnt grub-editenv /boot/grub/grubenv unset recordfail
   ```
4. Verify the setting is cleared (command output should be empty):
   ```bash
   sudo chroot /mnt grub-editenv /boot/grub/grubenv list
   ```
5. Apply the prevention directives to `/mnt/etc/default/grub` if not already present, and regenerate GRUB:
   ```bash
   sudo chroot /mnt update-grub
   ```
6. Unmount all paths cleanly and reboot:
   ```bash
   sudo umount -R /mnt
   sync
   sudo reboot
   ```
