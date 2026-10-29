# Safe Partitioning Guide (`/dev/nvme0n1`)

> **Status**: `not tested` — Partition creation has not been executed yet.

## Safety Invariants

1. **Never modify existing partitions**:
   - `nvme0n1p1` (4.0 GiB, EFI System Partition `/boot/efi`) — **DO NOT TOUCH**
   - `nvme0n1p2` (16 MiB, reserved) — **DO NOT TOUCH**
   - `nvme0n1p3` (70.1 GiB, `ext4`, Zorin OS root `/`) — **DO NOT TOUCH**
2. **Never modify host bootloaders**: Do not alter `/boot/efi`, GRUB configuration, `efibootmgr` entries, or host `initramfs`.
3. **Mandatory backups before partitioning**:
   - Export partition table text dump via `sfdisk -d /dev/nvme0n1`
   - Export binary GPT backup via `sgdisk --backup=... /dev/nvme0n1`
4. **Allowed operation**: Creating a single new partition strictly within the ~45.17 GiB unallocated space after `nvme0n1p3` (starting at or after sector `155344896`), only after explicit user confirmation of the exact command.
