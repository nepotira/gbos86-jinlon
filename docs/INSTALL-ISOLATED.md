# Isolated Installation Guide for gbOS86 on HP Elite c1030 (Jinlon)

> **Status**: Draft (Stage 6) — Verification and dry-run phase. No disk write operations performed yet.

## 1. Proposed Partition Layout (Unallocated Free Space Only)

The primary NVMe disk (`/dev/nvme0n1`, 119.2 GiB) currently has 46,252 MiB (~45.17 GiB) of contiguous free space starting at `75852 MiB` up to the disk end at `122104 MiB`.

Existing partitions (100% preserved and untouched):
- `nvme0n1p1`: 4.0 GiB FAT32 (`/boot/efi`, ESP)
- `nvme0n1p2`: 16 MiB (Microsoft reserved)
- `nvme0n1p3`: 70.1 GiB ext4 (Zorin OS root `/`)

Proposed new partitions inside unallocated space:
1. **`nvme0n1p4` (`GBOSSYS`)**:
   - **Start**: `75852 MiB`
   - **End**: `84044 MiB` (Size: `8192 MiB` / 8.0 GiB)
   - **Filesystem**: FAT32 (`mkfs.vfat -F 32 -n GBOSSYS`)
   - **Content**: `gbos/` payload copied from the live USB (`super.img`, `hook.sh`, modules, firmware, `early_patch.sh`, `gbos.cfg`).
2. **`nvme0n1p5` (`GBOS_META`)**:
   - **Start**: `84044 MiB`
   - **End**: `84108 MiB` (Size: `64 MiB`)
   - **Filesystem**: ext4 (`mkfs.ext4 -L GBOS_META`)
   - **Purpose**: Dedicated Android `/metadata` partition expected by stage0.
3. **`nvme0n1p6` (`GBOS_DATA`)**:
   - **Start**: `84108 MiB`
   - **End**: `122103 MiB` (Size: `37995 MiB` / ~37.1 GiB)
   - **Filesystem**: ext4 (`mkfs.ext4 -O verity -L GBOS_DATA`)
   - **Purpose**: Persistent user data, installed applications, and settings.

---

## 2. Bootloader Configuration Options

### Option A: Independent UEFI Firmware Boot Entry (Recommended)
- **Mechanism**: Copies the kernel to `/boot/efi/EFI/gbos/BOOTX64.EFI` on the existing ESP and creates a direct UEFI boot menu entry (`Googlebook OS`) via `efibootmgr`.
- **User Experience**: Press the boot selection key (or choose in UEFI setup) to boot Googlebook OS directly. The default boot remains Zorin OS unless chosen otherwise.
- **Impact on Host**: Zero modification to Zorin OS boot files, initramfs, or `/etc/grub.d/`.

### Option B: Zorin OS GRUB Menu Entry (`/etc/grub.d/40_custom`)
- **Mechanism**: Appends a chainloader menuentry in `/etc/grub.d/40_custom` searching for the `GBOSSYS` filesystem UUID and executes `update-grub`.
- **User Experience**: Googlebook OS appears as a selection in the standard GRUB bootloader menu on every startup.
- **Impact on Host**: Edits one text file (`/etc/grub.d/40_custom`) and regenerates `/boot/grub/grub.cfg`. Reversible by deleting the entry and running `update-grub`.

### Host GRUB Safety: UEFI GOP Framebuffer Preservation (ADR-0003)
On coreboot / MrChromebox EDK2 UEFI firmware, video is provided solely via UEFI GOP (no legacy 16-bit VGA BIOS). If the host Debian/Ubuntu GRUB triggers its fallback mode (`recordfail=1`), it defaults to `linux_gfx_mode=text`, disabling the GOP framebuffer and causing a black screen on subsequent boots of the host OS.
To shield against this, `/etc/default/grub` must include:
```sh
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_RECORDFAIL_TIMEOUT=10
GRUB_GFXMODE=1920x1280,auto
```
This is automatically validated and applied by `scripts/install-to-partition.sh`.

---

## 3. Step-by-Step Procedure

1. **Backups (Mandatory)**:
   - Full partition table text dump: `sudo sfdisk -d /dev/nvme0n1 > .agents/memory/nvme0n1-gpt-backup.txt`
   - Full binary GPT backup: `sudo sgdisk --backup=.agents/memory/nvme0n1-gpt-backup.bin /dev/nvme0n1`
   - Complete backup of ESP contents: `sudo rsync -a /boot/efi/ .agents/memory/esp-backup/`
   - Record UEFI NVRAM variables: `sudo efibootmgr -v > .agents/memory/efibootmgr-v-pre.txt`
2. **Partitioning**:
   - Create `nvme0n1p4`, `nvme0n1p5`, `nvme0n1p6` strictly within `75852 MiB` to `122104 MiB`.
   - Run `partprobe /dev/nvme0n1`.
3. **Formatting**:
   - Format only partitions 4, 5, and 6. Never execute wipefs or touch partitions 1, 2, or 3.
4. **Data Sync**:
   - Mount `/dev/nvme0n1p4` and copy all payload files from the live USB `/media/nepo/GBOS/`.
   - Ensure `MODE=boot` in `gbos/gbos.cfg` on `GBOSSYS`.
   - Copy `BOOTX64.EFI` to `/boot/efi/EFI/gbos/BOOTX64.EFI`.
5. **Boot Registration**:
   - Apply Option A or Option B as explicitly instructed by the user.
6. **Host GRUB Hardening (ADR-0003)**:
   - Ensure `GRUB_GFXPAYLOAD_LINUX=keep` is set in `/etc/default/grub` to prevent UEFI GOP framebuffer teardown and black screens.

---

## 4. Rollback and Recovery Plan

To completely undo the installation at any point:
1. **Remove partitions**: Delete partitions 4, 5, and 6 with `sudo parted /dev/nvme0n1 rm 6 rm 5 rm 4` (or restore exact GPT from backup: `sudo sgdisk --load-backup=.agents/memory/nvme0n1-gpt-backup.bin /dev/nvme0n1`).
2. **Clean ESP**: Remove the added folder: `sudo rm -rf /boot/efi/EFI/gbos`.
3. **Clean UEFI Entry (if Option A used)**: `sudo efibootmgr -b <NUM> -B`.
4. **Clean GRUB Entry (if Option B used)**: Remove the block from `/etc/grub.d/40_custom` and run `sudo update-grub`.

---

## 5. Architectural Recommendation (5 Lines)
> [!TIP]
> **Recommendation: Option A (Independent UEFI Boot Entry)**
> Option A is cleaner and safer because it keeps Googlebook OS completely isolated from Zorin OS's bootloader. It creates a dedicated directory `/EFI/gbos/` without touching `/etc/grub.d/` or requiring `update-grub`. The motherboard firmware handles switching naturally, ensuring that Linux updates or kernel regenerations in Zorin OS will never interfere with gbOS86 and vice-versa.
