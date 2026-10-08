import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/player_stats.dart';
import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';
import 'package:lucena/ui/profile/widgets/stats_row.dart';

import '../../../../testing/test_app.dart';
import 'one_line_check.dart';

void main() {
  const stats = PlayerStats(games: 128, wins: 74, streakDays: 12);

  Future<void> pump(
    WidgetTester tester,
    PlayerNumbers numbers, {
    double width = 412,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StatsRow(numbers: numbers),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect rect(WidgetTester tester, int index) =>
      tester.getRect(find.byKey(RatingKeys.stat(index)));

  // Os idiomas que mais apertam: o português, o alemão (palavras longas), o
  // árabe (da direita para a esquerda) e o pseudo-idioma (40% mais longo).
  const locales = [
    Locale('pt'),
    Locale('de'),
    Locale('ar'),
    Locale('en', 'XA'),
  ];

  for (final width in [320.0, 412.0]) {
    for (final locale in locales) {
      testWidgets('cinco números em $locale, ${width.round()} dp: grade 2 × 2 '
          'e o último na linha inteira, mesma altura, nada quebrado', (
        tester,
      ) async {
        await pump(
          tester,
          const PlayerNumbers(
            stats: stats,
            achievementsUnlocked: 17,
            achievementsTotal: 42,
            bestSpeedrun: Duration(minutes: 12, seconds: 34),
          ),
          width: width,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
        final full = tester.getRect(find.byKey(RatingKeys.stats));
        final rects = [
          for (var index = 0; index < 5; index++) rect(tester, index),
        ];
        // Duas linhas de dois, lado a lado, da mesma largura.
        for (final row in [0, 2]) {
          expect(rects[row].top, rects[row + 1].top);
          expect(rects[row].width, closeTo(rects[row + 1].width, 0.01));
          expect(rects[row].width, lessThan(full.width / 2));
        }
        expect(rects[2].top, greaterThan(rects[0].bottom));
        // O quinto ocupa a linha inteira: sem buraco.
        expect(rects[4].top, greaterThan(rects[2].bottom));
        expect(rects[4].width, closeTo(full.width, 0.01));
        // Todos da mesma altura.
        for (final card in rects) {
          expect(card.height, closeTo(rects.first.height, 0.01));
        }
        expectNoWrappedText(tester, find.byKey(RatingKeys.stats));
      });
    }
  }

  testWidgets('quatro números: 2 × 2, sem linha inteira', (tester) async {
    await pump(tester, const PlayerNumbers(stats: stats), width: 320);

    final full = tester.getRect(find.byKey(RatingKeys.stats));
    expect(find.byKey(RatingKeys.stat(4)), findsNothing);
    expect(rect(tester, 3).top, rect(tester, 2).top);
    expect(rect(tester, 3).width, lessThan(full.width / 2));
    expect(rect(tester, 3).height, closeTo(rect(tester, 0).height, 0.01));
    // Número e rótulo no cartão.
    expect(
      find.descendant(
        of: find.byKey(RatingKeys.stat(0)),
        matching: find.text('128'),
      ),
      findsOne,
    );
  });
}
