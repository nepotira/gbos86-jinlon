---
name: release
description: Create a new SemVer release by moving Unreleased changelog entries via PR, creating an annotated tag, and publishing a GitHub release. Triggered by /release.
---

# Release Workflow (`/release`)

1. Confirme que a branch `main` está limpa e atualizada.
2. Proponha o bump SemVer (`vMAJOR.MINOR.PATCH`) com base nas mudanças em `[Unreleased]` e aguarde o "OK" explícito do usuário.
3. Via branch `chore/release-vX.Y.Z` e PR, mova as entradas de `[Unreleased]` em `CHANGELOG.md` para a nova seção `[X.Y.Z] - AAAA-MM-DD` (commit `chore(release): vX.Y.Z`), faça squash merge e apague a branch.
4. Na `main` atualizada, crie a tag anotada (`git tag -a vX.Y.Z -m "Release vX.Y.Z"`) e envie (`git push origin vX.Y.Z`).
5. Publique a release no GitHub (`gh release create vX.Y.Z`) usando as notas da versão do `CHANGELOG.md`.
6. Registre a release em `.agents/memory/HANDOFF.md` e atualize `.agents/memory/STATE.md`.
