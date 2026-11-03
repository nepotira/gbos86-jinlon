#!/usr/bin/env bash
# scripts/install-to-partition.sh
# Non-destructive isolated installation script for gbOS86 on HP Elite c1030 (jinlon).
# Operates in DRY-RUN mode by default. Requires --apply and interactive user confirmation.
#
# Safety invariants enforced:
# - Never touches, resizes, moves, or formats existing partitions (p1, p2, p3).
# - Never calls wipefs or sgdisk --zap-all / -Z.
# - Verifies p3 ends exactly at 75852 MiB (sector 155344895) before any write.
# - Creates p4 (GBOSSYS), p5 (GBOS_META), and p6 (GBOS_DATA) strictly inside 75852 MiB..122103 MiB.
# - Formats only newly created partitions p4, p5, and p6.
# - Writes to ESP (/boot/efi) strictly inside /boot/efi/EFI/gbos/BOOTX64.EFI.

set -euo pipefail

TARGET_DISK="/dev/nvme0n1"
EXPECTED_P3_END_SECTOR=155344895
EXPECTED_UNALLOCATED_START_MIB=75852
EXPECTED_UNALLOCATED_END_MIB=122104
SYS_SIZE_MIB=8192
META_SIZE_MIB=64

APPLY=0
YES_CONFIRMED=0
BOOT_METHOD="A"
USB_SOURCE="/media/nepo/GBOS"
USB_EFI_DEV="/dev/sda1"
ESP_MOUNT="/boot/efi"

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --dry-run              Simulate the entire procedure without modifying any disk (default).
  --apply                Execute partition creation, formatting, and file copies.
  --yes                  Skip interactive prompt when called after explicit user confirmation.
  --source <path>        Path to mounted live USB GBOS partition (default: $USB_SOURCE).
  --usb-efi <dev>        USB EFI partition device holding BOOTX64.EFI (default: $USB_EFI_DEV).
  --boot-option <A|B>    Boot method: A = Independent UEFI entry (default); B = GRUB 40_custom.
  -h, --help             Show this help message.
EOF
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) APPLY=1; shift ;;
        --dry-run) APPLY=0; shift ;;
        --yes) YES_CONFIRMED=1; shift ;;
        --source) USB_SOURCE="$2"; shift 2 ;;
        --usb-efi) USB_EFI_DEV="$2"; shift 2 ;;
        --boot-option) BOOT_METHOD="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

echo "=========================================================="
echo "   gbOS86 Isolated Partition Installer (Jinlon Safety)    "
echo "=========================================================="
echo "Target Disk:       $TARGET_DISK"
echo "Mode:              $([ "$APPLY" -eq 1 ] && echo "APPLY (LIVE WRITES)" || echo "DRY-RUN (SIMULATION ONLY)")"
echo "Live USB Source:   $USB_SOURCE"
echo "USB EFI Device:    $USB_EFI_DEV"
echo "ESP Mount:         $ESP_MOUNT (writes only to $ESP_MOUNT/EFI/gbos/)"
echo "Boot Method:       Option $BOOT_METHOD"
echo "=========================================================="

# 1. Sanity Checks
if [ ! -b "$TARGET_DISK" ]; then
    echo "ERROR: Target disk $TARGET_DISK not found." >&2
    exit 1
fi

if [ ! -d "$USB_SOURCE/gbos" ]; then
    echo "ERROR: Live USB source not found at $USB_SOURCE/gbos. Please mount the GBOS USB partition." >&2
    exit 1
fi

if [ ! -b "$USB_EFI_DEV" ]; then
    echo "ERROR: USB EFI partition $USB_EFI_DEV not found." >&2
    exit 1
fi

# 2. Verify Baseline Invariants (Partitions 1, 2, and 3 must exist and match baseline sectors)
for p in 1 2 3; do
    if [ ! -b "${TARGET_DISK}p${p}" ]; then
        echo "ERROR: Baseline partition ${TARGET_DISK}p${p} is missing!" >&2
        exit 1
    fi
done

