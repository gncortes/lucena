---
name: entrega
description: Definição de pronto e fechamento de uma tarefa (commit e PR). Use ao terminar uma tarefa.
---

# Fechar a tarefa

Pronto quando, nesta ordem:
1. `dart format .` sem mudanças pendentes, `flutter analyze` limpo, `flutter test` verde.
2. Cenários Patrol da tarefa e suíte completa passando (com `--dart-define=E2E=true`).
3. Checklist de `docs/tasks/TXX.md` todo marcado.
4. Commit `TXX: <resumo>` no branch da tarefa.
5. Rodar a skill `qa-release`: ela gera a versão de QA, grava o GIF da feature no emulador e abre ou atualiza o PR com o link do app e o GIF.
6. CI do PR verde (`gh pr checks --watch`). Se falhar, corrigir no mesmo branch e rodar a `qa-release` de novo.

Nunca commitar nem dar push direto na `main`, nunca `--force`, nunca fazer merge nem criar a tag final `vX.Y.Z`:
o Gabriel faz isso depois de validar no celular (a tag final dispara a Release no CI).
