import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/training_goal/view_models/training_goal_cubit.dart';
import 'package:lucena/ui/training_goal/widgets/training_goal_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../course_guide/course_guide_catalog_layout_test.dart' show lesson;

/// PropV2MetaInicio: as opções com ícone, a data dentro do cartão do torneio
/// e o Continuar fixo na largura toda.
void main() {
  setUpAll(Goldens.loadFonts);

  Future<void> pump(WidgetTester tester) async {
    setPhoneSize(tester, const Size(412, 917));
    const config = TrainingCourseConfig.pilares;
    final repository = FakeTrainingRepository(
      content: {
        config.course: TrainingResources(lessons: [lesson('a1', 'alpha')]),
      },
      states: {
        config.course: TrainingState(
          course: config.course,
          installSeed: 'goal',
          onboardingDone: true,
        ),
      },
    );
    addTearDown(repository.dispose);
    final cubit = TrainingGoalCubit(
      repository: repository,
      config: config,
      now: FakeNow(DateTime(2026, 11, 25, 12)),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: TrainingGoalScreen(onBack: () {}, onContinue: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('as opções têm o ícone do quadro e o Continuar ocupa a largura '
      'toda, fixo embaixo', (tester) async {
    await pump(tester);
    final tournament = find.byKey(TrainingGoalKeys.goalTournament);
    final improve = find.byKey(TrainingGoalKeys.goalImprove);
    expect(
      find.descendant(
        of: tournament,
        matching: find.byIcon(Icons.stadium_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: improve, matching: find.byIcon(Icons.trending_up)),
      findsOneWidget,
    );
    final button = tester.getRect(find.byKey(TrainingGoalKeys.goalContinue));
    expect(button.width, 412 - 32);
    expect(button.height, 52);
    expect(button.bottom, greaterThan(917 - 80));
  });

  testWidgets('torneio marcado: a data, os dias que faltam e a agenda ficam '
      'dentro do cartão da opção', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(TrainingGoalKeys.goalTournament));
    await tester.pumpAndSettle();
    final card = find.byKey(TrainingGoalKeys.goalTournament);
    final row = find.byKey(TrainingGoalKeys.goalDateRow);
    expect(find.descendant(of: card, matching: row), findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.event)),
      findsOneWidget,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    // 14 de dezembro no seletor (hoje é 25 de novembro: abre em novembro).
    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('14'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: row, matching: find.text('Faltam 19 dias')),
      findsOneWidget,
    );
    final calendar = find.byKey(TrainingGoalKeys.goalAddToCalendar);
    expect(find.descendant(of: card, matching: calendar), findsOneWidget);
    expect(
      find.descendant(
        of: calendar,
        matching: find.byIcon(Icons.event_available_outlined),
      ),
      findsOneWidget,
    );
    expect(
      tester.getCenter(calendar).dx,
      closeTo(tester.getCenter(card.first).dx, 1),
    );
  });
}