P3_START_S=$(cat /sys/block/nvme0n1/nvme0n1p3/start)
P3_SIZE_S=$(cat /sys/block/nvme0n1/nvme0n1p3/size)
P3_END_S=$((P3_START_S + P3_SIZE_S - 1))

if [ "$P3_END_S" -ne "$EXPECTED_P3_END_SECTOR" ]; then
    echo "ERROR: nvme0n1p3 end sector ($P3_END_S) does not match baseline ($EXPECTED_P3_END_SECTOR). Aborting!" >&2
    exit 1
fi

# Calculate exact partition offsets in MiB (aligned to 1 MiB inside unallocated space)
P4_START=$EXPECTED_UNALLOCATED_START_MIB
P4_END=$((P4_START + SYS_SIZE_MIB))
P5_START=$P4_END
P5_END=$((P5_START + META_SIZE_MIB))
P6_START=$P5_END
P6_END=$((EXPECTED_UNALLOCATED_END_MIB - 1)) # Leave 1 MiB slack before secondary GPT header

if [ "$P4_START" -lt "$EXPECTED_UNALLOCATED_START_MIB" ] || [ "$P6_END" -ge "$EXPECTED_UNALLOCATED_END_MIB" ]; then
    echo "ERROR: Calculated bounds (${P4_START}..${P6_END} MiB) fall outside unallocated region!" >&2
    exit 1
fi

echo "Calculated Non-Destructive Layout (strictly inside ${EXPECTED_UNALLOCATED_START_MIB}..${EXPECTED_UNALLOCATED_END_MIB} MiB):"
echo "  Partition 4 (GBOSSYS):   ${P4_START}MiB to ${P4_END}MiB (Size: $((P4_END - P4_START))MiB, FAT32)"
echo "  Partition 5 (GBOS_META): ${P5_START}MiB to ${P5_END}MiB (Size: $((P5_END - P5_START))MiB, ext4)"
echo "  Partition 6 (GBOS_DATA): ${P6_START}MiB to ${P6_END}MiB (Size: $((P6_END - P6_START))MiB, ext4 + verity)"

REQUIRED_FILES=(
    "super.img"
    "super.layout"
    "hook.sh"
    "aidiag.sh"
    "early_patch.sh"
    "hwdetect.sh"
    "install.sh"
    "apex_patch.sh"
    "gbos.cfg"
    "crossystem"
    "bootdisk.img"
    "libkm_compat.so"
    "system_ext_manifest.xml"
    "soft_gk"
)

REQUIRED_DIRS=(
    "firmware"
    "patched"
    "audio"
    "installer"
    "kmod"
    "modules"
    "surface"
    "ksu"
)

for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$USB_SOURCE/gbos/$f" ]; then
        echo "ERROR: Missing required file $USB_SOURCE/gbos/$f" >&2
        exit 1
    fi
done

for d in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$USB_SOURCE/gbos/$d" ]; then
        echo "ERROR: Missing required directory $USB_SOURCE/gbos/$d" >&2
        exit 1
    fi
done

