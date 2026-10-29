# Installation Guide

> **Status**: `not tested` — Skeleton document. Detailed reproducible build and boot instructions will be populated as steps are verified on hardware.

## Overview

1. Prepare an external working directory outside this repository (`~/gbos-work/build` or `/mnt/gbwork`).
2. Obtain the upstream GooglebookOS (`gbos86`) build tools and the official Google recovery image for `hatch` / `jinlon`.
3. Build the target image in the external directory.
4. Write the live/installer image to a dedicated USB drive (never using Ventoy) or install into the dedicated unallocated partition on `/dev/nvme0n1` following [`docs/PARTITIONING.md`](PARTITIONING.md).
