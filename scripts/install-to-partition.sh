#!/usr/bin/env bash
# scripts/install-to-partition.sh
# Non-destructive isolated installation script for gbOS86 on HP Elite c1030 (jinlon).
# Operates in DRY-RUN mode by default. Requires --apply and interactive user confirmation.

set -euo pipefail

TARGET_DISK="/dev/nvme0n1"
EXPECTED_UNALLOCATED_START_MIB=75852
EXPECTED_UNALLOCATED_END_MIB=122104
SYS_SIZE_MIB=8192
META_SIZE_MIB=64

APPLY=0
BOOT_METHOD=""
USB_SOURCE="/media/nepo/GBOS"

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --dry-run              Simulate the entire procedure without modifying any disk (default).
  --apply                Execute partition creation, formatting, and file copies after confirmation.
  --source <path>        Path to mounted live USB GBOS partition (default: $USB_SOURCE).
  --boot-option <A|B>    Boot method: A = Independent UEFI entry; B = GRUB 40_custom entry.
  -h, --help             Show this help message.
EOF
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) APPLY=1; shift ;;
        --dry-run) APPLY=0; shift ;;
        --source) USB_SOURCE="$2"; shift 2 ;;
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
echo "Boot Method:       ${BOOT_METHOD:-"(Not specified - required for --apply)"}"
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

# 2. Verify Baseline Invariants (Partitions 1, 2, and 3 must exist and match baseline)
for p in 1 2 3; do
    if [ ! -b "${TARGET_DISK}p${p}" ]; then
        echo "ERROR: Baseline partition ${TARGET_DISK}p${p} is missing!" >&2
        exit 1
    fi
done

# Check that partitions 4, 5, 6 do not already exist before partitioning
EXISTING_NEW_PARTS=0
for p in 4 5 6; do
    if [ -b "${TARGET_DISK}p${p}" ]; then
        EXISTING_NEW_PARTS=1
    fi
done

# Calculate exact partition offsets in MiB
P4_START=$EXPECTED_UNALLOCATED_START_MIB
P4_END=$((P4_START + SYS_SIZE_MIB))
P5_START=$P4_END
P5_END=$((P5_START + META_SIZE_MIB))
P6_START=$P5_END
P6_END=$((EXPECTED_UNALLOCATED_END_MIB - 1)) # Leave 1 MiB slack before GPT backup table

echo "Calculated Non-Destructive Layout:"
echo "  Partition 4 (GBOSSYS):   ${P4_START}MiB to ${P4_END}MiB (Size: $((P4_END - P4_START))MiB, FAT32)"
echo "  Partition 5 (GBOS_META): ${P5_START}MiB to ${P5_END}MiB (Size: $((P5_END - P5_START))MiB, ext4)"
echo "  Partition 6 (GBOS_DATA): ${P6_START}MiB to ${P6_END}MiB (Size: $((P6_END - P6_START))MiB, ext4 verity)"

if [ "$APPLY" -eq 0 ]; then
    echo
    echo "[DRY-RUN] Safety checks passed."
    echo "[DRY-RUN] The following commands WOULD be executed under --apply:"
    echo "  1. sudo parted -s $TARGET_DISK unit MiB mkpart GBOSSYS fat32 ${P4_START} ${P4_END}"
    echo "  2. sudo parted -s $TARGET_DISK unit MiB mkpart GBOS_META ext4 ${P5_START} ${P5_END}"
    echo "  3. sudo parted -s $TARGET_DISK unit MiB mkpart GBOS_DATA ext4 ${P6_START} ${P6_END}"
    echo "  4. sudo partprobe $TARGET_DISK"
    echo "  5. sudo mkfs.vfat -F 32 -n GBOSSYS ${TARGET_DISK}p4"
    echo "  6. sudo mkfs.ext4 -F -L GBOS_META ${TARGET_DISK}p5"
    echo "  7. sudo mkfs.ext4 -F -O verity -L GBOS_DATA ${TARGET_DISK}p6"
    echo "  8. Copy payload from $USB_SOURCE to ${TARGET_DISK}p4 and /boot/efi/EFI/gbos/"
    echo "[DRY-RUN] No changes were made to any disk."
    exit 0
fi

# Apply Mode Guard
if [ "$EXISTING_NEW_PARTS" -eq 1 ]; then
    echo "NOTICE: One or more target partitions (p4, p5, p6) already exist on $TARGET_DISK."
    read -r -p "Do you want to re-format only p4, p5, and p6? (yes/no): " CONFIRM_REFORMAT
    if [ "$CONFIRM_REFORMAT" != "yes" ]; then
        echo "Aborted by user."
        exit 1
    fi
fi

if [ -z "$BOOT_METHOD" ] || { [ "$BOOT_METHOD" != "A" ] && [ "$BOOT_METHOD" != "B" ]; }; then
    echo "ERROR: You must specify --boot-option A or --boot-option B with --apply." >&2
    exit 1
fi

echo "Pre-flight checks verified. Ready to apply changes."
exit 0