if [ "$APPLY" -eq 0 ]; then
    echo
    echo "[DRY-RUN] Safety and baseline checks passed."
    echo "[DRY-RUN] Exact commands that will be executed under --apply:"
    echo "  1. sudo parted -s $TARGET_DISK unit MiB mkpart GBOSSYS fat32 ${P4_START} ${P4_END}"
    echo "  2. sudo parted -s $TARGET_DISK unit MiB mkpart GBOS_META ext4 ${P5_START} ${P5_END}"
    echo "  3. sudo parted -s $TARGET_DISK unit MiB mkpart GBOS_DATA ext4 ${P6_START} ${P6_END}"
    echo "  4. sudo partprobe $TARGET_DISK && sudo udevadm settle"
    echo "  5. sudo mkfs.vfat -F 32 -n GBOSSYS ${TARGET_DISK}p4"
    echo "  6. sudo mkfs.ext4 -F -q -L GBOS_META ${TARGET_DISK}p5"
    echo "  7. sudo mkfs.ext4 -F -q -m 0 -O verity -L GBOS_DATA ${TARGET_DISK}p6"
    echo "  8. sudo fsck.vfat -n ${TARGET_DISK}p4 && sudo e2fsck -fn ${TARGET_DISK}p5 && sudo e2fsck -fn ${TARGET_DISK}p6"
    echo "  9. Mount ${TARGET_DISK}p4 (GBOSSYS), copy busybox and gbos/* from $USB_SOURCE, set MODE=boot and DENSITY=180 in gbos.cfg"
    echo " 10. Mount $USB_EFI_DEV (ro), copy EFI/BOOT/BOOTX64.EFI to $ESP_MOUNT/EFI/gbos/BOOTX64.EFI and GBOSSYS/EFI/BOOT/BOOTX64.EFI"
    echo " 11. Verify SHA-256 checksums of copied files and BOOTX64.EFI against USB source"
    if [ "$BOOT_METHOD" = "A" ]; then
        echo " 12. Register UEFI boot entry via: sudo efibootmgr -c -d $TARGET_DISK -p 1 -L \"Googlebook OS\" -l '\\EFI\\gbos\\BOOTX64.EFI'"
    else
        echo " 12. Add menuentry to /etc/grub.d/40_custom and run sudo update-grub"
    fi
    echo " 13. Verify and harden host /etc/default/grub with GRUB_GFXPAYLOAD_LINUX=keep (ADR-0003)"
    echo "[DRY-RUN] No changes were written to any disk."
    exit 0
fi

# Apply Mode Guards
for p in 4 5 6; do
    if [ -b "${TARGET_DISK}p${p}" ]; then
        echo "ERROR: Partition ${TARGET_DISK}p${p} already exists on $TARGET_DISK. Refusing to overwrite!" >&2
        exit 1
    fi
done

if [ "$BOOT_METHOD" != "A" ] && [ "$BOOT_METHOD" != "B" ]; then
    echo "ERROR: --boot-option must be A or B." >&2
    exit 1
fi

if [ "$YES_CONFIRMED" -eq 0 ]; then
    read -r -p "Confirm execution of live partitioning and installation on $TARGET_DISK? (yes/no): " CONFIRM_EXEC
    if [ "$CONFIRM_EXEC" != "yes" ]; then
        echo "Cancelled by user."
        exit 1
    fi
fi

echo "==> [1/6] Creating partitions p4 (GBOSSYS), p5 (GBOS_META), p6 (GBOS_DATA) in unallocated space..."
sudo parted -s "$TARGET_DISK" unit MiB mkpart GBOSSYS fat32 "$P4_START" "$P4_END"
sudo parted -s "$TARGET_DISK" unit MiB mkpart GBOS_META ext4 "$P5_START" "$P5_END"
sudo parted -s "$TARGET_DISK" unit MiB mkpart GBOS_DATA ext4 "$P6_START" "$P6_END"
sudo partprobe "$TARGET_DISK"
sudo udevadm settle
sleep 2

for p in 4 5 6; do
    if [ ! -b "${TARGET_DISK}p${p}" ]; then
        echo "ERROR: Newly created partition ${TARGET_DISK}p${p} did not appear!" >&2
        exit 1
    fi
done

echo "==> [2/6] Formatting new partitions p4, p5, p6..."
sudo mkfs.vfat -F 32 -n GBOSSYS "${TARGET_DISK}p4"
sudo mkfs.ext4 -F -q -L GBOS_META "${TARGET_DISK}p5"
sudo mkfs.ext4 -F -q -m 0 -O verity -L GBOS_DATA "${TARGET_DISK}p6"

echo "==> [3/6] Running filesystem integrity checks (fsck) on p4, p5, p6..."
sudo fsck.vfat -n "${TARGET_DISK}p4"
sudo e2fsck -fn "${TARGET_DISK}p5"
sudo e2fsck -fn "${TARGET_DISK}p6"

