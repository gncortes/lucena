import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';
import '../core/motion/entrada_helpers.dart';

/// T85-D1 (Lição): a aba Aula do curso de finais é a tela do quadro
/// PropV1TreinoAula (ou AulaBoasVindas, antes do primeiro passo) e as
/// boas-vindas entram em cascata (H-ANI-16), como na Escola.
void main() {
  Future<void> open(
    WidgetTester tester, {
    required bool onboardingDone,
    bool reduzir = false,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = FakeTrainingRepository(
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'first',
          onboardingDone: onboardingDone,
        ),
      },
      content: {TrainingCourse.pilares: scenario.content},
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: scenario.now,
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 917),
          disableAnimations: reduzir,
        ),
        child: TestApp(
          locale: const Locale('pt'),
          child: BlocProvider.value(
            value: cubit,
            child: CourseGuideScreen(
              onBack: () {},
              onPlan: () {},
              onHelp: () {},
              onWelcomeContinue: () {},
              onLesson: (_) {},
              onChapter: (_) {},
              goalsBuilder: (_) => const SizedBox(),
              progressBuilder: (_) => const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }

  String? quadro(WidgetTester tester) {
    final telas = find.byType(EntradaDaTela);
    if (telas.evaluate().isEmpty) return null;
    return tester.widget<EntradaDaTela>(telas.first).id;
  }

  testWidgets('a aba Aula é a tela PropV1TreinoAula', (tester) async {
    await open(tester, onboardingDone: true);
    await tester.pumpAndSettle();
    expect(quadro(tester), 'PropV1TreinoAula');
  });

  group('boas-vindas (H-ANI-16)', () {
    testWidgets('são a tela PropV1TreinoAulaBoasVindas e entram em cascata, '
        'o botão por último', (tester) async {
      await open(tester, onboardingDone: false);
      await tester.pump();
      expect(quadro(tester), 'PropV1TreinoAulaBoasVindas');
      final titulo = find.byKey(MotionKeys.itemDaCascata(0));
      final botao = find.byKey(MotionKeys.itemDaCascata(2));
      expect(titulo, findsOneWidget);
      expect(botao, findsOneWidget);
      expect(opacidade(tester, botao), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacidade(tester, titulo), greaterThan(0));
      expect(opacidade(tester, botao), lessThan(opacidade(tester, titulo)));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(opacidade(tester, botao), 1);
      expect(find.byKey(CourseGuideKeys.continueButton), findsOneWidget);
    });

    testWidgets('movimento reduzido: tudo pronto no primeiro quadro', (
      tester,
    ) async {
      await open(tester, onboardingDone: false, reduzir: true);
      await tester.pump();
      expect(opacidade(tester, find.byKey(MotionKeys.itemDaCascata(2))), 1);
    });
  });
}
