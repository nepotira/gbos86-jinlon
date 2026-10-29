# ADR-0001: Repository Architecture and Non-Redistribution Policy

- **Date**: 2026-10-29
- **Status**: Accepted

## Context

Running GooglebookOS (`gbos86`) on the HP Elite c1030 (`jinlon`) alongside an existing Linux installation requires careful partitioning, audio firmware/topology configuration, and repeatable testing without risking the host OS or violating third-party copyrights.

## Decision

1. Keep all build artifacts, recovery images, and extracted firmware outside the Git repository (`~/gbos-work/build`).
2. Enforce a strict `pre-commit` scanner (`scripts/scan-sensitive.sh`) blocking binary extensions, oversized files (> 5 MB), credentials, MAC addresses, UUIDs, hardware identifiers, and local username paths.
3. Mark all hardware components as `not tested` until backed by concrete, sanitized logs in `docs/test-reports/`.

## Consequences

- The repository remains lightweight, MIT-licensed, and safe for public publication on GitHub.
- Reproducibility relies on documented scripts and checksums rather than redistributed binary blobs.
