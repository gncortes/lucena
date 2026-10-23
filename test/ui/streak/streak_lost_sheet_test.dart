import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/streak.dart';
import 'package:lucena/ui/core/keys/streak_keys.dart';
import 'package:lucena/ui/streak/widgets/streak_lost_sheet.dart';

import '../../../testing/test_app.dart';

void main() {
  const streak = Streak(current: 0, record: 21, activeToday: false, lost: 12);

  Future<List<String>> open(WidgetTester tester) async {
    final played = <String>[];
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showStreakLostSheet(
                context,
                streak: streak,
                onPlay: () => played.add('dia'),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return played;
  }

  testWidgets('diz quantos dias acabaram e que o recorde fica', (tester) async {
    await open(tester);
    expect(find.text('A sequência de 12 dias acabou'), findsOneWidget);
    expect(find.textContaining('recorde de 21 dias'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('"Jogar o final do dia" fecha e abre o final', (tester) async {
    final played = await open(tester);
    await tester.tap(find.byKey(StreakKeys.lostPlay));
    await tester.pumpAndSettle();
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
    expect(played, ['dia']);
  });

  testWidgets('"Agora não" só fecha', (tester) async {
    final played = await open(tester);
    await tester.tap(find.byKey(StreakKeys.lostNo));
    await tester.pumpAndSettle();
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
    expect(played, isEmpty);
  });
}
