import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';
import 'home_robot.dart';

/// As aulas de finais do Viktor: a trilha, a aula, a lição e os exercícios.
///
/// Os lances vêm das próprias aulas (`assets/lessons/endgames/`): o robô
/// joga o lance ensinado de cada vez, que é o primeiro dos aceitos.
class EndgamesRobot {
  const EndgamesRobot(this.$);

  final PatrolIntegrationTester $;

  static final _lessons = AssetEndgameLessonRepository(
    const AssetService(),
    school: AssetLessonRepository(const AssetService()),
  );

  /// A aula [id] como o app a lê.
  Future<EndgameLesson> lesson(String id) async {
    final trail = await $.tester.runAsync(_lessons.trail);
    return trail!.lesson(id)!;
  }

  /// Da tela inicial, pelo cartão das aulas de finais.
  Future<void> openFromHome() async {
    await tapHomePath($, HomePath.endgames);
    await $(EndgamesKeys.screen).waitUntilVisible();
  }

  Future<void> openLesson(String id) async {
    // A trilha passou de 30 aulas: rolar mais antes de desistir.
    await $(EndgamesKeys.lesson(id)).scrollTo(maxScrolls: 80).tap();
    await expectLessonScreen();
  }

  Future<void> expectLessonScreen() async {
    await $(EndgameLessonKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// Rola a tela do capítulo até [key] (T82: lista curta, sem fala nem
  /// teste recolhido).
  Future<PatrolFinder> _show(Key key) => $(key).scrollTo();

  // Os exercícios.

  /// Começa (ou continua) os exercícios pela linha "N exercícios práticos"
  /// do capítulo: passa pela introdução e abre o próximo por resolver.
  Future<void> startExercises(String lessonId, String exerciseId) async {
    await _show(EndgameLessonKeys.exercises).tap();
    await $(ExercisesIntroKeys.screen).waitUntilVisible();
    await $(ExercisesIntroKeys.start).tap();
    await expectExercise(lessonId, exerciseId);
  }

  Future<void> expectExercise(String lessonId, String exerciseId) async {
    await $(ExerciseKeys.open(lessonId, exerciseId)).waitUntilExists();
    await $(ExerciseKeys.board).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// Um lance no tabuleiro do exercício (`e2e4`), esperando a resposta.
  Future<void> exerciseMove(String uci) async {
    await _move(ExerciseKeys.board, uci);
    await _waitReply();
  }

  /// Os lances ensinados do exercício, do ponto em que ele está ([from]).
  Future<void> solveExercise(Exercise exercise, {int from = 0}) async {
    for (final turn in exercise.line.skip(from)) {
      await exerciseMove(turn.accept.first);
    }
    await $(ExerciseKeys.solved).waitUntilVisible();
  }

  Future<void> hint() async {
    await $(ExerciseKeys.hintButton).tap();
    await $.pumpAndSettle();
  }

  /// O que o Viktor está dizendo no exercício.
  String? get exerciseSpeech => $.tester
      .widget<SpeechBalloon>(find.byKey(LessonScriptKeys.speech).last)
      .speech
      ?.toString();

  /// O tabuleiro do exercício depois do primeiro lance ensinado e da resposta
  /// (só as peças): calculado da própria aula, que muda com as revisões.
  String boardAfterFirstTurn(Exercise exercise) {
    var position = GameRules.fromFen(exercise.fen)!;
    final turn = exercise.line.first;
    for (final uci in [turn.accept.first, ?turn.reply]) {
      position = GameRules.play(position, Move.parse(uci)!)!.position;
    }
    return position.fen;
  }

  /// Um lance legal que o primeiro passo do exercício não aceita: calculado da
  /// própria aula, que muda com as revisões.
  String wrongFirstMove(Exercise exercise) {
    final position = GameRules.fromFen(exercise.fen)!;
    final accepted = exercise.line.first.accept;
    for (final MapEntry(key: from, value: targets) in GameRules.legalMoves(
      position,
    ).entries) {
      for (final to in targets) {
        final uci = '${from.name}${to.name}';
        if (!accepted.contains(uci)) return uci;
      }
    }
    throw StateError('Sem lance errado em ${exercise.id}');
  }

  /// Os pontos ganhos no exercício resolvido ("1 of 2 points").
  /// Lido da estrela da barra de cima: com a explicação do Viktor na tela,
  /// a estrela grande some (T60).
  String? get earned =>
      $.tester.getSemantics(find.byKey(ExerciseKeys.stars)).label;

  /// A dica do exercício (T65, b2d0607b): o Viktor dá a pista em texto, sem a
  /// seta do lance no tabuleiro.
  void expectHintWithoutArrow() {
    final board = _board(ExerciseKeys.board);
    expect(board.shapes.whereType<Arrow>(), isEmpty);
    expect(exerciseSpeech, isNotEmpty);
  }

  /// A posição no tabuleiro do exercício (só as peças, sem a vez).
  void expectExerciseBoard(String fen) {
    expect(
      _board(ExerciseKeys.board).controller.fen.split(' ').first,
      fen.split(' ').first,
    );
  }

  /// "Próximo exercício" ou, no último, "ver resultado".
  Future<void> nextExercise() async {
    await $(ExerciseKeys.nextButton).tap();
    await $(ExerciseKeys.board).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> backFromExercise() async {
    // O último exercício leva ao resultado, que volta à aula.
    await $(ExerciseKeys.resultButton).tap();
    await $(ExercisesDoneKeys.screen).waitUntilVisible();
    // Abaixo do mínimo, o botão de baixo é "rever a lição": volta pelo X.
    if ($(ExercisesDoneKeys.back).exists) {
      await $(ExercisesDoneKeys.back).tap();
    } else {
      await $(ExercisesDoneKeys.close).tap();
    }
    await expectLessonScreen();
  }

  /// Resolve todos os exercícios da aula pelo botão de começar, pedindo
  /// antes [hints] dicas em cada um (cada dica custa uma estrela).
  Future<void> solveAll(EndgameLesson lesson, {int hints = 0}) async {
    final exercises = lesson.exercises;
    await startExercises(lesson.id, exercises.first.id);
    for (final (index, exercise) in exercises.indexed) {
      await expectExercise(lesson.id, exercise.id);
      if (hints > 0) await hint();
      await solveExercise(exercise);
      if (index < exercises.length - 1) {
        await nextExercise();
      } else {
        await backFromExercise();
      }
    }
  }

  /// O voltar da barra: de volta à aula (pelo widget, não pela dica
  /// "Back", que muda com o idioma).
  Future<void> back() async {
    await $(BackButton).tap();
    await expectLessonScreen();
  }

  Future<void> openInfo() async {
    await $(EndgameLessonKeys.infoButton).tap();
    await $(EndgameInfoKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// A resposta do outro lado vem depois de uma pausa curta.
  Future<void> _waitReply() async {
    await $.pump(const Duration(seconds: 1));
    await $.pumpAndSettle();
  }

  /// Toca na casa de origem e depois na de destino.
  Future<void> _move(Key boardKey, String uci) async {
    await $.tester.tapAt(_square(boardKey, uci.substring(0, 2)));
    await $.pump();
    await $.tester.tapAt(_square(boardKey, uci.substring(2, 4)));
    await $.pumpAndSettle();
  }

  Chessboard _board(Key key) => $.tester.widget<Chessboard>(find.byKey(key));

  Offset _square(Key boardKey, String square) => squareCenter(
    $.tester.getRect(find.byKey(boardKey)),
    square,
    orientation: _board(boardKey).orientation,
  );
}
