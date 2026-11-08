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
        partes: const ['titulo', 'placar', 'viktor', 'botoes'],
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
  int? respondidas(WidgetTester tester) {
    for (final text in tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(MotionKeys.parteDoResultado('placar')),
        matching: find.byType(Text),
      ),
    )) {
      final m = RegExp(r'^(\d+) posiç').firstMatch(text.data ?? '');
      if (m != null) return int.parse(m.group(1)!);
    }
    return null;
  }

  testWidgets('H-ANI-18: as posições respondidas contam no lugar do placar', (
    tester,
  ) async {
    await abreNoResultado(tester, reduzido: false);
    expect(respondidas(tester), 0);
    await tester.pumpAndSettle();
    expect(respondidas(tester), greaterThan(0));
  });

  testWidgets('H-ANI-18: reduzido, o total já no primeiro quadro', (
    tester,
  ) async {
    await abreNoResultado(tester, reduzido: true);
    final fim = respondidas(tester);
    expect(fim, greaterThan(0));
    await tester.pumpAndSettle();
    expect(respondidas(tester), fim);
  });
}
