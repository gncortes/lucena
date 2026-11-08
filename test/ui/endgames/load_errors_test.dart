import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/load_failure.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgame_lesson_screen.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';
import 'package:lucena/ui/school/widgets/school_screen.dart';

import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/test_app.dart';

class _Lessons extends FakeEndgameLessonRepository {
  Object? failure;
  @override
  Future<EndgameTrail> trail() async {
    if (failure case final error?) throw error;
    return super.trail();
  }
}

class _SchoolLessons extends FakeLessonRepository {
  Object? failure;
  @override
  Future<Course> course() async {
    if (failure case final error?) throw error;
    return super.course();
  }
}

void main() {
  test(
    'exercício com falha de conteúdo permite repetir o carregamento',
    () async {
      final lessons = _Lessons()..failure = const LessonContentUnavailable();
      final cubit = ExerciseCubit(
        lessons: lessons,
        progress: FakeEndgameProgressRepository(),
        characters: FakeCharacterRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load('rook.lucena', 'e01', 'pt');
      expect((cubit.state as dynamic).failure, LoadFailure.unavailable);
      lessons.failure = null;
      await cubit.load('rook.lucena', 'e01', 'pt');
      expect(cubit.state.exercise?.id, 'e01');
    },
  );
  testWidgets('trilha de finais informa falha e retry carrega', (tester) async {
    final lessons = _Lessons()..failure = StateError('banco');
    final cubit = EndgamesCubit(
      lessons: lessons,
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load('pt');
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const TestApp(locale: Locale('pt'), child: EndgamesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    lessons.failure = null;
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pumpAndSettle();
    expect(cubit.state.trail.lessons, isNotEmpty);
  });

  testWidgets('escola informa pacote ausente e retry carrega', (tester) async {
    final lessons = _SchoolLessons()
      ..failure = const LessonContentUnavailable();
    final cubit = SchoolCubit(
      lessons: lessons,
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load('pt');
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const TestApp(locale: Locale('pt'), child: SchoolScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Conteúdo indisponível'), findsOneWidget);
    lessons.failure = null;
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pumpAndSettle();
    expect(cubit.state.course.lessons, isNotEmpty);
  });
  for (final (error, title, expected) in <(Object, String, LoadFailure)>[
    (StateError('banco'), 'Ocorreu um erro inesperado', LoadFailure.generic),
    (
      const LessonContentUnavailable(),
      'Conteúdo indisponível',
      LoadFailure.unavailable,
    ),
    (
      const LessonContentNotFound(),
      'Conteúdo indisponível',
      LoadFailure.unavailable,
    ),
    (
      const LessonContentNetworkUnavailable(),
      'Sem internet',
      LoadFailure.offline,
    ),
    (
      const LessonContentStorageUnavailable(1),
      'Falta espaço no celular',
      LoadFailure.noSpace,
    ),
  ]) {
    testWidgets(
      'aula: $expected mostra causa e retry recupera sem apagar progresso',
      (tester) async {
        final lessons = _Lessons()..failure = error;
        final progress = FakeEndgameProgressRepository(
          const EndgameProgress(
            ongoing: LessonCheckpoint(lessonId: 'rook.lucena', step: 1),
          ),
        );
        final cubit = EndgameLessonCubit(
          lessons: lessons,
          progress: progress,
          journey: FakeJourneyRepository(),
          characters: FakeCharacterRepository(),
        );
        addTearDown(cubit.close);
        await cubit.load('rook.lucena', 'pt');
        expect(cubit.state.failure, expected);
        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: const TestApp(
              locale: Locale('pt'),
              child: EndgameLessonScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
        expect(progress.saved.ongoing?.step, 1);
        lessons.failure = null;
        await tester.tap(find.byKey(LoadErrorKeys.action));
        await tester.pumpAndSettle();
        expect(cubit.state.lesson?.id, 'rook.lucena');
        expect(find.byKey(LoadErrorKeys.screen), findsNothing);
      },
    );
  }
}
