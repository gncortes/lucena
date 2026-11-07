import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/goal/training_diagnostic.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/core/motion/movimento_reduzido.dart';
import 'package:lucena/ui/training_goal/view_models/training_goal_cubit.dart';
import 'package:lucena/ui/training_goal/widgets/training_questionnaire_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../domain/use_cases/training/goal/goal_rules_test.dart' show course;

/// H-ANI-30 no questionário (PropV2MetaQuestB): o nível tocado se enche de
/// cor em 200 ms (`emphasized`); com movimento reduzido, troca na hora.
void main() {
  Future<void> abre(WidgetTester tester, {bool reduzir = false}) async {
    setPhoneSize(tester, const Size(412, 917));
    final repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: course()},
    );
    final cubit = TrainingGoalCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(DateTime(2026, 11, 4, 10)),
      afterSave: (_) async {},
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    await cubit.chooseQuestionnaire();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(412, 917),
            disableAnimations: reduzir,
          ),
          child: BlocProvider.value(
            value: cubit,
            child: TrainingQuestionnaireScreen(onBack: () {}, onBuilt: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A cor de fundo do segmento (o `Material` do botão por dentro).
  Color fundo(WidgetTester tester, TopicLevel nivel) {
    final material = find
        .ancestor(
          of: find.byKey(TrainingGoalKeys.questLevel('p1', nivel.name)),
          matching: find.byType(Material),
        )
        .first;
    return tester.widget<Material>(material).color ?? const Color(0x00000000);
  }

  testWidgets('o nível tocado se enche de cor em 200 ms', (tester) async {
    await abre(tester);
    final vazio = fundo(tester, TopicLevel.practicing);
    await tester.tap(
      find.byKey(TrainingGoalKeys.questLevel('p1', TopicLevel.practicing.name)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final meio = fundo(tester, TopicLevel.practicing);
    await tester.pumpAndSettle();
    final cheio = fundo(tester, TopicLevel.practicing);
    expect(cheio, isNot(vazio));
    expect(meio, isNot(vazio), reason: 'em 100 ms a cor já mudou');
    expect(meio, isNot(cheio), reason: 'em 100 ms a cor ainda não chegou');
  });

  testWidgets('com movimento reduzido, troca na hora', (tester) async {
    await abre(tester, reduzir: true);
    await tester.tap(
      find.byKey(TrainingGoalKeys.questLevel('p1', TopicLevel.practicing.name)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final logo = fundo(tester, TopicLevel.practicing);
    await tester.pumpAndSettle();
    expect(logo, fundo(tester, TopicLevel.practicing));
    expect(
      MovimentoReduzido.of(tester.element(find.byType(Scaffold).first)),
      isTrue,
    );
  });
}
