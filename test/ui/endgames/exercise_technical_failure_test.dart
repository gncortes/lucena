import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/exercise_judge.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

// Falha negativa de transporte, sem resultado/WDL inventado.
class _UnavailableProofs implements ExerciseProofProvider {
  int calls = 0;
  @override
  Future<ExerciseJudgement> lookup(String fen) async {
    calls++;
    throw StateError('transport unavailable');
  }
}

class _Lessons extends FakeEndgameLessonRepository {
  _Lessons() : super(trail: _trail);
  static final _sample =
      FakeEndgameLessonRepository.sample.modules.first.lessons.first;
  static final _trail = EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: _sample.id,
            module: _sample.module,
            lesson: _sample.lesson,
            exercises: [
              Exercise(
                id: 'e01',
                stars: 3,
                fen: FakeEndgameLessonRepository.lucenaFen,
                goal: _sample.exercises.first.goal,
                line: _sample.exercises.first.line,
                completion: ExerciseCompletion.checkmate,
              ),
            ],
            passScore: _sample.passScore,
            keyPositions: _sample.keyPositions,
            practice: _sample.practice,
          ),
        ],
      ),
    ],
  );
  int loads = 0;
  final languages = <String>[];
  Completer<void>? gate;
  @override
  Future<EndgameTrail> trail() async {
    loads++;
    await gate?.future;
    return super.trail();
  }

  @override
  Future<LessonTexts> texts(String language) {
    languages.add(language);
    return super.texts(language);
  }
}

void main() {
  Future<
    ({
      ExerciseCubit cubit,
      _Lessons lessons,
      _UnavailableProofs proofs,
      FakeEndgameProgressRepository progress,
    })
  >
  open(WidgetTester tester) async {
    final lessons = _Lessons();
    final proofs = _UnavailableProofs();
    final progress = FakeEndgameProgressRepository();
    final cubit = ExerciseCubit(
      lessons: lessons,
      progress: progress,
      characters: FakeCharacterRepository(),
      exerciseJudge: ExerciseJudge(proofs),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'e01', 'pt');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final router = GoRouter(
      initialLocation: '/exercise',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(key: Key('returned')),
          routes: [
            GoRoute(
              path: 'exercise',
              builder: (_, _) => BlocProvider.value(
                value: cubit,
                child: const ExerciseScreen(),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ExerciseKeys.technicalFailure), findsNothing);
    expect(cubit.state.interactive, isTrue);
    await cubit.askHint();
    await cubit.play(Move.parse('c1c4')!);
    await tester.pumpAndSettle();
    expect(cubit.state.technicalFailure, isNotNull);
    expect(proofs.calls, 1);
    return (cubit: cubit, lessons: lessons, proofs: proofs, progress: progress);
  }

  for (final size in const [
    Size(360, 740),
    Size(360, 800),
    Size(384, 832),
    Size(393, 873),
    Size(412, 915),
    Size(414, 896),
  ]) {
    testWidgets('falha técnica visível no layout atual, sem nota: $size', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final s = await open(tester);
      expect(find.byKey(ExerciseKeys.technicalFailure), findsOneWidget);
      expect(
        find.textContaining('Não foi possível continuar', findRichText: true),
        findsOneWidget,
      );
      expect(find.byKey(ExerciseKeys.technicalRetry), findsOneWidget);
      expect(find.byKey(ExerciseKeys.backButton), findsOneWidget);
      expect(find.byKey(ExerciseKeys.stars), findsNothing);
      expect(find.byKey(ExerciseKeys.hintButton), findsNothing);
      expect(find.byKey(ExerciseKeys.showSolution), findsNothing);
      expect(find.byKey(ExerciseKeys.earned), findsNothing);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(
        tester.getRect(find.byKey(LessonScriptKeys.speech)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byKey(ExerciseKeys.board)).top),
      );
      expect(s.cubit.state.interactive, isFalse);
      await tester.pump(const Duration(seconds: 3));
      expect(s.lessons.loads, 1); // Nenhum retry automático.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('retry chama load uma vez e preserva assistência/checkpoint', (
    tester,
  ) async {
    final s = await open(tester);
    final checkpoint = s.progress.saved.of('rook.lucena').exercise!;
    final before = s.cubit.state;
    s.lessons.gate = Completer<void>();
    await tester.tap(find.byKey(ExerciseKeys.technicalRetry));
    await tester.pump();
    expect(s.lessons.loads, 2);
    expect(find.byKey(ExerciseKeys.technicalRetry), findsNothing);
    s.lessons.gate!.complete();
    await tester.pumpAndSettle();
    expect(s.cubit.state.technicalFailure, isNull);
    expect(s.cubit.state.interactive, isTrue);
    expect(s.cubit.state.hints, before.hints);
    expect(before.hints, 1);
    expect(s.cubit.state.mistakes, before.mistakes);
    expect(s.cubit.state.fen, before.fen);
    expect(s.cubit.state.played, before.played);
    expect(
      s.progress.saved.of('rook.lucena').exercise!.hints,
      checkpoint.hints,
    );
    expect(s.progress.saved.of('rook.lucena').stars, isEmpty);
    expect(s.lessons.languages, ['pt', 'pt']);
    expect(s.proofs.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voltar sai da falha sem nota ou tentativa apagada', (
    tester,
  ) async {
    final s = await open(tester);
    final checkpoint = s.progress.saved.of('rook.lucena').exercise!;
    await tester.tap(find.byKey(ExerciseKeys.backButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('returned')), findsOneWidget);
    expect(s.progress.saved.of('rook.lucena').exercise!.toJson(), {
      ...checkpoint.toJson(),
      'open': false,
    });
    expect(
      s.progress.saved.of('rook.lucena').exercise!.hints,
      checkpoint.hints,
    );
    expect(s.progress.saved.of('rook.lucena').stars, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
