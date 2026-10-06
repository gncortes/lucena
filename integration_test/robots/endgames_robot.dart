import 'package:chessground/chessground.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/endgames/widgets/stars_row.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';
import 'variant.dart';

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
    await $(HomeKeys.endgamesButton).scrollTo().tap();
    await $(EndgamesKeys.screen).waitUntilVisible();
  }

  Future<void> openLesson(String id) async {
    await $(EndgamesKeys.lesson(id)).scrollTo().tap();
    await expectLessonScreen();
  }

  Future<void> expectLessonScreen() async {
    await $(EndgameLessonKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  // A lição (os passos, na tela das aulas da escola).

  Future<void> openSteps() async {
    await $(EndgameLessonKeys.lessonButton).scrollTo().tap();
    await $(LessonKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// Faz a lição inteira: "continuar" nas falas, os lances ensinados nos
  /// passos de lance e, nos de jogar, os lances de [play] (por passo) contra
  /// a máquina dos cenários.
  Future<void> completeSteps(
    EndgameLesson lesson, {
    required Map<String, List<String>> play,
  }) async {
    for (final step in lesson.lesson.steps) {
      await $(LessonKeys.step(lesson.id, step.id)).waitUntilExists();
      switch (step) {
        case MoveStep(:final line):
          for (final turn in line) {
            await _move(LessonKeys.board, turn.accept.first);
            if (turn.reply != null) await _waitReply();
          }
        case PlayStep():
          for (final move in play[step.id]!) {
            await _move(LessonKeys.board, move);
            await _waitReply();
          }
        case TalkStep() || StarsStep():
          break;
      }
      await $(LessonKeys.nextButton).tap();
      await $.pumpAndSettle();
    }
    await $(LessonKeys.finished).waitUntilVisible();
  }

  /// "Continuar" no passo aberto da lição.
  Future<void> nextStep() async {
    await $(LessonKeys.nextButton).tap();
    await $.pumpAndSettle();
  }

  Future<void> expectStep(String lessonId, String stepId) async {
    await $(LessonKeys.step(lessonId, stepId)).waitUntilExists();
  }

  /// No fim da lição: volta para a aula, com os exercícios.
  Future<void> backToExercises() async {
    await $(LessonKeys.exercisesButton).tap();
    await expectLessonScreen();
  }

  Future<void> expectLessonDone() async {
    await $(EndgameLessonKeys.lessonDone).scrollTo();
  }

  // Os exercícios.

  Future<void> openExercise(String lessonId, String exerciseId) async {
    await $(EndgameLessonKeys.exercise(exerciseId)).scrollTo().tap();
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
  String? get exerciseSpeech =>
      $.tester.widget<Text>(find.byKey(ExerciseKeys.speech).last).data;

  /// As estrelas ganhas no exercício resolvido ("1 of 2 stars").
  String? get earned =>
      $.tester.widget<Text>(find.byKey(ExerciseKeys.earned)).data;

  /// A seta da dica no tabuleiro do exercício.
  void expectHintArrow(String uci) {
    final board = _board(ExerciseKeys.board);
    expect(
      board.shapes.whereType<Arrow>().any(
        (arrow) => '${arrow.orig.name}${arrow.dest.name}' == uci,
      ),
      isTrue,
    );
  }

  /// A posição no tabuleiro do exercício (só as peças, sem a vez).
  void expectExerciseBoard(String fen) {
    expect(
      _board(ExerciseKeys.board).controller.fen.split(' ').first,
      fen.split(' ').first,
    );
  }

  /// "Próximo exercício" ou, no último, "voltar à aula".
  Future<void> nextExercise() async {
    await $(ExerciseKeys.nextButton).tap();
    await $(ExerciseKeys.board).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> backFromExercise() async {
    await $(ExerciseKeys.backButton).tap();
    await expectLessonScreen();
  }

  /// Resolve todos os exercícios da aula a partir da lista, pedindo antes
  /// [hints] dicas em cada um (cada dica custa uma estrela).
  Future<void> solveAll(EndgameLesson lesson, {int hints = 0}) async {
    final exercises = lesson.exercises;
    await openExercise(lesson.id, exercises.first.id);
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

  /// As estrelas ganhas num exercício, na lista da aula.
  void expectExerciseStars(String exerciseId, int? earned) => expect(
    $.tester
        .widget<StarsRow>(
          find.byKey(EndgameLessonKeys.exerciseStars(exerciseId)),
        )
        .earned,
    earned,
  );

  /// O voltar da barra (ou do aparelho): de volta à aula.
  Future<void> back() async {
    await $.tester.pageBack();
    await expectLessonScreen();
  }

  // A nota e o passo final.

  Future<void> expectPassed() async {
    await $(EndgameLessonKeys.passed).scrollTo();
  }

  Future<void> expectFailed() async {
    await $(EndgameLessonKeys.failed).scrollTo();
  }

  /// A nota da aula ("11 of 23 stars").
  void expectScore(String text) =>
      expectTextIn(find.byKey(EndgameLessonKeys.score), text);

  /// Sem nota de reprovação (exercícios por fazer).
  void expectNotFailed() =>
      expect(find.byKey(EndgameLessonKeys.failed), findsNothing);

  Future<void> redo() async {
    await $(EndgameLessonKeys.redoButton).scrollTo().tap();
    await $.pumpAndSettle();
  }

  Future<void> expectFinalLocked() async {
    await $(EndgameLessonKeys.finalLocked).scrollTo();
  }

  Future<void> expectFinalStep() async {
    await $(EndgameLessonKeys.finalStep).scrollTo();
  }

  /// Desafia o speedrun do final no ritmo [pace] (`180+2`).
  Future<void> challengeSpeedrun(String pace) async {
    await $(EndgameLessonKeys.pace(pace)).scrollTo().tap();
    await $(EndgameLessonKeys.speedrunButton).scrollTo().tap();
    await $(SpeedrunKeys.screen).waitUntilVisible();
    expect(find.byKey(SpeedrunKeys.paceBadge), findsOneWidget);
  }

  Future<void> train() async {
    await $(EndgameLessonKeys.trainButton).scrollTo().tap();
    await $(GameSetupKeys.screen).waitUntilVisible();
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
