---
name: entrega
description: Definição de pronto e fechamento de uma tarefa (commit e PR). Use ao terminar uma tarefa.
---

# Fechar a tarefa

Pronto quando, nesta ordem:
1. `dart format .` sem mudanças pendentes, `flutter analyze` limpo, `flutter test` verde.
2. Cenários Patrol da tarefa e suíte completa passando (com `--dart-define=E2E=true`).
3. Checklist de `docs/tasks/TXX.md` todo marcado.
4. Commit `TXX: <resumo>` e PR para `main` com: o que mudou (até 5 linhas), cenários Patrol cobertos, pendências.

Não criar tag nem release: o usuário faz isso depois de validar o APK no celular
(`git tag vX.Y.Z && git push --tags` dispara o build da Release no CI).
