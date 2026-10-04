# Lucena — treino de finais de xadrez (Flutter, AGPL-3.0)

App offline: o usuário joga finais contra o Maia-3 (níveis humanos 600–2600) ou o Stockfish (máximo).
Plano completo: `docs/PLANO.md`. Tarefa atual: `docs/tasks/TXX.md` (use a skill `/tarefa TXX`).

## Regras fixas
- Uma tarefa por sessão. Leia só `CLAUDE.md`, o arquivo da tarefa e os arquivos que ela citar.
- Arquitetura do guia oficial do Flutter (skill `arquitetura`): `ui/<feature>/view_models` (Cubit/Bloc) e `widgets` → `data/repositories` → `data/services`; `domain/models` e `domain/use_cases` em Dart puro.
- View model nunca usa serviço direto, só repositórios e use cases. Fakes ficam em `testing/`.
- Tempo sempre via `Now` injetado. Nunca `DateTime.now()` direto.
- Nenhum texto fixo em widget: tudo em `lib/l10n/*.arb` (base `app_en.arb`). Ver skill `l10n`.
- Todo widget usado em teste tem key de `lib/ui/core/keys/*_keys.dart`. Ver skill `patrol-e2e`.
- Toda preferência/dado persiste; toda tela com estado sobrevive a segundo plano e a fechar à força.
- APIs de pacotes: consultar Context7 ou o MCP do Dart antes de supor assinaturas. Não inventar API.

## Comandos
- Formatar: `dart format .` (já roda sozinho após editar arquivos .dart)
- Analisar: `flutter analyze`
- Testes: `flutter test`
- Gerar código: `dart run build_runner build --delete-conflicting-outputs`
- Traduções: `flutter gen-l10n` e `python3 tools/check_l10n.py`
- Patrol (suíte): `patrol test --dart-define=E2E=true`
- Patrol (um arquivo): `patrol test -t integration_test/<arquivo>_test.dart --dart-define=E2E=true`

## Não ler
`build/`, `.dart_tool/`, `assets/models/`, `tools/.cache/`, `android/app/build/`, arquivos `*.g.dart` e `*.freezed.dart` (só se a tarefa pedir).

## Ao terminar a tarefa
Siga a skill `entrega`. Resumo final em até 5 linhas: o que mudou, testes, cenários Patrol, pendências.
