---
name: patrol-e2e
description: Como escrever e rodar cenários Patrol (ponta a ponta) com keys, robôs e modo E2E. Use ao criar ou alterar testes em integration_test/.
---

# Patrol

## Estrutura
- `integration_test/robots/<tela>_robot.dart`: ações e verificações de uma tela. Cenários só usam robôs.
- `integration_test/<feature>_test.dart`: um `patrolTest` por cenário listado na tarefa.
- `integration_test/smoke/<tela>_smoke_test.dart`: fumaça de cada tela (escuro, árabe, segundo plano e volta). Um arquivo por tela, para tarefas paralelas não disputarem o mesmo arquivo.
- `lib/ui/core/keys/<feature>_keys.dart`, ex.: `abstract final class SettingsKeys { static const themeDark = Key('settings.theme.dark'); }`.
  Nome: `feature.elemento.qualificador`.

## Modo E2E
- Rodar com `--dart-define=E2E=true`.
- Todo cenário abre o app por `AppRobot($).open()`, que usa a composição E2E de `testing/e2e_dependencies.dart`: `Now` controlável e, conforme entrarem, adversário falso, tempos curtos e banco limpo. `lib/` não importa `testing/`; `lib/config/` só expõe `isE2E` e a composição normal.
- `AppRobot.open()` apaga o que estava gravado: todo cenário começa do zero. Cenário de persistência usa `AppRobot.restart()`, que abre um app novo mantendo os dados; por isso a composição E2E grava de verdade no aparelho.
- Idioma do sistema: `AppRobot.open(systemLocale: ...)`. Sempre passar um idioma quando o cenário confere texto, porque os aparelhos do Test Lab não estão em inglês.
- Texto que não cabe: trocar para o pseudo-idioma (`AppLanguage.pseudo`, só na composição E2E) e chamar `AppRobot.expectNoClippedText()` em cada tela.

## Ações nativas
- Sempre por `$.platform.mobile` (o `$.native` está obsoleto), embrulhado no `AppRobot`: segundo plano (`pressHome` + `openApp`), sem internet (`disableWifi` + `disableCellular`), tema escuro do sistema.
- Não usar `enableAirplaneMode`: ele procura o botão pelo texto e só cobre aparelhos em inglês e mais quatro idiomas.
- O Patrol não gira o aparelho: cenário de rotação só confere que o app está em retrato; vale de verdade com o aparelho já deitado (`orientation=landscape` no Test Lab).
- Tela bloqueada, diálogos e permissões do sistema: API nativa do Patrol. Confirmar a assinatura via Context7 antes de usar.

## Regras
- Sem `Future.delayed` para esperar: usar `$.pumpAndSettle()` ou as esperas do Patrol.
- Depois de abrir uma tela, esperar com `waitUntilVisible()` antes de conferir: `expect($(key).visible, isTrue)` olha só aquele instante e falha em aparelho lento (leitura do aparelho e carga de imagem não agendam quadros, então o `pumpAndSettle` volta antes).
- Cada cenário termina verificando estado visível (texto, key, posição do tabuleiro).
- Captura de tela em falha habilitada.
