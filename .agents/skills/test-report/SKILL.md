---
name: test-report
description: Record hardware test results provided by the user, sanitize logs, open/update issues, update status tables, and submit a PR. Triggered by /test-report.
---

# Hardware Test Report Workflow (`/test-report`)

1. Pergunte os resultados do teste ao usuário e NUNCA invente evidências ou resultados.
2. Crie a branch `test/AAAA-MM-DD-assunto`.
3. Crie `docs/test-reports/AAAA-MM-DD-assunto.md` contendo:
   - Hardware
   - Versão do upstream
   - Versão do repositório
   - Tabela por componente com status (`Works` / `Partial` / `Broken` / `Not tested`)
   - Logs sanitizados
   - Notas
4. Sanitize todos os logs (remova números de série, endereços MAC, UUIDs e nome de usuário).
5. Abra ou atualize uma issue por problema encontrado usando rótulos adequados (`hardware`, `audio`, `boot`, `docs`, `test-report`, `upstream`).
6. Atualize a tabela de status nos dois READMEs (`README.md` e `README.pt-BR.md`) e em `docs/AUDIO.md` (se aplicável).
7. Faça commits pequenos e atômicos em inglês (Conventional Commits) e atualize `CHANGELOG.md` na seção `[Unreleased]`.
8. Abra o PR (`gh pr create`) e realize o squash merge, apagando a branch em seguida.
9. Sugira rodar `/release`.
