import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:chessground/chessground.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/voice_robot.dart';

const _english = Locale('en', 'US');
const _lesson = 'pawns.distantOpposition';

// Mate em um: Dh8#.
const _mateInOne = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';

/// T65 F4 (contrato `T65-contrato-licoes-fluxo.md`): o selo do fim de
/// partida, a barra contínua e o capítulo concluído, a demonstração sem voz,
/// o modo variante e a apresentação B. Voz do Viktor desligada (padrão do
/// E2E) em todos.
void main() {
  patrolTest('S1: o selo de vitória entra, some sozinho em 1,6 s e não volta '
      'ao reabrir', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final board = FreeBoardRobot($);
    await board.openAt(
      _mateInOne,
      opponent: 'maia',
      level: 1000,
      user: Side.white,
      goal: 'win',
      position: 'basic.queen.0001',
    );
    // Sem esperar assentar: o selo inteiro dura 1,6 s.
    await board.move('h1', 'h8', settle: false);
    // Sob IgnorePointer: existe, mas não recebe toque.
    await $(FreeBoardKeys.endFlash).waitUntilExists();
    final shown = DateTime.now();
    expect(find.text('You won!'), findsOneWidget);
    // Some sozinho depois do pico, sem toque.
    while (find.byKey(FreeBoardKeys.endFlash).evaluate().isNotEmpty &&
        DateTime.now().difference(shown) < const Duration(seconds: 4)) {
      await $.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(FreeBoardKeys.endFlash), findsNothing);
    expect(
      DateTime.now().difference(shown),
      lessThan(const Duration(milliseconds: 2500)),
    );
    // O rodapé "Ver o resultado" continua; o tabuleiro fica limpo.
    await $(FreeBoardKeys.seeResultButton).waitUntilVisible();

    // Reabrir não toca o selo de novo.
    await app.restart();
    await $.pump(const Duration(milliseconds: 300));
    expect(find.byKey(FreeBoardKeys.endFlash), findsNothing);
  });

  patrolTest('P1 e P2: a barra contínua cresce a cada passo e some no capítulo '
      'concluído, com os dois botões iguais', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lesson);
    // A parte `distant` virou roteiro (tela própria): usa a diagonal.
    final part = lesson.lesson.parts.firstWhere((p) => p.id == 'diagonal');
    await _openPart(endgames, 'diagonal');
    await endgames.expectStep(_lesson, part.steps.first.id);

    // No pé da AppBar, a largura toda; sem contador "1/5", título no centro.
    final bar = $.tester.getRect(find.byKey(LessonKeys.progress));
    final screen = $.tester.getRect(find.byKey(LessonKeys.screen));
    expect(bar.height, 4);
    expect(bar.width, screen.width);
    expect(find.byKey(LessonKeys.place), findsNothing);
    final board = $.tester.getRect(find.byKey(LessonKeys.board));
    // 12 dp entre a barra e a área do tabuleiro, mais o gutter de 8 (topo
    // em 80 em 412×917).
    expect(board.top - bar.bottom, closeTo(20, 1));
    final first = _progress($);
    expect(first, closeTo(1 / part.steps.length, 0.001));

    // Um passo adiante: a barra anda (e o tabuleiro não se mexe).
    e2eNow.advance(const Duration(minutes: 5));
    await $.pump(const Duration(seconds: 1));
    await endgames.nextStep();
    await endgames.expectStep(_lesson, part.steps[1].id);
    await $.pumpAndSettle();
    expect(_progress($), greaterThan(first));
    expect($.tester.getRect(find.byKey(LessonKeys.board)).top, board.top);

    await endgames.completePart(lesson, part.steps.skip(1).toList());
    await $(LessonKeys.partFinished).waitUntilVisible();
    expect(find.byKey(LessonKeys.progress), findsNothing);
    final review = $.tester.getRect(find.byKey(LessonKeys.reviewPartButton));
    final next = $.tester.getRect(find.byKey(LessonKeys.nextPartButton));
    expect(review.width, closeTo(next.width, 1));
    expect(review.height, closeTo(52, 1));
    expect(next.height, closeTo(52, 1));
    expect(review.center.dy, closeTo(next.center.dy, 1));
  });

  patrolTest('D: sem voz, a demonstração anda sozinha em até 8 s com o anel; '
      'pausada, para e fica sem anel', ($) async {
    await AppRobot($).open(systemLocale: _english);
    expect(VoiceRobot($).spokenCount, 0);
    final endgames = EndgamesRobot($);
    await _openPart(endgames, 'diagonal');
    await _toDemo($, endgames, 'diagonal', 'd_diagonal');

    // Andando: o anel no ⏭ e o primeiro lance sai sozinho em até 8 s.
    expect(_cubit($).state.demoMove, 0);
    expect(find.byKey(LessonKeys.demoRing), findsOneWidget);
    // Medido no relógio do app (o injetado), que é o que a lição conta.
    final started = e2eNow();
    await _waitUntil($, () => _cubit($).state.demoMove >= 1);
    expect(
      e2eNow().difference(started),
      lessThanOrEqualTo(const Duration(milliseconds: 8500)),
    );

    // Pausada: sem anel e sem lance novo, nem depois do teto de 8 s.
    await $(LessonKeys.demoPause).tap();
    await $.pump(const Duration(milliseconds: 300));
    final paused = _cubit($).state.demoMove;
    expect(_cubit($).state.demoPlaying, isFalse);
    expect(find.byKey(LessonKeys.demoRing), findsNothing);
    for (var i = 0; i < 90; i++) {
      e2eNow.advance(const Duration(milliseconds: 100));
      await $.pump(const Duration(milliseconds: 100));
    }
    expect(_cubit($).state.demoMove, paused);

    // Retomada: anda de novo sozinha.
    await $(LessonKeys.demoPause).tap();
    await _waitUntil($, () => _cubit($).state.demoMove > paused);
  });

  patrolTest('V: tocar no 2.Ke4 da demonstração abre o modo variante nele, ⏭ '
      'anda e o X volta com a fala inteira', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    await _openPart(endgames, 'diagonal');
    await _toDemo($, endgames, 'diagonal', 'd_diagonal');

    // Pausada no 3º lance (a fala "2.Ke4. Now face to face...").
    await $(LessonKeys.demoPause).tap();
    await $.pumpAndSettle();
    while (_cubit($).state.demoMove < 3) {
      await $(LessonKeys.demoForward).tap();
      await $.pumpAndSettle();
    }
    if (_cubit($).state.demoPlaying) {
      await $(LessonKeys.demoPause).tap();
      await $.pumpAndSettle();
    }
    expect(_cubit($).state.demoMove, 3);
    final said = _speechText($);
    expect(said, contains('2.Ke4'));
    final sheet = $.tester.getRect(find.byKey(LessonKeys.viktorSheet));

    await _tapMove($, '2.Ke4');
    await $.pump(const Duration(seconds: 1));
    await $(LessonKeys.variationExit).waitUntilVisible();
    expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
    // O tabuleiro parado no lance tocado: 2.Ke4 jogado, pretas a jogar.
    expect(
      $.tester.widget<Chessboard>(find.byKey(LessonKeys.board)).controller.fen,
      startsWith('8/8/4k3/8/4K3/4P3/8/8 b'),
    );
    expect(
      _stripCurrent($),
      contains('Ke4'),
      reason: 'o lance tocado é o da vez na faixa',
    );
    // A demonstração não anda por baixo da variante.
    expect(_cubit($).state.demoMove, 3);

    // ⏭ anda pela linha (o destaque segue) até desligar no fim.
    final before = _stripCurrent($);
    expect(_forward($).onPressed, isNotNull);
    await $(LessonKeys.variationForward).tap();
    await $.pumpAndSettle();
    expect(_stripCurrent($), isNot(before));
    while (_forward($).onPressed != null) {
      await $(LessonKeys.variationForward).tap();
      await $.pumpAndSettle();
    }

    // O X: a faixa sai, a folha volta igual e a fala inteira.
    await $(LessonKeys.variationExit).tap();
    await $.pumpAndSettle();
    expect(find.byKey(LessonKeys.variationStrip), findsNothing);
    expect(find.byKey(LessonKeys.variationExit), findsNothing);
    expect($.tester.getRect(find.byKey(LessonKeys.viktorSheet)), sheet);
    expect(_speechText($), said);
    expect(_cubit($).state.demoMove, 3);
  });

  patrolTest('B em 360×640: a Oposição lateral abre como modal com o X e, sem '
      'voz, fecha sozinha; o relógio começa em 0:00', ($) async {
    final view = $.tester.view;
    view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360 * 3, 640 * 3);
    addTearDown(view.reset);
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    // Direto pela rota: a lista das partes não rola bem na tela encolhida.
    GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
        .push(Routes.endgameLessonSteps(_lesson, part: 'lateral'));
    await $(LessonKeys.screen).waitUntilVisible();
    await endgames.expectStep(_lesson, 't_euwe');

    // Caso B: a folha cobre o tabuleiro, com o X, sem rodapé nem relógio.
    await $(LessonKeys.presentationClose).waitUntilVisible();
    final opened = DateTime.now();
    expect(_cubit($).state.presenting, isTrue);
    expect(find.byTooltip('Close and see the board'), findsOneWidget);
    expect(find.byKey(LessonKeys.nextButton).hitTestable(), findsNothing);
    final cover = $.tester.getRect(find.byKey(LessonKeys.presentation));
    final board = $.tester.getRect(find.byKey(LessonKeys.board));
    expect(cover.top, lessThan(board.bottom));

    // Sem voz: fecha sozinha no tempo de leitura (teto de 8 s).
    await _waitUntil(
      $,
      () => !_cubit($).state.presenting,
      timeout: const Duration(seconds: 12),
    );
    expect(
      DateTime.now().difference(opened),
      lessThanOrEqualTo(const Duration(milliseconds: 9500)),
    );
    await $.pumpAndSettle();
    // A folha entre o tabuleiro e o rodapé; o rodapé de volta; o relógio do
    // passo começa agora.
    expect(find.byKey(LessonKeys.presentation), findsNothing);
    expect(find.byKey(LessonKeys.presentationClose), findsNothing);
    expect(find.byKey(LessonKeys.nextButton).hitTestable(), findsOneWidget);
    final sheet = $.tester.getRect(find.byKey(LessonKeys.scroll));
    expect(sheet.top, greaterThanOrEqualTo(board.bottom));
    expect(EndgamesRobot($).stepTimer, '0:00');
  });

  patrolTest('fechar à força no modo variante: reabre na explicação, sem a '
      'faixa', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    await _openPart(endgames, 'diagonal');
    await _toDemo($, endgames, 'diagonal', 'd_diagonal');
    await $(LessonKeys.demoPause).tap();
    await $.pumpAndSettle();
    while (_cubit($).state.demoMove < 3) {
      await $(LessonKeys.demoForward).tap();
      await $.pumpAndSettle();
    }
    if (_cubit($).state.demoPlaying) {
      await $(LessonKeys.demoPause).tap();
      await $.pumpAndSettle();
    }
    await _tapMove($, '2.Ke4');
    await $.pump(const Duration(seconds: 1));
    await $(LessonKeys.variationExit).waitUntilVisible();

    // A variante não persiste: o app volta ao passo, com a fala.
    await app.restart();
    await $(LessonKeys.screen).waitUntilVisible();
    await endgames.expectStep(_lesson, 'd_diagonal');
    // A folha ocupa a altura toda (o centro dela cai no tabuleiro): quem
    // aparece é a fala.
    await $(LessonKeys.speech).waitUntilVisible();
    expect(_speechText($), contains('2.Ke4'));
    expect(find.byKey(LessonKeys.variationStrip), findsNothing);
    // A posição não diz nada aqui: o 2.Ke4 tocado é o mesmo lance que a
    // demonstração já tinha jogado.
    expect(find.byKey(LessonKeys.variationExit), findsNothing);
  });

  patrolTest('fechar à força na apresentação B: reabre no estado final, com o '
      'rodapé e o relógio', ($) async {
    final view = $.tester.view;
    view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360 * 3, 640 * 3);
    addTearDown(view.reset);
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
        .push(Routes.endgameLessonSteps(_lesson, part: 'lateral'));
    await $(LessonKeys.screen).waitUntilVisible();
    await endgames.expectStep(_lesson, 't_euwe');
    await $(LessonKeys.presentationClose).waitUntilVisible();
    expect(_cubit($).state.presenting, isTrue);

    await app.restart();
    await $(LessonKeys.screen).waitUntilVisible();
    await endgames.expectStep(_lesson, 't_euwe');
    await $.pumpAndSettle();
    // Sem modal: a folha abaixo do tabuleiro, o rodapé tocável e o relógio.
    expect(_cubit($).state.presenting, isFalse);
    expect(find.byKey(LessonKeys.presentation), findsNothing);
    expect(find.byKey(LessonKeys.nextButton).hitTestable(), findsOneWidget);
    final board = $.tester.getRect(find.byKey(LessonKeys.board));
    final sheet = $.tester.getRect(find.byKey(LessonKeys.scroll));
    expect(sheet.top, greaterThanOrEqualTo(board.bottom));
    expect(find.byKey(LessonKeys.stepTimer), findsOneWidget);
  });
}

