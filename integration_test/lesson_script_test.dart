import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/school_robot.dart';
import 'robots/script_lesson_robot.dart';

const _english = Locale('en', 'US');

/// Abre a aula [id] do curso, na tela roteirizada.
Future<ScriptLessonRobot> _open(PatrolIntegrationTester $, String id) async {
  await AppRobot($).open(systemLocale: _english);
  final school = SchoolRobot($);
  await school.openFromHome();
  await school.openScriptLesson(id);
  final lesson = ScriptLessonRobot($);
  await lesson.waitUntil(() => lesson.state.ready);
  return lesson;
}

void main() {
  // Escola escondida (VisibleLessons): os cenários voltam quando ela for
  // liberada (as aulas dela é que abrem a tela roteirizada por aqui).
  patrolTest('lance errado na pergunta: o Viktor aponta o erro, a peça volta '
      'sozinha e o lance certo segue a aula', ($) async {
    final lesson = await _open($, 'pieces.rook');
    await lesson.advanceToPhase(ScriptPhase.pergunta);
    final before = lesson.state.fen;

    // Fala curta (a pergunta): o toque no balão também abre a folha inteira.
    await lesson.expectSpeechSheetRoundTrip();

    await lesson.expectWrongMoveBounces(
      'd4',
      'a4',
      errorText: 'The rook stopped on another square',
    );
    expect(lesson.state.fen, before);

    // A torre vai a d8: sai da pergunta com o acerto no balão.
    await lesson.move('d4', 'd8');
    await lesson.waitUntil(() => lesson.state.phase != ScriptPhase.pergunta);
    expect(lesson.state.tone, isNot(ScriptTone.bad));
    expect(lesson.speech, contains('That'));
  }, skip: !VisibleLessons.school);

  patrolTest('ver a resposta: o botão mostra o lance e a lista de lances '
      'aparece; tocar num lance leva o tabuleiro até ele', ($) async {
    final lesson = await _open($, 'pieces.rook');
    await lesson.advanceToPhase(ScriptPhase.pergunta);
    lesson.expectMoveListHidden();

    await $(LessonScriptKeys.showAnswer).tap();
    await lesson.settle(10);
    lesson.expectMoveListShown();
    expect(lesson.speech, contains('d-file'));

    final first = lesson.state.moves.first.id;
    await $(LessonScriptKeys.move(first)).tap();
    await lesson.settle(6);
    expect(lesson.state.currentMoveId, first);
  }, skip: !VisibleLessons.school);

  patrolTest('ver a resposta pelo link dentro da fala do balão faz o mesmo '
      'que o botão', ($) async {
    final lesson = await _open($, 'pieces.rook');
    await lesson.advanceToPhase(ScriptPhase.pergunta);
    lesson.expectMoveListHidden();

    await lesson.tapInSpeech('Show answer');
    await lesson.settle(10);
    lesson.expectMoveListShown();
  }, skip: !VisibleLessons.school);

  patrolTest('coordenadas: a prática de tocar na casa pedida dá verde no '
      'certo e vermelho no errado, com pretas embaixo e sem as letras da '
      'borda', ($) async {
    final lesson = await _open($, 'notation.coordinates');
    await lesson.advanceToExample('pratica', 0, ScriptPhase.praticaVez);

    // Achar: com as letras e os números na borda.
    lesson.expectCoordinates(visible: true);
    expect(lesson.state.touching, isTrue);
    expect(lesson.speech, contains('e4'));

    // Casa errada: vermelho, e o pedido continua o mesmo.
    await lesson.tapSquare('d4');
    expect(lesson.state.touchMiss, 'd4');
    expect(lesson.state.touched, isEmpty);
    expect(lesson.speech, contains('d4'));
    expect(lesson.speech, contains('e4'));

    // Certa: verde, e vem a próxima.
    await lesson.tapSquare('e4');
    expect(lesson.state.touched, ['e4']);
    expect(lesson.state.touchMiss, isNull);
    expect(lesson.speech, contains('a1'));
    await lesson.tapSquare('a1');
    await lesson.tapSquare('h8');
    await lesson.tapSquare('d5');
    expect(lesson.state.phase, ScriptPhase.praticaFim);

    // Com as pretas: o tabuleiro vira e as letras seguem na borda.
    await lesson.advanceToExample('pratica', 1, ScriptPhase.praticaVez);
    expect(lesson.state.orientation.name, 'black');
    lesson.expectCoordinates(visible: true);
    for (final square in ['a1', 'e5', 'h3', 'c7']) {
      await lesson.tapSquare(square);
    }
    expect(lesson.state.phase, ScriptPhase.praticaFim);

    // Sem coordenadas: nenhuma letra na borda.
    await lesson.advanceToExample('pratica', 2, ScriptPhase.praticaVez);
    lesson.expectCoordinates(visible: false);
    await lesson.tapSquare('c6');
    expect(lesson.state.touched, ['c6']);
  }, skip: !VisibleLessons.school);

  patrolTest('fechar à força no meio da aula volta ao início da parte, não '
      'ao passo onde estava', ($) async {
    final app = AppRobot($);
    final lesson = await _open($, 'pieces.rook');
    // Anda por várias falas, passa a ideia e entra na etapa das
    // demonstrações.
    await lesson.advanceUntil(() => lesson.state.stageId == 'demos');
    expect(lesson.state.stageIndex, 1);

    await app.restart();
    await $(LessonScriptKeys.screen).waitUntilVisible();
    final reopened = ScriptLessonRobot($);
    await reopened.waitUntil(() => reopened.state.ready);
    expect(reopened.state.stageIndex, 0);
    expect(reopened.state.stageId, 'ideia');
    expect(reopened.state.exampleIndex, 0);
    expect(reopened.state.phase, ScriptPhase.entrada);
    expect(find.byKey(LessonScriptKeys.back), findsNothing);
    expect(find.byKey(LessonScriptKeys.moveList), findsNothing);
  }, skip: !VisibleLessons.school);

  patrolTest('segundo plano no meio da aula mantém o passo onde estava', (
    $,
  ) async {
    final app = AppRobot($);
    final lesson = await _open($, 'pieces.rook');
    await lesson.advanceToExample('ideia', 1, ScriptPhase.pergunta);
    final stage = lesson.state.stageIndex;
    final fen = lesson.state.fen;
    final speech = lesson.speech;

    await app.sendToBackgroundAndReturn();
    await lesson.settle(10);

    expect(find.byKey(LessonScriptKeys.screen), findsOneWidget);
    expect(lesson.state.stageIndex, stage);
    expect(lesson.state.exampleIndex, 1);
    expect(lesson.state.phase, ScriptPhase.pergunta);
    expect(lesson.state.fen, fen);
    expect(lesson.speech, speech);
  }, skip: !VisibleLessons.school);
}
