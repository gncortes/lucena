---
name: patrol-e2e
description: Como escrever e rodar cenários Patrol (ponta a ponta) com keys, robôs e modo E2E. Use ao criar ou alterar testes em integration_test/.
---

# Patrol

## Estrutura
- `integration_test/robots/<tela>_robot.dart`: ações e verificações de uma tela. Cenários só usam robôs.
- `integration_test/<feature>_test.dart`: um `patrolTest` por cenário listado na tarefa.
- `integration_test/smoke_test.dart`: fumaça (tela nova em escuro, em árabe, segundo plano e volta).
- `lib/ui/core/keys/<feature>_keys.dart`, ex.: `abstract final class SettingsKeys { static const themeDark = Key('settings.theme.dark'); }`.
  Nome: `feature.elemento.qualificador`.

## Modo E2E
- Rodar com `--dart-define=E2E=true`.
- Todo cenário abre o app por `AppRobot($).open()`, que usa a composição E2E de `testing/e2e_dependencies.dart`: `Now` controlável e, conforme entrarem, adversário falso, tempos curtos e banco limpo. `lib/` não importa `testing/`; `lib/config/` só expõe `isE2E` e a composição normal.
- Cenários de persistência reiniciam o app e conferem o dado; os demais começam do zero.

## Ações nativas
- Sempre por `$.platform.mobile` (o `$.native` está obsoleto), embrulhado no `AppRobot`: segundo plano (`pressHome` + `openApp`), sem internet (`disableWifi` + `disableCellular`), tema escuro do sistema.
- Não usar `enableAirplaneMode`: ele procura o botão pelo texto e só cobre aparelhos em inglês e mais quatro idiomas.
- O Patrol não gira o aparelho: cenário de rotação só confere que o app está em retrato; vale de verdade com o aparelho já deitado (`orientation=landscape` no Test Lab).
- Tela bloqueada, diálogos e permissões do sistema: API nativa do Patrol. Confirmar a assinatura via Context7 antes de usar.

## Regras
- Sem `Future.delayed` para esperar: usar `$.pumpAndSettle()` ou as esperas do Patrol.
- Cada cenário termina verificando estado visível (texto, key, posição do tabuleiro).
- Captura de tela em falha habilitada.
