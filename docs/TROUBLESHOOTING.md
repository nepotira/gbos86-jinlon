# Troubleshooting Guide

> **Status**: `not tested` — Skeleton troubleshooting reference.

## Common Scenarios

### Boot Media Issues
- **Do not use Ventoy**: Image must be written directly to a dedicated USB drive via `dd` after verifying the block device name and ensuring no partitions are mounted.

### Host OS Safety
- If boot order changes unexpectedly in UEFI/MrChromebox firmware, select the Zorin OS EFI entry directly from the firmware boot menu without modifying `/boot/efi` from untested scripts.
