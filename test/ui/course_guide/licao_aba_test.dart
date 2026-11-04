import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_continue_card.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

class _Checkpoint extends EndgameProgressRepository {
  _Checkpoint(this.value);
  EndgameProgress value;
  @override
  Future<EndgameProgress> load() async => value;
  @override
  Future<void> save(EndgameProgress progress) async => value = progress;
}

/// H-LIC-01, 03 e 04: o cartão da aba Lição com os textos do canvas
/// (PropV1TreinoAula, AulaPrimeira, LicaoRetomada).
void main() {
  final label = RegExp(r'^Parte [IVX]+ · Lição \d+$');

  Future<({CourseGuideCubit cubit, TrainingLesson? tapped})> open(
    WidgetTester tester, {
    required bool fresh,
    String? stoppedAt,
    int step = 0,
    void Function(TrainingLesson)? onLesson,
  }) async {
    setPhoneSize(tester, phoneSizes.last);
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final state = fresh
        ? TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'first',
            onboardingDone: true,
          )
        : scenario.large();
    final repository = FakeTrainingRepository(
      states: {TrainingCourse.pilares: state},
      content: {TrainingCourse.pilares: scenario.content},
    );
    EndgameProgressRepository? checkpoint;
    if (stoppedAt != null) {
      checkpoint = _Checkpoint(
        EndgameProgress(
          ongoing: LessonCheckpoint(
            lessonId: stoppedAt,
            part: 'x',
            step: step,
            scriptExample: 0,
            open: false,
          ),
        ),
      );
    }
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: scenario.now,
      testProgress: checkpoint,
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: CourseGuideScreen(
            onBack: () {},
            onPlan: () {},
            onHelp: () {},
            onWelcomeContinue: () {},
            onLesson: onLesson ?? (_) {},
            onChapter: (_) {},
            goalsBuilder: (_) => const SizedBox(),
            progressBuilder: (_) => const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (cubit: cubit, tapped: null);
  }

  testWidgets(
    'H-LIC-01: rótulo "Parte I · Lição N", Continuar, dicas e catálogo',
    (tester) async {
      TrainingLesson? tapped;
      final s = await open(tester, fresh: false, onLesson: (l) => tapped = l);
      final card = find.byType(CourseContinueCard);
      expect(card, findsOneWidget);
      final texts = tester
          .widgetList<Text>(
            find.descendant(of: card, matching: find.byType(Text)),
          )
          .map((t) => t.data)
          .toList();
      expect(texts.where((t) => t != null && label.hasMatch(t)), hasLength(1));
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Dicas de estudo'), findsOneWidget);
      expect(find.text('Pense antes de mover'), findsOneWidget);
      expect(find.text('Monte no tabuleiro'), findsOneWidget);
      await tester.tap(find.byKey(CourseGuideKeys.continueButton));
      expect(tapped, s.cubit.state.nextLesson);
      await tester.scrollUntilVisible(
        find.byKey(CourseGuideKeys.seeCatalog),
        150,
      );
      expect(find.text('Ver o catálogo'), findsOneWidget);
      await tester.tap(find.byKey(CourseGuideKeys.seeCatalog));
      await tester.pumpAndSettle();
      expect(s.cubit.state.training!.tab, CourseGuideTab.catalog);
    },
  );

  testWidgets('H-LIC-03: sem lição feita, o botão diz Começar e o rótulo é a '
      'Lição 1', (tester) async {
    await open(tester, fresh: true);
    expect(find.text('Parte I · Lição 1'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);
  });

  for (final (step, stage, body) in [
    (0, 'teoria', 'Você parou na teoria.'),
    (1, 'demonstração', 'Você parou na demonstração.'),
  ]) {
    testWidgets('H-LIC-04: lição parada na $stage', (tester) async {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final next = (await _firstPending(scenario)).id;
      await open(tester, fresh: false, stoppedAt: next, step: step);
      expect(find.textContaining('Você parou na $stage'), findsOneWidget);
      expect(find.textContaining(body), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      final card = find.byType(CourseContinueCard);
      final labels = tester
          .widgetList<Text>(
            find.descendant(of: card, matching: find.byType(Text)),
          )
          .map((t) => t.data)
          .whereType<String>();
      expect(
        labels.where((t) => RegExp('^Parte [IVX]+ · $stage\$').hasMatch(t)),
        hasLength(1),
      );
    });
  }
}

Future<TrainingLesson> _firstPending(TrainingScenarioBuilder scenario) async {
  final repository = FakeTrainingRepository(
    states: {TrainingCourse.pilares: scenario.large()},
    content: {TrainingCourse.pilares: scenario.content},
  );
  final cubit = CourseGuideCubit(
    repository: repository,
    config: TrainingCourseConfig.pilares,
    now: scenario.now,
  );
  await cubit.load();
  final lesson = cubit.state.nextLesson!;
  await cubit.close();
  await repository.dispose();
  return lesson;
}
