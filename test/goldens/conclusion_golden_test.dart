import 'package:dartchess/dartchess.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/conclusion/widgets/conclusion_screen.dart';
import 'package:lucena/ui/free_board/view_models/game_reporter.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../testing/fakes/fake_achievements_repository.dart';
import '../../testing/fakes/fake_share_repository.dart';
import '../../testing/fakes/fake_analysis_repository.dart';
import '../../testing/fakes/fake_game_review_repository.dart';
import '../../testing/fakes/fake_journey_repository.dart';
import '../../testing/fakes/fake_now.dart';
import '../../testing/fakes/fake_positions_repository.dart';
import '../../testing/fakes/fake_progress_repository.dart';
import '../../testing/fakes/fake_rating_repository.dart';
import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/fakes/fake_speedrun_repository.dart';
import '../../testing/goldens/golden_harness.dart';
import '../../testing/test_app.dart';

/// Uma partida jogada e gravada como no tabuleiro.
typedef _Play = Future<int> Function({
  required AttemptOutcome outcome,
  GameEndReason reason,
  String? challengeId,
  int? attemptId,
  int? stage,
  int level,
  Duration clock,
  List<String> moves,
});

/// As conclusões de cada contexto (T51, frente B), com os personagens e as
/// falas de verdade: a tela inteira, para conferir o desenho.
void main() {
  final pace = SpeedrunPaces.all.first;
  final speedrunId = SpeedrunPaces.idFor(sampleSpeedruns[0].id, pace);
  final stages = SpeedrunPaces.withTime(sampleSpeedruns[0], pace).stages;

  final scenarios =
      <String, Future<int> Function(_Play, FakeSpeedrunRepository, FakeNow)>{
        'journey_won': (play, _, _) async {
          return play(
            outcome: AttemptOutcome.win,
            challengeId: sampleLadder[0].challenges[0].id,
            moves: const ['c1g5', 'd7e6', 'c2d3', 'e6d6', 'g5f5', 'd6c6'],
          );
        },
        'journey_reviewed': (play, _, _) => play(
          outcome: AttemptOutcome.win,
          challengeId: sampleLadder[0].challenges[0].id,
          moves: const ['c1g5', 'd7e6', 'c2d3', 'e6d6', 'g5f5', 'd6c6'],
        ),
        'game_lost': (play, _, _) =>
            play(outcome: AttemptOutcome.loss, reason: GameEndReason.timeout),
        'game_draw': (play, _, _) => play(
          outcome: AttemptOutcome.draw,
          reason: GameEndReason.stalemate,
          level: 1600,
        ),
        'speedrun_stage': (play, speedruns, now) async {
          final attempt = await speedruns.start(speedrunId, now());
          return play(
            outcome: AttemptOutcome.win,
            attemptId: attempt.id,
            stage: 0,
            clock: const Duration(seconds: 38),
          );
        },
        'speedrun_end': (play, speedruns, now) async {
          final attempt = await speedruns.start(speedrunId, now());
          await play(
            outcome: AttemptOutcome.win,
            attemptId: attempt.id,
            stage: 0,
            clock: const Duration(seconds: 38),
          );
          return play(
            outcome: AttemptOutcome.win,
            attemptId: attempt.id,
            stage: 1,
            clock: const Duration(seconds: 71),
          );
        },
        'speedrun_lost': (play, speedruns, now) async {
          final attempt = await speedruns.start(speedrunId, now());
          await play(
            outcome: AttemptOutcome.win,
            attemptId: attempt.id,
            stage: 0,
          );
          return play(
            outcome: AttemptOutcome.loss,
            reason: GameEndReason.resign,
            attemptId: attempt.id,
            stage: 1,
          );
        },
      };

  for (final MapEntry(key: name, value: scenario) in scenarios.entries) {
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('conclusion · $name · ${theme.name}', (tester) async {
        await Goldens.loadFonts();
        final now = FakeNow(DateTime.utc(2026, 10, 8, 12));
        final progress = FakeProgressRepository();
        final achievements = FakeAchievementsRepository();
        final rating = FakeRatingRepository();
        final speedruns = FakeSpeedrunRepository(progress);
        final characters = AssetCharacterRepository(const AssetService());
        final reporter = GameReporter(
          rating: rating,
          achievements: achievements,
          journey: FakeJourneyRepository(),
          progress: progress,
          speedruns: speedruns,
          positions: FakePositionsRepository(),
          now: now,
        );
        Future<int> play({
          required AttemptOutcome outcome,
          GameEndReason reason = GameEndReason.checkmate,
          String? challengeId,
          int? attemptId,
          int? stage,
          int level = 1000,
          Duration clock = const Duration(seconds: 54),
          List<String> moves = const [],
        }) async {
          final position = stage == null
              ? samplePositions[0]
              : stages[stage].position;
          final game = Attempt(
            positionId: position.id,
            playedAt: now(),
            outcome: outcome,
            fulfilled: outcome == AttemptOutcome.win,
            opponent: OpponentKind.maia,
            opponentLevel: level,
            startFen: position.fen,
            userSide: Side.white,
            endReason: reason,
            userClock: clock,
            challengeId: challengeId,
            speedrunAttemptId: attemptId,
            speedrunStage: stage,
            moves: moves,
          );
          final id = await progress.addAttempt(game);
          await reporter.report(
            game,
            gameId: id,
            userSide: Side.white,
            drawGoal: false,
          );
          return id;
        }

        late int id;
        await tester.runAsync(() async {
          id = await scenario(play, speedruns, now);
        });
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        addTearDown(settings.close);
        await tester.runAsync(settings.load);
        final cubit = ConclusionCubit(
          progress: progress,
          rating: rating,
          achievements: achievements,
          journey: FakeJourneyRepository(),
          speedruns: speedruns,
          positions: FakePositionsRepository(),
          characters: characters,
          now: now,
          analysis: FakeAnalysisRepository(),
          reviews: FakeGameReviewRepository(),
        );
        addTearDown(cubit.close);
        await tester.runAsync(() async {
          await cubit.load(id, 'pt');
          // A análise rápida, tocada.
          if (name == 'journey_reviewed') await cubit.quickReview();
          // O resumo da revisão e a melhor linha, em segundo plano.
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        const size = Size(412, 1500);
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = size;
        addTearDown(tester.view.reset);
        // Os retratos lidos de verdade antes da tela.
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          final context = tester.element(find.byType(SizedBox));
          for (final character in await characters.characters()) {
            await precacheImage(AssetImage(character.imageFor(null)), context);
            for (final image in character.images.values) {
              await precacheImage(AssetImage(image), context);
            }
          }
        });
        final share = FakeShareRepository();
        await tester.pumpWidget(
          TestApp(
            shareRepository: share,
            locale: const Locale('pt'),
            themeMode: theme,
            settingsCubit: settings,
            child: MediaQuery(
              data: const MediaQueryData(size: size, disableAnimations: true),
              child: BlocProvider.value(
                value: cubit,
                child: const ConclusionScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
        }
        // No fim do speedrun, a estatística detalhada aberta.
        if (name == 'speedrun_end') {
          await tester.tap(find.byKey(ConclusionKeys.runDetails));
          await tester.pumpAndSettle();
        }
        await expectLater(
          find.byType(ConclusionScreen),
          matchesGoldenFile('goldens/conclusion/${name}_${theme.name}.png'),
        );
        // Compartilhar com a tela rolada até o fim dá a mesma imagem que
        // do topo: o cartão e a análise ficam montados mesmo longe da vista.
        if (name == 'journey_reviewed' && theme == ThemeMode.light) {
          Future<Uint8List> shared() async {
            share.shared.clear();
            await tester.runAsync(() async {
              await tester.tap(find.byKey(ConclusionKeys.share));
              for (var i = 0; i < 40 && share.shared.isEmpty; i++) {
                await Future<void>.delayed(const Duration(milliseconds: 50));
              }
            });
            return share.shared.single.png;
          }

          // A altura da imagem, no cabeçalho do PNG.
          int heightOf(Uint8List png) =>
              ByteData.sublistView(png, 20, 24).getUint32(0);
          final fromTop = heightOf(await shared());
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          expect(heightOf(await shared()), fromTop);
        }
      });
    }
  }
}