echo "==> [4/6] Copying payload from $USB_SOURCE to ${TARGET_DISK}p4 (GBOSSYS) and $ESP_MOUNT/EFI/gbos/..."
MNT_SYS=$(mktemp -d)
MNT_USBEFI=$(mktemp -d)
cleanup() {
    sudo umount "$MNT_SYS" 2>/dev/null || true
    sudo umount "$MNT_USBEFI" 2>/dev/null || true
    rmdir "$MNT_SYS" "$MNT_USBEFI" 2>/dev/null || true
}
trap cleanup EXIT

sudo mount -t vfat -o noatime "${TARGET_DISK}p4" "$MNT_SYS"
sudo mount -t vfat -o ro "$USB_EFI_DEV" "$MNT_USBEFI"

if [ ! -f "$MNT_USBEFI/EFI/BOOT/BOOTX64.EFI" ]; then
    echo "ERROR: $MNT_USBEFI/EFI/BOOT/BOOTX64.EFI not found!" >&2
    exit 1
fi

sudo mkdir -p "$MNT_SYS/EFI/BOOT" "$MNT_SYS/gbos/logs" "$ESP_MOUNT/EFI/gbos"
sudo cp "$MNT_USBEFI/EFI/BOOT/BOOTX64.EFI" "$MNT_SYS/EFI/BOOT/BOOTX64.EFI"
sudo cp "$MNT_USBEFI/EFI/BOOT/BOOTX64.EFI" "$ESP_MOUNT/EFI/gbos/BOOTX64.EFI"

if [ -f "$USB_SOURCE/busybox" ]; then
    sudo cp "$USB_SOURCE/busybox" "$MNT_SYS/busybox"
fi

for f in "${REQUIRED_FILES[@]}"; do
    echo "  Copying $f ..."
    sudo cp "$USB_SOURCE/gbos/$f" "$MNT_SYS/gbos/$f"
done

for d in "${REQUIRED_DIRS[@]}"; do
    echo "  Copying directory $d/ ..."
    sudo mkdir -p "$MNT_SYS/gbos/$d"
    sudo cp -R "$USB_SOURCE/gbos/$d/." "$MNT_SYS/gbos/$d/"
done

# Configure gbos.cfg on GBOSSYS for installed boot (MODE=boot, DENSITY=180)
sudo sed -i 's/^MODE=.*/MODE=boot/' "$MNT_SYS/gbos/gbos.cfg"
sudo sed -i 's/^DENSITY=.*/DENSITY=180/' "$MNT_SYS/gbos/gbos.cfg"

sync

echo "==> [5/6] Verifying SHA-256 hashes of copied files..."
SRC_EFI_SHA=$(sha256sum "$MNT_USBEFI/EFI/BOOT/BOOTX64.EFI" | awk '{print $1}')
ESP_EFI_SHA=$(sudo sha256sum "$ESP_MOUNT/EFI/gbos/BOOTX64.EFI" | awk '{print $1}')
SYS_EFI_SHA=$(sudo sha256sum "$MNT_SYS/EFI/BOOT/BOOTX64.EFI" | awk '{print $1}')

if [ "$SRC_EFI_SHA" != "$ESP_EFI_SHA" ] || [ "$SRC_EFI_SHA" != "$SYS_EFI_SHA" ]; then
    echo "ERROR: BOOTX64.EFI SHA-256 mismatch!" >&2
    exit 1
fi
echo "  BOOTX64.EFI SHA-256 verified: $ESP_EFI_SHA"

for f in "${REQUIRED_FILES[@]}"; do
    if [ "$f" = "gbos.cfg" ]; then
        continue # gbos.cfg has MODE=boot updated intentionally
    fi
    S_SHA=$(sha256sum "$USB_SOURCE/gbos/$f" | awk '{print $1}')
    D_SHA=$(sudo sha256sum "$MNT_SYS/gbos/$f" | awk '{print $1}')
    if [ "$S_SHA" != "$D_SHA" ]; then
        echo "ERROR: SHA-256 mismatch for $f ($S_SHA != $D_SHA)!" >&2
        exit 1
    fi
    echo "  Verified $f: $D_SHA"
done

