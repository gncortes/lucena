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

  testWidgets('sem onTap, não recebe toques: o que está embaixo continua '
      'usável', (tester) async {
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

  testWidgets('com onTap, tocar no aviso devolve a conquista (abre o '
      'detalhe); fora dele, o de baixo continua usável', (tester) async {
    var below = 0;
    Achievement? tapped;
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => below++,
              ),
              AchievementToasts(
                achievements: const [first],
                onTap: (achievement) => tapped = achievement,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.byKey(AchievementsKeys.toast));
    expect(tapped, first);
    expect(below, 0);
    await tester.tapAt(const Offset(200, 500));
    expect(below, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('datas em português: relativa na linha e completa no detalhe', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Builder(
          builder: (context) {
            l10n = context.l10n;
            return const SizedBox();
          },
        ),
      ),
    );
    final now = DateTime(2026, 10, 8, 9);

    expect(relativeDay(l10n, 'pt', DateTime(2026, 10, 8, 1), now), 'hoje');
    expect(relativeDay(l10n, 'pt', DateTime(2026, 10, 7, 23), now), 'ontem');
    expect(
      relativeDay(l10n, 'pt', DateTime(2026, 10, 5, 23), now),
      'há 3 dias',
    );
    expect(
      fullDateTime(l10n, 'pt', DateTime(2026, 10, 7, 22, 41)),
      '7 de out. de 2026, 22:41',
    );
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

  testWidgets('título longo numa faixa estreita: elipse, sem estourar', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 150,
              height: 64,
              child: AchievementToasts(
                achievements: const [beat],
                characters: const [
                  Character(
                    id: 'magician',
                    level: 1600,
                    name: 'Valdini o Grande Ilusionista Misterioso',
                    tagline: {},
                    personality: {},
                    traits: [],
                    avatar: 'assets/characters/magician/avatar.png',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byKey(AchievementsKeys.toast)).width,
      lessThanOrEqualTo(150),
    );
    expect(
      tester.widget<Text>(find.byKey(AchievementsKeys.toastTitle)).overflow,
      TextOverflow.ellipsis,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('a entrada tem mola leve: passa uns 5 px e assenta em 480 ms', (
    tester,
  ) async {
    await pumpToasts(tester, [first]);
    await tester.pump();
    final ys = <double>[];
    for (var ms = 0; ms <= 480; ms += 8) {
      ys.add(tester.getTopLeft(find.byKey(AchievementsKeys.toast)).dy);
      await tester.pump(const Duration(milliseconds: 8));
    }
    await tester.pump(const Duration(milliseconds: 600));
    final lugar = tester.getTopLeft(find.byKey(AchievementsKeys.toast)).dy;
    final maisBaixo = ys.reduce((a, b) => a > b ? a : b);
    final maisAlto = ys.reduce((a, b) => a < b ? a : b);
    expect(lugar - maisAlto, closeTo(64, 2));
    expect(maisBaixo - lugar, inInclusiveRange(3, 7));
    await tester.pumpAndSettle();
  });

  testWidgets('vários avisos: o anterior sai para cima e o próximo entra '
      '120 ms depois, sem corte seco', (tester) async {
    await pumpToasts(tester, [first, beat]);
    await tester.pump();
    final duracao = AchievementToasts.durationFor(2);
    // Logo antes de o primeiro sair: só ele.
    await tester.pump(duracao - const Duration(milliseconds: 400));
    expect(find.byKey(AchievementsKeys.toast), findsOneWidget);
    expect(title(tester), 'First endgame');
    // Saindo: sobe e some; o segundo ainda não entrou.
    await tester.pump(const Duration(milliseconds: 100));
    final saindo = tester.getTopLeft(find.byKey(AchievementsKeys.toast)).dy;
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getTopLeft(find.byKey(AchievementsKeys.toast)).dy,
      lessThan(saindo),
    );
    // 120 ms depois do início da saída, o segundo já existe (acima, caindo).
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(AchievementsKeys.toast), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.byKey(AchievementsKeys.toast), findsNothing);
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
