# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository structure, MIT license, and `.gitignore` rules preventing binary/firmware and private data commits.
- Pre-commit hook and `scripts/scan-sensitive.sh` scanner for sensitive patterns, hardware identifiers, and oversized files.
- Agent rules (`.agents/rules/`) and workflows/skills (`test-report`, `release`).
- Bilingual documentation (`README.md` and `README.pt-BR.md`) and initial documentation skeletons in `docs/`.
- GitHub Issue and Pull Request templates.
