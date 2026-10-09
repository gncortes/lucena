import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
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
import 'home_robot.dart';

import '../../testing/e2e_dependencies.dart';

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
    await tapHomePath($, HomeKeys.endgamesButton);
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

  /// Rola a tela da aula até [key]. O `scrollTo` do Patrol só desce, e a
  /// lista descarta o que ficou acima: se o item não existe, volta ao topo
  /// (a fala do Viktor) antes de descer.
  Future<PatrolFinder> _show(Key key) async {
    if (!$(key).exists) {
      await $(EndgameLessonKeys.speech)
          .scrollTo(scrollDirection: AxisDirection.up);
    }
    // Os exercícios ficam no teste final, que começa recolhido (T51).
    if (!$(key).exists && !$(EndgameLessonKeys.exercises).exists) {
      await $(EndgameLessonKeys.finalTestSummary).scrollTo().tap();
      await $.pumpAndSettle();
    }
    return $(key).scrollTo();
  }

  // A lição (os passos, na tela das aulas da escola).

  Future<void> openSteps() async {
    await _show(EndgameLessonKeys.lessonButton).tap();
    await $(LessonKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await chooseThinkTime();
  }

  /// Na primeira aula com passo de pensar, a escolha do tempo vem antes:
  /// fica no recomendado (as próximas aulas não perguntam mais).
  Future<void> chooseThinkTime({int minutes = 0}) async {
    // A escolha aparece depois de a aula carregar: espera um pouco por ela.
    for (var i = 0; i < 20 && !$(LessonKeys.thinkChooser).exists; i++) {
      if ($(LessonKeys.nextButton).exists || $(LessonKeys.board).exists) break;
      await $.pump(const Duration(milliseconds: 100));
    }
    if (!$(LessonKeys.thinkChooser).exists) return;
    await $(LessonKeys.thinkChoice(minutes)).scrollTo().tap();
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
      await _stepOrChooser(LessonKeys.step(lesson.id, step.id));
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
        case ThinkStep():
          // O tempo de pensar (o das preferências, até 5 minutos) passa no
          // relógio dos cenários; se o relógio da tela não andar, "ver
          // explicação agora" encerra.
          e2eNow.advance(const Duration(minutes: 5));
          await $.pump(const Duration(seconds: 1));
          await _skipThink();
        case DemoStep():
          // Avança na mão até o fim (a demonstração também anda sozinha).
          while (!$(LessonKeys.nextButton).exists) {
            if ($(LessonKeys.demoForward).exists) {
              await $(LessonKeys.demoForward).tap();
            }
            await $.pumpAndSettle();
          }
        case TalkStep() || StarsStep() || TapStep():
          break;
      }
      await $(LessonKeys.nextButton).tap();
      await $.pumpAndSettle();
    }
    // Fim da aula: a tela de aula concluída ou a da última parte.
    for (var i = 0; i < 100; i++) {
      if ($(LessonKeys.finished).exists || $(LessonKeys.partFinished).exists) {
        return;
      }
      await $.pump(const Duration(milliseconds: 100));
    }
    await $(LessonKeys.finished).waitUntilVisible();
  }

  /// Espera o passo [step]; se antes dele aparecer a escolha do tempo de
  /// pensar (a primeira aula com passo de pensar), escolhe o recomendado.
  Future<void> _stepOrChooser(Key step) async {
    for (var i = 0; i < 100; i++) {
      if ($(step).exists) return;
      if ($(LessonKeys.thinkChooser).exists) {
        await chooseThinkTime();
        continue;
      }
      // A aula em partes (T51): no fim de cada parte, "ir para a parte
      // seguinte".
      if ($(LessonKeys.nextPartButton).exists) {
        await $(LessonKeys.nextPartButton).scrollTo().tap();
        await $.pumpAndSettle();
        continue;
      }
      await $.pump(const Duration(milliseconds: 100));
    }
    await $(step).waitUntilExists();
  }

  /// "Continuar" no passo aberto da lição.
  Future<void> nextStep() async {
    await _skipThink();
    await $(LessonKeys.nextButton).tap();
    await $.pumpAndSettle();
  }

  /// No passo de pensar (T51), "ver explicação agora" encerra o tempo e o
  /// "continuar" aparece.
  Future<void> _skipThink() async {
    if ($(LessonKeys.thinkSkip).exists) {
      await $(LessonKeys.thinkSkip).tap();
      await $.pumpAndSettle();
    }
  }

  Future<void> expectStep(String lessonId, String stepId) async {
    await $(LessonKeys.step(lessonId, stepId)).waitUntilExists();
  }

  /// No fim da lição: volta para a aula, com os exercícios.
  Future<void> backToExercises() async {
    // Na aula em partes, o fim da última parte volta à aula por "voltar à
    // aula"; na aula inteira, por "exercícios".
    if ($(LessonKeys.exercisesButton).exists) {
      await $(LessonKeys.exercisesButton).tap();
    } else {
      await $(LessonKeys.backToLessonButton).scrollTo().tap();
    }
    await expectLessonScreen();
  }

  Future<void> expectLessonDone() async {
    await _show(EndgameLessonKeys.lessonDone);
  }

  // Os exercícios.

  Future<void> openExercise(String lessonId, String exerciseId) async {
    await _show(EndgameLessonKeys.exercise(exerciseId)).tap();
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
      _plain($.tester.widget<Text>(find.byKey(ExerciseKeys.speech).last));

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

  /// O voltar da barra: de volta à aula (pelo widget, não pela dica
  /// "Back", que muda com o idioma).
  Future<void> back() async {
    await $(BackButton).tap();
    await expectLessonScreen();
  }

  // A nota e o passo final.

  Future<void> expectPassed() async {
    await _show(EndgameLessonKeys.passed);
  }

  Future<void> expectFailed() async {
    await _show(EndgameLessonKeys.failed);
  }

  /// A nota da aula ("11 of 23 stars").
  void expectScore(String text) =>
      expectTextIn(find.byKey(EndgameLessonKeys.score), text);

  /// Sem nota de reprovação (exercícios por fazer).
  void expectNotFailed() =>
      expect(find.byKey(EndgameLessonKeys.failed), findsNothing);

  Future<void> redo() async {
    await _show(EndgameLessonKeys.redoButton).tap();
    await $.pumpAndSettle();
  }

  Future<void> expectFinalStep() async {
    await _show(EndgameLessonKeys.finalStep);
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

  // A fala como texto, simples ou com as casas destacadas (texto rico).
  static String? _plain(Text text) => text.data ?? text.textSpan?.toPlainText();
}
