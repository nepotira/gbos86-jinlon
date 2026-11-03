# ADR-0002: Isolated Dual-Boot Installation on Internal NVMe

- **Date**: 2026-10-29
- **Status**: Proposed

## Context
The user verified a fully functional live USB boot of GooglebookOS (`gbOS86`) on the HP Elite c1030 Chromebook (`jinlon`). The internal NVMe SSD (`/dev/nvme0n1`, 119.2 GiB) hosts Zorin OS (`nvme0n1p3`, 70.1 GiB), an EFI System Partition (`nvme0n1p1`, 4.0 GiB), a Microsoft reserved partition (`nvme0n1p2`, 16 MiB), and approximately 45.17 GiB (`46252 MiB`) of contiguous unallocated free space between sector 155,344,896 (`75852 MiB`) and 250,069,679 (`122104 MiB`).

The goal is to install gbOS86 permanently onto the internal SSD without touching, modifying, resizing, or endangering the existing Zorin OS installation or its files on the ESP.

## Upstream Installer Analysis
1. **Official Clean Install (`usb/install.sh`)**:
   - Intended to wipe the entire drive (`wipefs`, `sgdisk -Z`).
   - Requires manually typing the disk hardware identifier.
   - Partitions created: `p1 EFI` (FAT32), `p2 GBOSSYS` (8 GiB FAT32), `p3 GBOS_META` (64 MiB ext4), `p4 GBOS_DATA` (ext4).
2. **Official Dual-Boot Mode (`tools/install_dualboot.sh`)**:
   - Designed for unallocated free space.
   - Partitions created:
     - `GBOSSYS` (8–10 GiB, FAT32): holds kernel, `super.img`, hooks, modules, firmware, and `gbos.cfg`.
     - `GBOS_META` (64 MiB, ext4): Android `/metadata`.
     - `GBOS_DATA` (remaining space, ext4 with `verity` option): persistent Android `/data`.
   - Boot entry: copies kernel to existing ESP under `EFI/gbos86/BOOTX64.EFI`, registers UEFI entry via `efibootmgr`, and appends menu entry to `/etc/grub.d/40_custom`.
3. **Stage0 Boot Discovery Mechanism (`usb/stage0_init.sh`)**:
   - Searches block devices using `findfs LABEL=GBOS` (USB stick) or `findfs LABEL=GBOSSYS` (internal install).
   - If `GBOSSYS` is found, sets `FROM=nvme`.
   - Locates `DATA=$(findfs LABEL=GBOS_DATA)` and `META=$(findfs LABEL=GBOS_META)`. If physical `GBOS_META` is missing, looks for `metadata.img` loopback file inside `GBOSSYS`.
   - Mounts `super.img` via loop devices + `dm-linear`, runs `gbos/hook.sh`, mounts `/data` and `/metadata`, and invokes `switch_root /new /system/bin/init selinux_setup`.

## Community Patches and Safety Invariants
- Upstream scripts often use generic auto-numbering (`0:0:+8G`) or search for `/dev/sdX` patterns. On NVMe (`/dev/nvme0n1`), partition naming uses the `p` prefix (`nvme0n1p4`).
- Dedicated non-destructive installation must strictly:
  1. Forbid any calls to `wipefs`, `sgdisk -Z`, or `dd` on whole disks.
  2. Restrict partition creation strictly between start sector `155344896` (`75852 MiB`) and `250069679` (`122104 MiB`).
  3. Format only newly created partitions (e.g., `nvme0n1p4`, `nvme0n1p5`, `nvme0n1p6`).
  4. Write only into `/EFI/gbos/` on the existing ESP (`/dev/nvme0n1p1`), without altering existing directories (`BOOT`, `ubuntu`, `fedora`, `Microsoft`, `OC`).

## Boot Strategy Options
- **Option A (Independent UEFI Boot Entry)**:
  - Add EFI binary to `/boot/efi/EFI/gbos/BOOTX64.EFI`.
  - Register a dedicated NVRAM boot option via `efibootmgr` (e.g. `Googlebook OS`).
  - Does not touch `/etc/grub.d/` or host GRUB.
- **Option B (GRUB 40_custom Chainloader)**:
  - Add a custom menuentry in `/etc/grub.d/40_custom` targeting the `GBOSSYS` filesystem UUID.
  - Updates `/boot/grub/grub.cfg` via `update-grub`.

## Decision
Develop a standalone, non-destructive installer script (`scripts/install-to-partition.sh`) that operates in dry-run mode by default, enforces sector boundary checks against baseline partition tables, and presents clear rollback mechanisms.
