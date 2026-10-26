import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/goal_card.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  testWidgets('Finais conta capítulos da coleção, não lições do capítulo', (
    tester,
  ) async {
    final state = HomeState(
      goal: GoalPreference.endgames,
      endgameGoal: EndgameGoal(
        lesson: EndgameSummary(
          lessonId: 'test.chapter',
          title: 'Delétang',
          score: 0,
          maxScore: 6,
          teacher: FakeCharacterRepository.viktor,
          partNumber: 1,
          partCount: 4,
        ),
        number: 1,
        total: 6,
        passed: 0,
      ),
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(body: GoalCard(state: state)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delétang'), findsOneWidget);
    expect(find.text('Aprender finais · capítulo 1 de 6'), findsOneWidget);
    expect(find.text('0 de 6 capítulos concluídos em Finais'), findsOneWidget);
    expect(find.textContaining('lições'), findsNothing);
  });

  testWidgets('Escola preserva o vocabulário de aulas', (tester) async {
    const state = HomeState(
      goal: GoalPreference.learn,
      boardControlsDone: true,
      school: SchoolSummary(done: 1, total: 6, teacher: null),
    );
    await tester.pumpWidget(
      const TestApp(
        locale: Locale('pt'),
        child: Scaffold(body: GoalCard(state: state)),
      ),
    );
    await tester.pumpAndSettle();
    // A Escola está oculta pela política VisibleLessons: não inventar um
    // cartão de progresso quando esse caminho não está disponível.
    expect(find.text('1 de 6 aulas'), findsNothing);
    expect(find.textContaining('capítulos'), findsNothing);
  });
}
