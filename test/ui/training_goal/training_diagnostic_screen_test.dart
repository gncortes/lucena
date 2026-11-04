import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/models/training/goal/training_diagnostic.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/core/motion/opcao_selecionavel.dart';
import 'package:lucena/ui/training_goal/view_models/training_goal_cubit.dart';
import 'package:lucena/ui/training_goal/widgets/training_diagnostic_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../domain/use_cases/training/goal/goal_rules_test.dart' show course;

/// H-TRE-04 e H-ANI-30: "Como montar o plano" tem duas opções de escolha
/// única (`OpcaoSelecionavel`) e o rodapé "Continuar", como o quadro
/// PropV2MetaDiagnostico. Tocar marca a opção; "Continuar" segue a marcada.
void main() {
  late List<String> abriu;

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

  Future<TrainingGoalCubit> abre(
    WidgetTester tester, {
    TrainingResources? recursos,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    abriu = [];
    final repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: recursos ?? comBanco()},
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
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: TrainingDiagnosticScreen(
            onBack: () {},
            onTest: () => abriu.add('teste'),
            onQuestionnaire: () => abriu.add('questionário'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  bool marcada(WidgetTester tester, Key chave) => tester
      .widget<OpcaoSelecionavel>(
        find.descendant(
          of: find.byKey(chave),
          matching: find.byType(OpcaoSelecionavel),
        ),
      )
      .selecionada;

  VoidCallback? continuar(WidgetTester tester) => tester
      .widget<FilledButton>(find.byKey(TrainingGoalKeys.diagnosticContinue))
      .onPressed;

  testWidgets('sem escolha: nada marcado e Continuar desligado', (
    tester,
  ) async {
    await abre(tester);
    expect(find.byType(OpcaoSelecionavel), findsNWidgets(2));
    expect(marcada(tester, TrainingGoalKeys.diagnosticTest), isFalse);
    expect(marcada(tester, TrainingGoalKeys.diagnosticQuestionnaire), isFalse);
    expect(continuar(tester), isNull);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('tocar marca na hora, sem abrir a próxima tela', (tester) async {
    await abre(tester);
    await tester.tap(find.byKey(TrainingGoalKeys.diagnosticQuestionnaire));
    await tester.pump();
    expect(marcada(tester, TrainingGoalKeys.diagnosticQuestionnaire), isTrue);
    expect(marcada(tester, TrainingGoalKeys.diagnosticTest), isFalse);
    expect(abriu, isEmpty);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TrainingGoalKeys.diagnosticTest));
    await tester.pumpAndSettle();
    expect(marcada(tester, TrainingGoalKeys.diagnosticTest), isTrue);
    expect(marcada(tester, TrainingGoalKeys.diagnosticQuestionnaire), isFalse);
  });

  testWidgets('Continuar com o teste marcado abre o teste', (tester) async {
    final cubit = await abre(tester);
    await tester.tap(find.byKey(TrainingGoalKeys.diagnosticTest));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TrainingGoalKeys.diagnosticContinue));
    await tester.pumpAndSettle();
    expect(abriu, ['teste']);
    expect(cubit.state.view!.state.diagnostic!.method, DiagnosticMethod.test);
  });

  testWidgets('Continuar com o questionário marcado abre o questionário', (
    tester,
  ) async {
    final cubit = await abre(tester);
    await tester.tap(find.byKey(TrainingGoalKeys.diagnosticQuestionnaire));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TrainingGoalKeys.diagnosticContinue));
    await tester.pumpAndSettle();
    expect(abriu, ['questionário']);
    expect(
      cubit.state.view!.state.diagnostic!.method,
      DiagnosticMethod.questionnaire,
    );
  });

  testWidgets('voltar com um teste começado: o teste já vem marcado', (
    tester,
  ) async {
    final cubit = await abre(tester);
    await cubit.chooseTest();
    await tester.pumpAndSettle();
    expect(marcada(tester, TrainingGoalKeys.diagnosticTest), isTrue);
    expect(continuar(tester), isNotNull);
  });

  testWidgets('sem o teste baixado: o questionário vem marcado e o teste '
      'não marca', (tester) async {
    await abre(tester, recursos: course());
    expect(find.byKey(TrainingGoalKeys.diagnosticOffline), findsOneWidget);
    expect(marcada(tester, TrainingGoalKeys.diagnosticQuestionnaire), isTrue);
    await tester.tap(find.byKey(TrainingGoalKeys.diagnosticTest));
    await tester.pumpAndSettle();
    expect(marcada(tester, TrainingGoalKeys.diagnosticTest), isFalse);
  });
}
