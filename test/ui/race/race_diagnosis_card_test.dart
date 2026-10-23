import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/race_diagnosis.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/race/widgets/race_diagnosis_card.dart';

import '../../../testing/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, RaceDiagnosis diagnosis) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            child: RaceDiagnosisCard(diagnosis: diagnosis),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('antes de 3 Corridas: quantas faltam', (tester) async {
    await pump(tester, const RaceDiagnosis(runs: 1));
    expect(find.byKey(RaceKeys.diagnosisProgress), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.textContaining('2 more Races'), findsOneWidget);
    expect(find.byKey(RaceKeys.diagnosisWeakest), findsNothing);
  });

  testWidgets('3 Corridas sem problemas bastantes: ainda falta uma', (
    tester,
  ) async {
    await pump(tester, const RaceDiagnosis(runs: 3));
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.textContaining('1 more Race '), findsOneWidget);
  });

  testWidgets('o ponto mais fraco em destaque, os outros e os que vão bem', (
    tester,
  ) async {
    await pump(
      tester,
      const RaceDiagnosis(
        runs: 4,
        weak: [
          RaceCategoryScore(category: 'basic', errors: 11, total: 21),
          RaceCategoryScore(category: 'knightBishop', errors: 4, total: 11),
        ],
        good: [RaceCategoryScore(category: 'pawn', errors: 2, total: 16)],
      ),
    );
    expect(find.byKey(RaceKeys.diagnosisWeakest), findsOneWidget);
    expect(find.text('You missed 11 of 21 puzzles.'), findsOneWidget);
    expect(find.byKey(RaceKeys.diagnosisAlsoWeak), findsOneWidget);
    expect(find.textContaining('(missed 4 of 11)'), findsOneWidget);
    expect(find.byKey(RaceKeys.diagnosisGood('pawn')), findsOneWidget);
    expect(find.textContaining('latest 4 Races'), findsOneWidget);
  });

  testWidgets('nenhum fraco: a frase e os que vão bem', (tester) async {
    await pump(
      tester,
      const RaceDiagnosis(
        runs: 3,
        good: [RaceCategoryScore(category: 'pawn', errors: 0, total: 9)],
      ),
    );
    expect(find.byKey(RaceKeys.diagnosisNoWeak), findsOneWidget);
    expect(find.byKey(RaceKeys.diagnosisWeakest), findsNothing);
    expect(find.byKey(RaceKeys.diagnosisGood('pawn')), findsOneWidget);
  });
}
