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

## Textos das aulas de finais (pedidos do Gabriel, 2026-10-09; valem para toda lição, revisão e reescrita)
- **Lance citado sempre numerado**, como nos livros: `1.Rf7!`, `1...Rh7`, `2.e4`, `Com 1.Rc4? ...`. Posição de partida real
  (com link para abrir no Lichess): o número é o do lance real da partida, tirado do PGN. Posição montada ou de estudo:
  começa em 1. Casa solta ("fecha g8") não leva número. O revisor de lições reprova lance sem número ou com número errado.
- **Captura é "capturar"**, nunca "comer" (só as piadas de comida do Gino ficam).
- **"Sobre este final"** (`history`, `key.*`): para leigo. O que é o final, por que importa, que parece simples e não é, uma
  curiosidade. Sem lance solto, sem notação, sem "tabela"/motor, sem bastidores de produção nem crédito de usuário.
- **Passo de pensar**: o app só mostra "Jogam as brancas. Pense com calma: ..."; o texto do passo abre a explicação (sem
  a pergunta). Escrever o enunciado como contexto + pergunta no fim.
- **Exercício**: o Viktor não fala enquanto o aluno joga (nem elogio, nem "não é esse"); só na dica e depois de resolver.
- Detalhes: `.claude/skills/aula-final/licao.md`, `formato.md` e `.claude/agents/revisor-licoes.md`.

## Git
- Uma branch por tarefa (`tarefa/TXX-nome-curto`), criada a partir da `develop` atualizada. Commits e push só nela; a PR vai para a `develop` (`--base develop`).
- Nunca commitar nem dar push direto na `develop` nem na `main`. As duas só recebem código por PR com CI verde; o merge é do usuário. A `main` recebe da `develop`.
- CI em `.github/workflows/`: `ci.yml` (PR para `develop` ou `main`: formatação, analyze, traduções, testes, APK), `qa.yml` (tag `vX.Y.Z-rc.N`: App Distribution, grupo de QA, sem Test Lab) e `release.yml` (tag `vX.Y.Z` na `main`: Patrol no Test Lab, Release com o APK e App Distribution, grupo `release`).
- O Patrol não roda no CI da `develop`: a suíte local em paralelo é a validação antes da PR.
- Pedido de ajuste do Gabriel = rodada de ajustes (skill `rodada-ajustes`): **cancelar na hora qualquer Patrol em andamento** e usar os emuladores para mandar o print de cada pedido (evidência) assim que ficar pronto, com agentes em paralelo. Patrol só depois do "tudo ok".
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
