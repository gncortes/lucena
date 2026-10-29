import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/ui/core/widgets/animated_progress.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_item_tile.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  setUpAll(Goldens.loadFonts);
  for (final sample in [
    'first',
    'second',
    'dayOff',
    'large',
    'done',
    'doneExtra',
  ]) {
    testWidgets('goals QA $sample preserves Canvas presentation', (
      tester,
    ) async {
      setPhoneSize(tester, const Size(412, 917));
      final source = TrainingScenarioBuilder(TrainingCourse.pilares).content;
      final indexed = TrainingResources(
        lessons: [
          for (final (i, lesson) in source.lessons.indexed) ...[
            if (i == 8)
              const TrainingLesson(
                id: 'chapter-test',
                kind: TrainingLessonKind.test,
                title: 'Teste do capítulo',
                partId: 'active',
                groupId: 'active',
              ),
            TrainingLesson(
              id: lesson.id,
              kind: lesson.kind,
              title: lesson.title,
              summary: lesson.summary,
              partId: i < 8 ? 'previous' : 'active',
              groupId: i < 8 ? 'previous' : 'active',
            ),
          ],
        ],
        banks: source.banks,
        openings: source.openings,
      );
      final scenario = TrainingScenarioBuilder(
        TrainingCourse.pilares,
        resources: indexed,
      );
      final training = scenario.goalsScenario(sample);
      final repository = scenario.repository(training);
      final cubit = CourseGuideCubit(
        repository: repository,
        config: scenario.config,
        now: scenario.now,
        characters: FakeCharacterRepository(),
      );
      addTearDown(cubit.close);
      addTearDown(repository.dispose);
      await cubit.load();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              body: TrainingGoalsTab(onGoal: (_) {}, onPlan: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (sample == 'first') {
        expect(find.text('AULA'), findsNothing);
        final info = find.text(
          'Ao concluir uma aula, o tema dela entra nas metas por 7 dias, um exercício por dia.',
        );
        final panel = tester.widget<Material>(
          find.ancestor(of: info, matching: find.byType(Material)).first,
        );
        expect(
          panel.color,
          Theme.of(tester.element(info)).colorScheme.primaryContainer,
        );
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      } else if (sample == 'second') {
        expect(find.text('AULA'), findsOneWidget);
      } else if (sample == 'doneExtra') {
        expect(
          tester.getSize(find.byKey(TrainingKeys.doubleButton)).height,
          52,
        );
        expect(find.text('AULAS'), findsOneWidget);
      } else if (sample == 'dayOff') {
        expect(find.text('Plano: 0 dias de estudo'), findsOneWidget);
        final info = find.text(
          'A aula adiantada conta como meta feita. Os exercícios dela entram no próximo dia de estudo.',
        );
        final panel = tester.widget<Material>(
          find.ancestor(of: info, matching: find.byType(Material)).first,
        );
        expect(
          panel.color,
          Theme.of(tester.element(info)).colorScheme.primaryContainer,
        );
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(
          tester
              .widget<CourseItemTile>(find.byType(CourseItemTile).first)
              .title,
          startsWith('Aula 1 · '),
        );
      } else if (sample == 'large') {
        final progress = tester.widget<AnimatedProgress>(
          find.byType(AnimatedProgress),
        );
        expect(progress.backgroundColor, const Color(0xffc4c6d0));
        expect(
          tester
              .widget<CourseItemTile>(find.byType(CourseItemTile).first)
              .title,
          startsWith('Aula 1 · '),
        );
      } else {
        final list = tester.widget<ListView>(find.byType(ListView));
        final delegate = list.childrenDelegate as SliverChildListDelegate;
        expect(delegate.children.length, training.day!.goals.length + 1);
        final speech = find.byType(TeacherSpeech);
        expect(tester.widget<TeacherSpeech>(speech).avatarSize, 40);
        expect(
          Theme.of(tester.element(speech)).textTheme.bodyLarge!.fontSize,
          14,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
