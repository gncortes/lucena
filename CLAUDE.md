# Lucena — treino de finais de xadrez (Flutter, AGPL-3.0)

App offline: o usuário joga finais contra o Maia-3 (níveis humanos 1000–2600) ou o Stockfish (máximo).
Plano completo: `docs/PLANO.md`. Tarefa atual: `docs/tasks/TXX.md` (use a skill `/tarefa TXX`).

## Regras fixas
- Uma entrega do plano (uma tarefa ou um lote de tarefas) por sessão. Leia só `CLAUDE.md`, o arquivo da tarefa e os arquivos que ela citar.
- Arquitetura do guia oficial do Flutter (skill `arquitetura`): `ui/<feature>/view_models` (Cubit/Bloc) e `widgets` → `data/repositories` → `data/services`; `domain/models` e `domain/use_cases` em Dart puro.
- View model nunca usa serviço direto, só repositórios e use cases. Fakes ficam em `testing/`.
- Tempo sempre via `Now` injetado. Nunca `DateTime.now()` direto.
- Nenhum texto fixo em widget: tudo em `lib/l10n/*.arb` (base `app_en.arb`). Ver skill `l10n`.
- Todo widget usado em teste tem key de `lib/ui/core/keys/*_keys.dart`. Ver skill `patrol-e2e`.
- Toda preferência/dado persiste; toda tela com estado sobrevive a segundo plano e a fechar à força.
- APIs de pacotes: consultar Context7 ou o MCP do Dart antes de supor assinaturas. Não inventar API.

## Git
- Uma branch por tarefa (`tarefa/TXX-nome-curto`), criada a partir da `develop` atualizada. Commits e push só nela; a PR vai para a `develop` (`--base develop`).
- Nunca commitar nem dar push direto na `develop` nem na `main`. As duas só recebem código por PR com CI verde; o merge é do usuário. A `main` recebe da `develop`.
- CI em `.github/workflows/`: `ci.yml` (PR para `develop` ou `main`: formatação, analyze, traduções, testes, APK), `qa.yml` (tag `vX.Y.Z-rc.N`: App Distribution, grupo de QA, sem Test Lab) e `release.yml` (tag `vX.Y.Z` na `main`: Patrol no Test Lab, Release com o APK e App Distribution, grupo `release`).
- O Patrol não roda no CI da `develop`: a suíte local em paralelo é a validação antes da PR.
- Segredos (keystore, credenciais) ficam só no GitHub. Nunca ler, criar ou imprimir segredo.

## Comandos
- Formatar: `dart format .` (já roda sozinho após editar arquivos .dart)
- Analisar: `flutter analyze`
- Testes: `flutter test`
- Gerar código: `dart run build_runner build --delete-conflicting-outputs`
- Traduções: `python3 tools/gen_pseudo_l10n.py`, `flutter gen-l10n` e `python3 tools/check_l10n.py`
- Patrol (suíte): `patrol test --dart-define=E2E=true`
- Patrol (um arquivo): `patrol test -t integration_test/<arquivo>_test.dart --dart-define=E2E=true`
- Patrol (suíte em tema escuro ou em árabe): acrescentar `--dart-define=E2E_VARIANT=dark` ou `=ar`
- Patrol: sempre com `-d <ANDROID_DEVICE do .env>` (sem `-d` ele pergunta o aparelho e trava); o CLI fica em `~/.pub-cache/bin`.

## Não ler
`build/`, `.dart_tool/`, `assets/models/`, `tools/.cache/`, `android/app/build/`, arquivos `*.g.dart` e `*.freezed.dart` (só se a tarefa pedir).

## Ao terminar a tarefa
Siga a skill `entrega` e depois `qa-release` (PR com resumo curto, GIF da feature rodando no emulador e link do app para QA).
Nunca fazer merge, push na `main` nem tag final: só o Gabriel.
