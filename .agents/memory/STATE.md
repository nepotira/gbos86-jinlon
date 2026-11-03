# Project State (STATE)

- **Etapa Atual**: ETAPA 8 (Registro de Hardware do Boot no SSD, Análise Forense e Próximos Ajustes) — Em Conclusão
- **Última Ação**:
  - Analisados os logs de boot do SSD (`boot-2` e `boot-3`), identificando causas para as 5 ocorrências relatadas pelo usuário: falha de módulos térmicos (`int340x_thermal_zone.ko`, etc. com `Exec format error`) causando ventoinha a 100%, falha de `joydev.ko` para o dongle USB (enquanto Bluetooth HID funciona), escala fracionada de `DENSITY=180` (1.125x) causando blur visual, e lista restrita de ABIs a 64-bit (`x86_64,arm64-v8a`) sem suporte a 32-bit (`ro.product.cpu.abilist32=''`).
  - Criado o relatório de teste `docs/test-reports/2026-11-03-ssd-nvme-boot.md`.
  - Atualizadas as matrizes de compatibilidade em `README.md` e `README.pt-BR.md`.
  - Atualizado `CHANGELOG.md` na seção `[Unreleased]`.
- **Bloqueios**: Nenhum.
- **Próximos Passos**: Enviar commits para `feat/isolated-install`, fazer merge do PR #6 na `main`, rodar `/release` para publicar `v0.3.0` e, opcionalmente, testar ajustes em `gbos.cfg` (como `DENSITY=160` para eliminar o blur).