for d in "${REQUIRED_DIRS[@]}"; do
    S_CNT=$(find "$USB_SOURCE/gbos/$d" -type f | wc -l)
    D_CNT=$(sudo find "$MNT_SYS/gbos/$d" -type f | wc -l)
    if [ "$S_CNT" -ne "$D_CNT" ]; then
        echo "ERROR: File count mismatch in $d ($S_CNT != $D_CNT)!" >&2
        exit 1
    fi
    echo "  Verified directory $d/ ($D_CNT files)"
done

sudo umount "$MNT_SYS"
sudo umount "$MNT_USBEFI"
trap - EXIT
rmdir "$MNT_SYS" "$MNT_USBEFI"

echo "==> [6/6] Configuring Boot Method ($BOOT_METHOD)..."
if [ "$BOOT_METHOD" = "A" ]; then
    # Add UEFI entry without changing default BootOrder so Zorin OS remains first
    CURRENT_ORDER=$(sudo efibootmgr | awk -F': ' '/^BootOrder:/ {print $2}')
    if ! sudo efibootmgr | grep -q "Googlebook OS"; then
        sudo efibootmgr -c -d "$TARGET_DISK" -p 1 -L "Googlebook OS" -l '\EFI\gbos\BOOTX64.EFI'
        if [ -n "$CURRENT_ORDER" ]; then
            NEW_BOOT_NUM=$(sudo efibootmgr | awk '/Googlebook OS/ {gsub(/\*/,"",$1); sub(/^Boot/,"",$1); print $1; exit}')
            if [ -n "$NEW_BOOT_NUM" ]; then
                sudo efibootmgr -o "${CURRENT_ORDER},${NEW_BOOT_NUM}"
            fi
        fi
    fi
    sudo efibootmgr -v
elif [ "$BOOT_METHOD" = "B" ]; then
    SYS_UUID=$(sudo blkid -s UUID -o value "${TARGET_DISK}p4")
    if ! grep -q "Googlebook OS (gbOS86 persistent)" /etc/grub.d/40_custom 2>/dev/null; then
        cat <<GRUB_EOF | sudo tee -a /etc/grub.d/40_custom >/dev/null

menuentry "Googlebook OS (gbOS86 persistent)" --class android --class gnu-linux --class os {
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root $SYS_UUID
    chainloader /EFI/BOOT/BOOTX64.EFI
}
GRUB_EOF
        sudo update-grub
    fi
fi

# Harden host GRUB configuration against UEFI GOP black screen (ADR-0003)
if [ -f "/etc/default/grub" ]; then
    echo "==> Hardening host GRUB configuration against UEFI GOP black screen (ADR-0003)..."
    GRUB_MODIFIED=0
    if ! grep -q "^GRUB_GFXPAYLOAD_LINUX=" /etc/default/grub; then
        echo "  Adding GRUB_GFXPAYLOAD_LINUX=keep to /etc/default/grub..."
        echo "GRUB_GFXPAYLOAD_LINUX=keep" | sudo tee -a /etc/default/grub >/dev/null
        GRUB_MODIFIED=1
    fi
    if ! grep -q "^GRUB_RECORDFAIL_TIMEOUT=" /etc/default/grub; then
        echo "  Adding GRUB_RECORDFAIL_TIMEOUT=10 to /etc/default/grub..."
        echo "GRUB_RECORDFAIL_TIMEOUT=10" | sudo tee -a /etc/default/grub >/dev/null
        GRUB_MODIFIED=1
    fi
    if ! grep -q "^GRUB_GFXMODE=" /etc/default/grub; then
        echo "  Adding GRUB_GFXMODE=1920x1280,auto to /etc/default/grub..."
        echo "GRUB_GFXMODE=1920x1280,auto" | sudo tee -a /etc/default/grub >/dev/null
        GRUB_MODIFIED=1
    fi
    if [ "$GRUB_MODIFIED" -eq 1 ] && command -v update-grub >/dev/null 2>&1; then
        echo "  Regenerating GRUB configuration..."
        sudo update-grub
    fi
fi

sync
echo "=========================================================="
echo "   Isolated installation completed and verified!          "
echo "=========================================================="
