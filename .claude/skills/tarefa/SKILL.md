---
name: tarefa
description: Executa uma tarefa do plano (T00–T19). Use quando o usuário pedir "/tarefa TXX" ou mandar trabalhar numa tarefa específica.
---

# Executar uma tarefa

1. Leia `docs/tasks/$ARGUMENTS.md` (ex.: `docs/tasks/T05.md`). Não leia o plano inteiro.
2. Crie a branch `tarefa/TXX-nome-curto`.
3. Para cada item do checklist:
   - escreva primeiro o teste unitário ou de BLoC (skill `arquitetura`);
   - implemente o mínimo para passar.
4. Escreva os cenários Patrol listados na tarefa (skill `patrol-e2e`).
5. Rode, nesta ordem: `flutter analyze`, `flutter test`, Patrol da tarefa, suíte Patrol completa.
6. Marque os itens concluídos no arquivo da tarefa.
7. Siga a skill `entrega`.

Se algo da tarefa for ambíguo ou estourar o escopo, pare e relate em vez de improvisar.
