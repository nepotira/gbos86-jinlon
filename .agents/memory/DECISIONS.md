# Architecture and Workflow Decisions (DECISIONS)

| Data | Decisão | Motivo |
| :--- | :--- | :--- |
| 2026-10-29 | Criar regras globais em `~/.gemini/GEMINI.md` e `~/.gemini/config/GEMINI.md` | Compatibilidade com os dois caminhos globais documentados no Antigravity (`~/.gemini/GEMINI.md` e `~/.gemini/config/`). |
| 2026-10-29 | Criar `/test-report` e `/release` tanto em `.agents/skills/<name>/SKILL.md` quanto em `.agents/workflows/<name>.md` | A documentação atual do Antigravity depreciou `.agents/workflows/*.md` em favor de `.agents/skills/<name>/SKILL.md`. Manter ambos garante funcionamento nativo dos slash commands e conformidade com a estrutura pedida. |
| 2026-10-29 | Manter a pasta de build fora do repositório (`~/gbos-work/build`) | Evitar commits acidentais de imagens, binários proprietários ou artefatos grandes. |
