import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/history/widgets/history_labels.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_rating_bonus_card.dart';

import '../../../testing/test_app.dart';

SpeedrunBonus _bonus(int before, int after) => SpeedrunBonus(
  attemptId: 1,
  speedrunId: 'ending.rook@600+0',
  before: PlayerRating.start(before),
  after: PlayerRating.start(after),
  at: DateTime(2026, 1, 1),
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget card, {
    Size size = const Size(360, 740),
    double scale = 1,
    Locale locale = const Locale('en'),
    ThemeMode mode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: mode,
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: card,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, Key key) => tester
      .widgetList<Text>(
        find.descendant(of: find.byKey(key), matching: find.byType(Text)),
      )
      .map((t) => t.data)
      .join(' | ');

  testWidgets('oferta mostra o título e a dica do ritmo', (tester) async {
    await pump(
      tester,
      const SpeedrunRatingBonusCard.offer(
        points: 30,
        group: PaceCategory.blitz,
      ),
    );
    final shown = text(tester, SpeedrunKeys.ratingBonusOffer);
    expect(shown, contains('30'));
    expect(shown, contains('Only the first time'));
    expect(find.byKey(SpeedrunKeys.ratingBonusEarned), findsNothing);
  });

  testWidgets('ganho mostra +N e antes -> depois numa linha', (tester) async {
    await pump(
      tester,
      SpeedrunRatingBonusCard.earned(bonus: _bonus(1237, 1267)),
    );
    final shown = text(tester, SpeedrunKeys.ratingBonusEarned);
    expect(shown, contains('1237 → 1267'));
    expect(shown, contains('+30'));
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
  });

  testWidgets('some com zero pontos', (tester) async {
    await pump(
      tester,
      Column(
        children: [
          const SpeedrunRatingBonusCard.offer(
            points: 0,
            group: PaceCategory.blitz,
          ),
          SpeedrunRatingBonusCard.earned(bonus: _bonus(1200, 1200)),
        ],
      ),
    );
    expect(find.byKey(SpeedrunKeys.ratingBonusOffer), findsNothing);
    expect(find.byKey(SpeedrunKeys.ratingBonusEarned), findsNothing);
  });

  for (final size in const [Size(360, 740), Size(412, 917)]) {
    for (final mode in ThemeMode.values.where((m) => m != ThemeMode.system)) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        testWidgets(
          'sem overflow, fonte 2,0, ${size.width.toInt()} $mode $locale',
          (tester) async {
            await pump(
              tester,
              Column(
                children: [
                  const SpeedrunRatingBonusCard.offer(
                    points: 45,
                    group: PaceCategory.ultraBullet,
                  ),
                  SpeedrunRatingBonusCard.earned(bonus: _bonus(1237, 1282)),
                ],
              ),
              size: size,
              scale: 2,
              mode: mode,
              locale: locale,
            );
            expect(tester.takeException(), isNull);
            for (final key in [
              SpeedrunKeys.ratingBonusOffer,
              SpeedrunKeys.ratingBonusEarned,
            ]) {
              final rect = tester.getRect(find.byKey(key));
              expect(rect.left, 16);
              expect(rect.width, closeTo(size.width - 32, 1));
              expect(rect.height, greaterThanOrEqualTo(48));
            }
          },
        );
      }
    }
  }

  testWidgets(
    'árabe isola "+N" e "antes ← depois" como LTR e espelha o ícone',
    (tester) async {
      await pump(
        tester,
        SpeedrunRatingBonusCard.earned(bonus: _bonus(1237, 1267)),
        locale: const Locale('ar'),
      );
      final shown = text(tester, SpeedrunKeys.ratingBonusEarned);
      expect(shown, contains(HistoryLabels.ltr('+30')));
      expect(shown, contains(HistoryLabels.ltr('1237 ← 1267')));
      final card = tester.getRect(find.byKey(SpeedrunKeys.ratingBonusEarned));
      final icon = tester.getRect(find.byIcon(Icons.trending_up));
      expect(icon.right, greaterThan(card.center.dx));
    },
  );
}
