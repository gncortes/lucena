import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/achievement.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/ui/achievements/widgets/achievement_toast.dart';
import 'package:lucena/ui/achievements/widgets/achievement_ui.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';

import '../../../testing/test_app.dart';

void main() {
  const first = Achievement(
    id: 'first-fulfilled',
    type: AchievementType.firstFulfilled,
    icon: 'star',
  );
  const beat = Achievement(
    id: 'beat-1600',
    type: AchievementType.beatLevel,
    level: 1600,
  );
  const valdini = Character(
    id: 'magician',
    level: 1600,
    name: 'Valdini',
    tagline: {},
    personality: {},
    traits: [],
    avatar: 'assets/characters/magician/avatar.png',
  );

  Future<void> pumpToasts(
    WidgetTester tester,
    List<Achievement> achievements, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      TestApp(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: AchievementToasts(
              achievements: achievements,
              characters: const [valdini],
            ),
          ),
        ),
      ),
    );
  }

  String title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(AchievementsKeys.toastTitle)).data!;

  testWidgets('o aviso desce do alto, mostra a conquista e some sozinho', (
    tester,
  ) async {
    await pumpToasts(tester, [first]);
    await tester.pump();

    // Entrando: ainda acima do lugar dele.
    final entering = tester.getTopLeft(find.byKey(AchievementsKeys.toast)).dy;
    await tester.pump(const Duration(milliseconds: 1000));
    final resting = tester.getTopLeft(find.byKey(AchievementsKeys.toast)).dy;
    expect(entering, lessThan(resting));
    expect(find.text('Achievement unlocked'), findsOneWidget);
    expect(title(tester), 'First endgame');

    await tester.pump(AchievementToasts.duration);
    await tester.pump();
    expect(find.byKey(AchievementsKeys.toast), findsNothing);
  });

  testWidgets('várias conquistas: uma depois da outra, com o nome do '
      'personagem', (tester) async {
    await pumpToasts(tester, [first, beat]);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(title(tester), 'First endgame');

    await tester.pump(AchievementToasts.duration);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(title(tester), 'Beat Valdini');

    await tester.pumpAndSettle();
    expect(find.byKey(AchievementsKeys.toast), findsNothing);
  });

  test('com várias de uma vez, a fila inteira dura no máximo uns 8 s', () {
    expect(AchievementToasts.durationFor(1), AchievementToasts.duration);
    for (var count = 1; count <= 6; count++) {
      final total = AchievementToasts.durationFor(count) * count;
      expect(total, lessThanOrEqualTo(const Duration(milliseconds: 9600)));
    }
    expect(
      AchievementToasts.durationFor(4),
      lessThan(AchievementToasts.duration),
    );
  });

  testWidgets('não recebe toques: o que está embaixo continua usável', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
              ),
              const AchievementToasts(achievements: [first]),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.byKey(AchievementsKeys.toast), warnIfMissed: false);
    expect(taps, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('sem animações, o aviso aparece no lugar, sem deslizar', (
    tester,
  ) async {
    await pumpToasts(tester, [first], disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 50));
    final start = tester.getTopLeft(find.byKey(AchievementsKeys.toast)).dy;
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.getTopLeft(find.byKey(AchievementsKeys.toast)).dy, start);
    await tester.pumpAndSettle();
  });

  testWidgets('sem os personagens, o nome do motor; com eles, o do '
      'personagem', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) {
            l10n = context.l10n;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(beat.title(l10n), 'Beat Maia 1600');
    expect(beat.title(l10n, const [valdini]), 'Beat Valdini');
    expect(rungLabel(l10n, '1600', const [valdini]), 'Valdini');
    expect(rungLabel(l10n, 'stockfish', const [valdini]), 'Stockfish');
  });
}
