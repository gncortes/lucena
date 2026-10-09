import 'dart:async';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/conclusion/widgets/conclusion_screen.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/free_board/view_models/game_reporter.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_share_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_app.dart';

// Uma partida longa: 16 lances (a dama e o rei indo e voltando).
const _longMoves = [
  'c1b1', 'd7e7', 'b1c1', 'e7d7', //
  'c1b1', 'd7e7', 'b1c1', 'e7d7',
  'c1b1', 'd7e7', 'b1c1', 'e7d7',
  'c1b1', 'd7e7', 'b1c1', 'e7d7',
];

void main() {
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeAnalysisRepository analysis;
  late FakeShareRepository share;
  late ConclusionCubit cubit;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 9, 12));
    progress = FakeProgressRepository();
    analysis = FakeAnalysisRepository();
    share = FakeShareRepository();
  });

  // Deixa a engine falsa e as animações terminarem.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Grava a partida, monta a tela e espera ela abrir.
  Future<void> open(
    WidgetTester tester, {
    AttemptOutcome outcome = AttemptOutcome.win,
    List<String> moves = const ['c1g5'],
    Duration played = const Duration(seconds: 20),
    bool disableAnimations = false,
  }) async {
    final rating = FakeRatingRepository();
    final achievements = FakeAchievementsRepository();
    final speedruns = FakeSpeedrunRepository(progress);
    await tester.runAsync(() async {
      final game = Attempt(
        positionId: samplePositions[0].id,
        playedAt: now(),
        startedAt: now().subtract(played),
        outcome: outcome,
        fulfilled: outcome == AttemptOutcome.win,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        startFen: samplePositions[0].fen,
        userSide: Side.white,
        endReason: switch (outcome) {
          AttemptOutcome.win => GameEndReason.checkmate,
          AttemptOutcome.loss => GameEndReason.resign,
          AttemptOutcome.draw => GameEndReason.stalemate,
        },
        moves: moves,
      );
      final id = await progress.addAttempt(game);
      await GameReporter(
        rating: rating,
        achievements: achievements,
        journey: FakeJourneyRepository(),
        progress: progress,
        speedruns: speedruns,
        positions: FakePositionsRepository(),
        now: now,
      ).report(game, gameId: id, userSide: Side.white, drawGoal: false);
      cubit = ConclusionCubit(
        progress: progress,
        rating: rating,
        achievements: achievements,
        journey: FakeJourneyRepository(),
        speedruns: speedruns,
        positions: FakePositionsRepository(),
        characters: FakeCharacterRepository(),
        now: now,
        analysis: analysis,
        reviews: FakeGameReviewRepository(),
      );
      await cubit.load(id, 'en');
    });
    addTearDown(cubit.close);
    const size = Size(412, 2400);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await tester.runAsync(settings.load);
    await tester.pumpWidget(
      TestApp(
        shareRepository: share,
        settingsCubit: settings,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
          ),
          child: BlocProvider.value(
            value: cubit,
            child: const ConclusionScreen(),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  /// Compartilha e devolve a altura da imagem (no cabeçalho do PNG).
  Future<int> sharedHeight(WidgetTester tester) async {
    share.shared.clear();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(ConclusionKeys.share));
      for (var i = 0; i < 40 && share.shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    final png = share.shared.single.png;
    return ByteData.sublistView(png, 20, 24).getUint32(0);
  }

  group('análise rápida', () {
    testWidgets('partida curta: começa sozinha, no fim da tela, andando', (
      tester,
    ) async {
      analysis.hold = Completer<void>();
      await open(tester);

      expect(cubit.state.reviewing, isTrue);
      expect(find.byKey(ConclusionKeys.reviewBoard), findsOneWidget);
      // No fim: depois dos atalhos de histórico.
      final links = tester.getTopLeft(
        find.byKey(ConclusionKeys.action(ConclusionAction.analyze)),
      );
      final quick = tester.getTopLeft(find.byKey(ConclusionKeys.quickReview));
      expect(quick.dy, greaterThan(links.dy));

      analysis.hold!.complete();
      analysis.hold = null;
      await settle(tester);
      expect(find.byKey(ConclusionKeys.review), findsOneWidget);
    });

    testWidgets('partida longa: só no toque, logo abaixo do cartão', (
      tester,
    ) async {
      await open(tester, moves: _longMoves, played: const Duration(minutes: 5));

      expect(cubit.state.reviewing, isFalse);
      expect(analysis.requests, isEmpty);
      expect(find.byKey(ConclusionKeys.reviewBoard), findsNothing);
      expect(find.byKey(ConclusionKeys.review), findsNothing);
      final links = tester.getTopLeft(
        find.byKey(ConclusionKeys.action(ConclusionAction.analyze)),
      );
      final quick = tester.getTopLeft(find.byKey(ConclusionKeys.quickReview));
      expect(quick.dy, lessThan(links.dy));

      await tester.tap(find.byKey(ConclusionKeys.quickReview));
      await settle(tester);
      expect(find.byKey(ConclusionKeys.review), findsOneWidget);
    });

    testWidgets('compartilhar com a análise rodando: a imagem sai sem ela; '
        'pronta, ela entra', (tester) async {
      analysis.hold = Completer<void>();
      await open(tester);
      expect(cubit.state.reviewing, isTrue);
      final running = await sharedHeight(tester);
      // A imagem é só o cartão: a análise (com o tabuleiro) ficou de fora.
      final card = tester.getSize(find.byKey(ConclusionKeys.quickReview));
      expect(card.height, greaterThan(100));

      analysis.hold!.complete();
      analysis.hold = null;
      await settle(tester);
      expect(cubit.state.review, isNotNull);
      final done = await sharedHeight(tester);
      expect(done, greaterThan(running));
    });
  });

  group('brilho de quem venceu', () {
    Finder glowIn(Key player) => find.descendant(
      of: find.byKey(player),
      matching: find.byKey(ConclusionKeys.winnerGlow),
    );

    testWidgets('vitória: só no jogador', (tester) async {
      await open(tester, moves: _longMoves, played: const Duration(minutes: 5));
      expect(glowIn(ConclusionKeys.player), findsOneWidget);
      expect(glowIn(ConclusionKeys.opponent), findsNothing);
    });

    testWidgets('derrota: só no adversário', (tester) async {
      await open(
        tester,
        outcome: AttemptOutcome.loss,
        moves: _longMoves,
        played: const Duration(minutes: 5),
      );
      expect(glowIn(ConclusionKeys.player), findsNothing);
      expect(glowIn(ConclusionKeys.opponent), findsOneWidget);
    });

    testWidgets('empate: em nenhum', (tester) async {
      await open(
        tester,
        outcome: AttemptOutcome.draw,
        moves: _longMoves,
        played: const Duration(minutes: 5),
      );
      expect(find.byKey(ConclusionKeys.winnerGlow), findsNothing);
    });

    testWidgets('sem animações: nenhum', (tester) async {
      await open(
        tester,
        moves: _longMoves,
        played: const Duration(minutes: 5),
        disableAnimations: true,
      );
      expect(find.byKey(ConclusionKeys.winnerGlow), findsNothing);
    });
  });
}