LessonCubit _cubit(PatrolIntegrationTester $) =>
    $.tester.element(find.byKey(LessonKeys.screen)).read<LessonCubit>();

double _progress(PatrolIntegrationTester $) => $.tester
    .widget<LinearProgressIndicator>(find.byKey(LessonKeys.progress))
    .value!;

IconButton _forward(PatrolIntegrationTester $) =>
    $.tester.widget<IconButton>(find.byKey(LessonKeys.variationForward));

/// O lance da vez na faixa: o único trecho com fundo.
String _stripCurrent(PatrolIntegrationTester $) {
  final line = $.tester.widget<Text>(
    find.byKey(LessonKeys.variationStripCurrent),
  );
  final spans = (line.textSpan! as TextSpan).children!.whereType<TextSpan>();
  return spans
      .firstWhere((span) => span.style?.backgroundColor != null)
      .text!
      .replaceAll(RegExp('[\u2066\u2069]'), '');
}

RenderParagraph _speechParagraph(PatrolIntegrationTester $) =>
    $.tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byKey(LessonKeys.speech),
            matching: find.byType(RichText),
          )
          .first,
    );

String _speechText(PatrolIntegrationTester $) =>
    _speechParagraph($).text.toPlainText();

/// Toca no lance [move] escrito na fala.
Future<void> _tapMove(PatrolIntegrationTester $, String move) async {
  final paragraph = _speechParagraph($);
  final index = paragraph.text.toPlainText().indexOf(move);
  expect(index, isNonNegative, reason: '$move na fala');
  final caret = paragraph.getOffsetForCaret(
    TextPosition(offset: index + move.length ~/ 2),
    Rect.zero,
  );
  await $.tester.tapAt(paragraph.localToGlobal(caret + const Offset(0, 8)));
  await $.pumpAndSettle();
}

