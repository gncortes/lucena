import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/explanation_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';

const _english = Locale('en', 'US');
const _lesson = 'pawns.distantOpposition';

/// O passo de pensar da parte da oposição na diagonal (a primeira, `distant`,
/// virou roteiro e tem tela própria): o certo é f3f4; e3e4 é recusado.
const _think = 't_diagonal';

/// O passo de lance da mesma parte (o 6º): e3e4 aqui é o erro com a solução
/// na explicação.
const _convert = 'diagonalMove';
const _wrong = 'e3e4';
const _part = 'diagonal';

/// T65 (LICOES-V2 §3–§6, contrato `T65-contrato-licoes-painel.md`): o painel
/// da explicação depois do erro, a Solução vista e o Voltar. "Ver solução" e
/// "Tentar de novo" só existem em passo de lance (contrato, item 14).
void main() {
  patrolTest('erro no passo de lance: rodapé Voltar | Ver solução | '
      'Continuar, nessa ordem', ($) async {
    final endgames = await _wrongAnswer($);
    _expectErrorFooter($);
    expect(find.byKey(LessonKeys.retryButton), findsNothing);
    expect(find.byKey(LessonKeys.solutionFooter), findsNothing);
    await endgames.expectExplaining();
  });

  patrolTest('Ver solução: o rodapé vira Tentar de novo, e tentar de novo '
      'reabre o passo de lance', ($) async {
    final endgames = await _wrongAnswer($);
    await _seeSolution($);
    _expectSolutionFooter($);

    await $(LessonKeys.retryButton).tap();
    await $.pumpAndSettle();
    await endgames.expectStep(_lesson, _convert);
    await endgames.expectSolving();
    expect(find.byKey(LessonKeys.solutionFooter), findsNothing);
    expect(find.byKey(LessonKeys.seeSolution), findsNothing);
  });

  patrolTest('fechar à força com a Solução vista: reabre nela', ($) async {
    final app = AppRobot($);
    await _wrongAnswer($, app: app);
    await _seeSolution($);
    _expectSolutionFooter($);

    await app.restart();
    await $(LessonKeys.solutionFooter).waitUntilVisible();
    _expectSolutionFooter($);
  });

  patrolTest('erro no primeiro passo (de pensar) e Voltar: o painel mostra o '
      'objetivo, sem a solução', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    await _openFirstPart(endgames);
    await endgames.moveInLesson(_wrong);
    // O erro de pensar leva à explicação do passo seguinte: sem "Ver
    // solução" (contrato, item 14).
    await $(LessonKeys.backButton).waitUntilVisible();
    expect(find.byKey(LessonKeys.seeSolution), findsNothing);

    await $(LessonKeys.backButton).tap();
    await $.pumpAndSettle();
    await endgames.expectStep(_lesson, _think);
    // O objetivo do passo (o bloco de contexto), sem a ideia principal.
    await $(ExplanationKeys.block('context')).waitUntilExists();
    expect(find.byKey(ExplanationKeys.block('main_solution')), findsNothing);
    expect(find.byKey(LessonKeys.seeSolution), findsNothing);
    expect(find.byKey(LessonKeys.solutionFooter), findsNothing);
    // O tabuleiro volta a aceitar o lance: o certo segue a lição.
    await endgames.moveInLesson('f3f4');
    await $.pumpAndSettle();
    expect(find.byKey(LessonKeys.seeSolution), findsNothing);
  });
}

Future<void> _openFirstPart(EndgamesRobot endgames) async {
  await endgames.openFromHome();
  await endgames.openLesson(_lesson);
  await endgames.openPart(_part);
  await endgames.expectStep(_lesson, _think);
}

/// Abre a primeira parte, passa pelo pensar, pela fala e pelas três
/// demonstrações até o passo de lance e erra nele até a explicação do erro
/// (os primeiros erros só devolvem a peça com a dica).
Future<EndgamesRobot> _wrongAnswer(
  PatrolIntegrationTester $, {
  AppRobot? app,
}) async {
  await (app ?? AppRobot($)).open(systemLocale: _english);
  final endgames = EndgamesRobot($);
  await _openFirstPart(endgames);
  // Pensar sem lance: o "continuar" de baixo é o "Ver explicação".
  e2eNow.advance(const Duration(minutes: 5));
  await $.pump(const Duration(seconds: 1));
  await endgames.nextStep();
  await endgames.expectStep(_lesson, 'diagonal');
  await endgames.nextStep();
  for (final demo in ['d_diagonal', 'err_diagonalKing', 'err_diagonalCheck']) {
    await endgames.expectStep(_lesson, demo);
    await endgames.finishDemo();
    await endgames.nextStep();
  }
  await endgames.expectStep(_lesson, _convert);
  for (var i = 0; i < 4 && !$(LessonKeys.seeSolution).exists; i++) {
    await endgames.moveInLesson(_wrong);
    await $.pump(const Duration(seconds: 2));
    await $.pumpAndSettle();
  }
  await $(LessonKeys.seeSolution).waitUntilVisible();
  return endgames;
}

Future<void> _seeSolution(PatrolIntegrationTester $) async {
  await $(LessonKeys.seeSolution).tap();
  await $.pumpAndSettle();
  await $(LessonKeys.solutionFooter).waitUntilVisible();
}

/// Os três botões do erro na mesma fileira do rodapé, da esquerda para a
/// direita (LTR).
void _expectErrorFooter(PatrolIntegrationTester $) {
  Rect rect(Key key) => $.tester.getRect(
    find.descendant(
      of: find.byKey(LessonKeys.footer),
      matching: find.byKey(key),
    ),
  );
  final back = rect(LessonKeys.backButton);
  final solution = rect(LessonKeys.seeSolution);
  final next = rect(LessonKeys.nextButton);
  expect(back.right, lessThan(solution.left));
  expect(solution.right, lessThan(next.left));
  expect(back.center.dy, closeTo(next.center.dy, 1));
  expect(solution.center.dy, closeTo(next.center.dy, 1));
}

/// Solução vista: Tentar de novo em cima; embaixo, Voltar e Continuar.
void _expectSolutionFooter(PatrolIntegrationTester $) {
  expect(find.byKey(LessonKeys.seeSolution), findsNothing);
  Rect rect(Key key) => $.tester.getRect(
    find.descendant(
      of: find.byKey(LessonKeys.solutionFooter),
      matching: find.byKey(key),
    ),
  );
  final retry = rect(LessonKeys.retryButton);
  final back = rect(LessonKeys.backButton);
  final next = rect(LessonKeys.nextButton);
  expect(retry.bottom, lessThan(back.top));
  expect(back.right, lessThan(next.left));
}
