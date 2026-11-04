import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/training_goal/view_models/training_goal_cubit.dart';
import 'package:lucena/ui/training_goal/widgets/training_test_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/motion_expectations.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../domain/use_cases/training/goal/goal_rules_test.dart' show course;

/// H-ANI-25: o resultado do teste da meta (PropV2MetaTesteResultado) se monta
/// em ordem: o título sobe, a frase entra, onde o jogador está vem depois e
/// "Ver o plano" desliza por último. Sem animações, tudo pronto.
void main() {
  /// O curso com um exercício por lição: o teste está baixado.
  TrainingResources comBanco() {
    final base = course();
    return TrainingResources(
      lessons: base.lessons,
      banks: {
        for (final l in base.lessons)
          l.id: [
            TrainingExercise(
              id: '${l.id}.e1',
              stars: 1,
              fen: GameRules.initial.fen,
              solution: const ['e2e4'],
              mock: true,
            ),
          ],
      },
    );
  }

  Future<void> abreNoResultado(
    WidgetTester tester, {
    required bool reduzido,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    final repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: comBanco()},
    );
    final cubit = TrainingGoalCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(DateTime(2026, 11, 4, 10)),
      afterSave: (_) async {},
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    {
      await cubit.load();
      expect(await cubit.chooseTest(), isTrue);
      for (var i = 0; i < 40; i++) {
        if (cubit.state.view!.state.diagnostic!.testComplete) break;
        await cubit.answerTest(true);
      }
      expect(cubit.state.view!.state.diagnostic!.testComplete, isTrue);
    }
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(412, 917),
            disableAnimations: reduzido,
          ),
          child: BlocProvider.value(
            value: cubit,
            child: TrainingTestScreen(onBack: () {}, onSeePlan: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final reduzido in [false, true]) {
    testWidgets('H-ANI-25: o resultado se monta em ordem (reduzido: '
        '$reduzido)', (tester) async {
      await abreNoResultado(tester, reduzido: reduzido);
      expect(find.byKey(TrainingGoalKeys.testResult), findsOneWidget);
      expectEntradaDeResultado(
        tester,
        partes: const ['titulo', 'subtitulo', 'viktor', 'botoes'],
        animando: !reduzido,
      );
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.parteDoResultado('titulo')),
          matching: find.byKey(TrainingGoalKeys.testResult),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.parteDoResultado('botoes')),
          matching: find.byKey(TrainingGoalKeys.testSeePlan),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 1300));
      expect(
        opacidadeDaParte(
          tester,
          find.byKey(MotionKeys.parteDoResultado('botoes')),
        ),
        1,
      );
      await tester.pumpAndSettle();
    });
  }
}
