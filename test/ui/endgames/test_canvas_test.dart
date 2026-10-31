import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/test_canvas_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercises_done_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercises_intro_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../course_entry/course_states_canvas_test.dart' as capture;

// Explicit visual fixtures reproduce Canvas data. These snapshots do not
// certify exercise acceptance, an engine verdict, or operational navigation.
const _fen = '4k3/pp3ppp/2n5/8/3P4/3B4/PP3PPP/4K3 w - - 0 1';
final _lesson = EndgameLesson(
  id: 'pilares.c2',
  module: 'pilares',
  lesson: const Lesson(id: 'pilares.c2', steps: []),
  passScore: 9,
  keyPositions: const [],
  exercises: [
    for (var i = 0; i < 12; i++)
      Exercise(
        id: 'e$i',
        stars: 1,
        fen: _fen,
        goal: PositionGoal.win,
        line: const [MoveTurn(accept: {})],
      ),
  ],
);

class _SnapshotExercise extends ExerciseCubit {
  _SnapshotExercise()
    : super(
        lessons: FakeEndgameLessonRepository(),
        progress: FakeEndgameProgressRepository(
          const EndgameProgress(
            lessons: {
              'pilares.c2': EndgameLessonProgress(stars: {'e0': 1, 'e1': 1}),
            },
          ),
        ),
        characters: FakeCharacterRepository(),
        now: FakeNow(DateTime.utc(2026)),
      ) {
    emit(
      ExerciseState(
        ready: true,
        lesson: _lesson,
        exercise: _lesson.exercises[2],
        fen: _fen,
        viktor: FakeCharacterRepository.viktor,
        number: 3,
        count: 12,
      ),
    );
  }
}

void main() {
  setUpAll(Goldens.loadFonts);
  setUp(() async {
    capture.settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await capture.settings.load();
    capture.speech = SpeechCubit(
      FakeVoiceRepository(settings: const VoiceSettings(enabled: true)),
    );
    await capture.speech.load();
  });
  tearDown(() => capture.settings.close());
  tearDown(() => capture.speech.close());

  for (final size in capture.sizes) {
    for (final name in [
      'TesteIntro',
      'TesteExercicio',
      'TesteSair',
      'TesteResultado',
      'TesteNaoPassou',
    ]) {
      capture.canvasTest('$name Canvas $size (visual fixture)', (tester) async {
        setPhoneSize(tester, size);
        expect(GameRules.fromFen(_fen), isNotNull);
        final cubit = _SnapshotExercise();
        addTearDown(cubit.close);
        final correct = name == 'TesteNaoPassou' ? 7 : 10;
        final answers = [
          for (var i = 0; i < 12; i++)
            name == 'TesteNaoPassou' ? i < correct : ![2, 7].contains(i),
        ];
        final Widget page = switch (name) {
          'TesteIntro' => TestCanvasIntroPage(
            chapter: 2,
            count: 12,
            onStart: () {},
          ),
          'TesteResultado' || 'TesteNaoPassou' => TestCanvasResultPage(
            chapter: 2,
            answers: answers,
            teacher: FakeCharacterRepository.viktor,
            speech: name == 'TesteResultado'
                ? 'Dois tropeços, nos dois exercícios de garfo. A cravada você já resolve sozinho.'
                : null,
            onContinue: () {},
            onRetry: () {},
            onReview: (_) {},
          ),
          _ => BlocProvider<ExerciseCubit>.value(
            value: cubit,
            child: const ExerciseScreen(trainingTest: true),
          ),
        };
        await capture.mount(tester, page);
        if (name == 'TesteResultado' || name == 'TesteNaoPassou') {
          final target = tester.getSize(find.byKey(TestCanvasKeys.answer(0)));
          expect(target.width, greaterThanOrEqualTo(44));
          expect(target.height, greaterThanOrEqualTo(44));
        }
        if (name == 'TesteSair') {
          await tester.tap(find.byKey(TrainingKeys.testBack));
          await tester.pumpAndSettle();
          expect(
            find.text(
              'Os 2 exercícios feitos ficam salvos. Quando voltar, você continua no exercício 3.',
            ),
            findsOneWidget,
          );
        }
        if (name == 'TesteExercicio') {
          expect(find.byKey(ExerciseKeys.stars), findsNothing);
          expect(find.byKey(ExerciseKeys.hintButton), findsNothing);
          expect(find.byKey(ExerciseKeys.timer), findsNothing);
          final board = tester.getRect(find.byKey(ExerciseKeys.board));
          expect(board.width, closeTo(size.width, 1));
          expect(find.text('Teste · 3 de 12'), findsOneWidget);
        }
        if (name == 'TesteResultado' || name == 'TesteNaoPassou') {
          expect(find.byKey(TestCanvasKeys.answer(11)), findsOneWidget);
          expect(
            find.text('Teste do capítulo 2 · $correct de 12'),
            findsOneWidget,
          );
          expect(find.byKey(ExercisesDoneKeys.redo), findsOneWidget);
          expect(find.byKey(ExercisesDoneKeys.back), findsOneWidget);
        }
        await capture.shot(tester, name, size);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }
}