Future<void> _waitUntil(
  PatrolIntegrationTester $,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final start = DateTime.now();
  while (!done()) {
    if (DateTime.now().difference(start) > timeout) {
      fail('não aconteceu em $timeout');
    }
    // O ritmo da lição mede o tempo pelo relógio injetado (falso no E2E):
    // ele anda junto com o real.
    e2eNow.advance(const Duration(milliseconds: 100));
    await $.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openPart(EndgamesRobot endgames, String part) async {
  await endgames.openFromHome();
  await endgames.openLesson(_lesson);
  await endgames.openPart(part);
}

/// Do passo de pensar da parte até a demonstração [demo] (pensar sem lance,
/// a fala e o "continuar").
Future<void> _toDemo(
  PatrolIntegrationTester $,
  EndgamesRobot endgames,
  String part,
  String demo,
) async {
  final lesson = await endgames.lesson(_lesson);
  final steps = lesson.lesson.parts.firstWhere((p) => p.id == part).steps;
  for (final step in steps) {
    await endgames.expectStep(_lesson, step.id);
    if (step.id == demo) break;
    if (step is ThinkStep) {
      e2eNow.advance(const Duration(minutes: 5));
      await $.pump(const Duration(seconds: 1));
    }
    await endgames.nextStep();
  }
  await $.pump(const Duration(milliseconds: 500));
}
