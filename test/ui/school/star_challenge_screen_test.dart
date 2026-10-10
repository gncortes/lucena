import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';
import 'package:lucena/domain/use_cases/star_challenge_rules.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/star_challenge_cubit.dart';
import 'package:lucena/ui/school/widgets/star_challenge_screen.dart';
import 'package:lucena/ui/school/widgets/star_challenges_screen.dart';
import 'package:lucena/ui/school/widgets/star_scoreboard.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_star_challenge_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeNow now;
  late FakeStarChallengeRepository progress;

  setUp(() {
    now = FakeNow(DateTime(2026, 10, 6, 10));
    progress = FakeStarChallengeRepository();
  });

  Future<SettingsCubit> settings() async {
    final cubit = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  Future<StarChallengeCubit> pump(
    WidgetTester tester, {
    ChallengeLevel level = ChallengeLevel.easy,
  }) async {
    // Tela de celular: o tabuleiro ocupa a largura.
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final cubit = StarChallengeCubit(
      progress: progress,
      now: now,
      random: Random(5),
      tickEvery: const Duration(hours: 1),
    );
    addTearDown(cubit.close);
    await cubit.load(ChallengePiece.rook, level);
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: BlocProvider.value(
          value: cubit,
          child: const StarChallengeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('às cegas: a estrela vem pelo nome da casa, sem desenho', (
    tester,
  ) async {
    final cubit = await pump(tester, level: ChallengeLevel.named);
    await tester.tap(find.byKey(StarChallengeKeys.goButton));
    await tester.pumpAndSettle();

    final star = cubit.state.star!;
    expect(find.byKey(StarChallengeKeys.star(star.name)), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(StarChallengeKeys.starName)).data,
      star.name,
    );
    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
  });

  testWidgets('"vai", a estrela aparece, pegar conta e o fim mostra a nota', (
    tester,
  ) async {
    final cubit = await pump(tester);
    expect(find.text('Rook challenge'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(StarChallengeKeys.levelChip),
        matching: find.text('Easy'),
      ),
      findsOneWidget,
    );
    expect(find.text('1:00'), findsOneWidget);
    await tester.tap(find.byKey(StarChallengeKeys.goButton));
    await tester.pumpAndSettle();

    final star = cubit.state.star!;
    expect(find.byKey(StarChallengeKeys.star(star.name)), findsOneWidget);
    final board = LessonRules.starsBoard(cubit.state.fen!);
    final from = StarChallengeRules.pieceSquare(board)!;
    final rect = tester.getRect(find.byKey(StarChallengeKeys.board));
    await tester.tapAt(squareCenter(rect, from.name));
    await tester.pump();
    await tester.tapAt(squareCenter(rect, star.name));
    await tester.pumpAndSettle();
    expect(cubit.state.points, greaterThan(0));
    // O painel embaixo do tabuleiro: a cor da estrela pega e o total.
    final kind = StarKind.values.firstWhere((k) => cubit.state.countOf(k) > 0);
    expect(
      tester
          .widget<Text>(find.byKey(StarChallengeKeys.kindCount(kind.name)))
          .data,
      '1',
    );
    expect(
      tester.widget<Text>(find.byKey(StarChallengeKeys.collected)).data,
      cubit.state.points == 1 ? '1 point' : '${cubit.state.points} points',
    );

    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
    expect(find.byKey(StarChallengeKeys.result), findsOneWidget);
    expect(find.text("Time's up!"), findsOneWidget);
    expect(find.text('New best!'), findsOneWidget);
    expect(find.byKey(StarChallengeKeys.retryButton), findsOneWidget);
  });

  testWidgets('o painel: estrelas de cada cor e o total de pontos', (
    tester,
  ) async {
    final scores = ValueNotifier<(Map<StarKind, int>, int)>((const {}, 0));
    addTearDown(scores.dispose);
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: Scaffold(
          body: Center(
            child: ValueListenableBuilder(
              valueListenable: scores,
              builder: (context, value, _) =>
                  StarScoreboard(counts: value.$1, points: value.$2),
            ),
          ),
        ),
      ),
    );
    String text(Key key) => tester.widget<Text>(find.byKey(key)).data!;

    await tester.pumpAndSettle();
    for (final kind in StarKind.values) {
      expect(text(StarChallengeKeys.kindCount(kind.name)), '0');
    }
    expect(text(StarChallengeKeys.collected), '0 points');

    // Duas de bronze, uma de prata, três de ouro: 2 + 2 + 9 = 13.
    scores.value = (
      const {StarKind.bronze: 2, StarKind.silver: 1, StarKind.gold: 3},
      13,
    );
    await tester.pump();
    // No meio da animação o total ainda está subindo.
    await tester.pump(const Duration(milliseconds: 50));
    expect(text(StarChallengeKeys.collected), isNot('13 points'));
    await tester.pumpAndSettle();
    expect(text(StarChallengeKeys.kindCount('bronze')), '2');
    expect(text(StarChallengeKeys.kindCount('silver')), '1');
    expect(text(StarChallengeKeys.kindCount('gold')), '3');
    expect(text(StarChallengeKeys.collected), '13 points');
  });

  testWidgets('o tabuleiro fica com o centro no centro do espaço útil, '
      'entre a barra do app e o fim da tela, no convite e jogando', (
    tester,
  ) async {
    final cubit = await pump(tester);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final appBar = tester.getRect(find.byType(AppBar));
    final center = (appBar.bottom + screen.height) / 2;
    final ready = tester.getRect(find.byKey(StarChallengeKeys.board));
    expect(ready.center.dy, closeTo(center, 1));
    await tester.tap(find.byKey(StarChallengeKeys.goButton));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(StarChallengeKeys.board));
    expect(rect, ready);
    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
  });

  testWidgets('a lista: seis peças, três níveis, a melhor marca', (
    tester,
  ) async {
    progress = FakeStarChallengeRepository(
      const StarChallengeProgress().withBest(
        ChallengePiece.knight,
        ChallengeLevel.hard,
        7,
      ),
    );
    final cubit = StarChallengesCubit(progress: progress);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: BlocProvider.value(
          value: cubit,
          child: const StarChallengesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(StarChallengeKeys.listScreen), findsOneWidget);
    // A lista monta por partes: rola até cada peça.
    for (final piece in ChallengePiece.values) {
      await tester.scrollUntilVisible(
        find.byKey(StarChallengeKeys.challenge(piece.name, 'easy')),
        200,
      );
      expect(
        find.byKey(StarChallengeKeys.challenge(piece.name, 'hard')),
        findsOneWidget,
      );
    }
    await tester.scrollUntilVisible(
      find.byKey(StarChallengeKeys.challenge('knight', 'hard')),
      -200,
    );
    expect(find.text('Best: 7'), findsOneWidget);
  });
}
