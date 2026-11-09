import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

void main() {
  final resources = TrainingResources(
    lessons: [
      const TrainingLesson(
        id: 'theme',
        kind: TrainingLessonKind.theme,
        title: 'Garfo de cavalo',
      ),
    ],
  );

  Future<CourseGuideCubit> load({
    required String completedOn,
    required DateTime today,
  }) async {
    final repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: resources},
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'seed',
          completedLessons: {'theme': completedOn},
          // A conclusão da lição abre o ciclo do tema, ainda sem exercícios.
          cycles: {
            'theme': ThemeCycle(lessonId: 'theme', startedOn: completedOn),
          },
        ),
      },
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(today),
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    return cubit;
  }

  Future<void> show(WidgetTester tester, CourseGuideCubit cubit) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: Scaffold(body: TrainingProgressTab(onTheme: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('1 lição concluída hoje: sem vazio, com Hoje e o tema', (
    tester,
  ) async {
    await show(
      tester,
      await load(completedOn: '2026-10-28', today: DateTime(2026, 10, 28)),
    );
    expect(find.byKey(TrainingKeys.progressEmpty), findsNothing);
    expect(find.byKey(TrainingKeys.progressToday), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('1 lição concluída'), findsOneWidget);
    expect(find.byKey(TrainingKeys.masteryRow('theme')), findsOneWidget);
    expect(find.text('Garfo de cavalo'), findsOneWidget);
    expect(find.text('0 de 7'), findsOneWidget);
  });

  testWidgets('lição de outro dia: tema aparece, cartão Hoje não', (
    tester,
  ) async {
    await show(
      tester,
      await load(completedOn: '2026-10-27', today: DateTime(2026, 10, 28)),
    );
    expect(find.byKey(TrainingKeys.progressEmpty), findsNothing);
    expect(find.byKey(TrainingKeys.progressToday), findsNothing);
    expect(find.byKey(TrainingKeys.masteryRow('theme')), findsOneWidget);
  });
}
