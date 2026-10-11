import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/achievement.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';
import 'package:lucena/ui/profile/widgets/rating_screen.dart';

import '../../testing/fakes/fake_achievements_repository.dart';
import '../../testing/fakes/fake_now.dart';
import '../../testing/fakes/fake_progress_repository.dart';
import '../../testing/fakes/fake_rating_repository.dart';
import '../../testing/goldens/golden_harness.dart';
import '../../testing/test_app.dart';

void main() {
  // A tela inteira com um mês de partidas: vitórias, empates e derrotas
  // contra níveis diferentes.
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('rating_screen · ${theme.name}', (tester) async {
      await Goldens.loadFonts();
      final progress = FakeProgressRepository();
      final rating = FakeRatingRepository();
      final now = FakeNow(DateTime.utc(2026, 10, 8, 13));
      const outcomes = [
        AttemptOutcome.win,
        AttemptOutcome.loss,
        AttemptOutcome.win,
        AttemptOutcome.win,
        AttemptOutcome.draw,
        AttemptOutcome.win,
        AttemptOutcome.loss,
        AttemptOutcome.win,
        AttemptOutcome.win,
        AttemptOutcome.draw,
        AttemptOutcome.win,
        AttemptOutcome.loss,
        AttemptOutcome.win,
        AttemptOutcome.win,
        AttemptOutcome.win,
      ];
      await tester.runAsync(() async {
        for (final (index, outcome) in outcomes.indexed) {
          final game = Attempt(
            positionId: 'basic.queen.0001',
            playedAt: DateTime.utc(
              2026,
              9,
              10,
              12,
            ).add(Duration(days: index * 2)),
            outcome: outcome,
            fulfilled: outcome == AttemptOutcome.win,
            opponent: OpponentKind.maia,
            opponentLevel: 1000 + 200 * (index ~/ 3),
          );
          final id = await progress.addAttempt(game);
          await rating.rate(
            game,
            userSide: Side.white,
            drawGoal: false,
            gameId: id,
          );
        }
      });
      // Os personagens de verdade, com os retratos.
      final characters = AssetCharacterRepository(const AssetService());
      // O catálogo de conquistas, com duas já ganhas.
      final catalog = jsonDecode(
        io.File('assets/achievements.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final achievements = FakeAchievementsRepository([
        for (final entry
            in (catalog['achievements'] as List).cast<Map<String, dynamic>>())
          ?Achievement.fromJson(entry),
      ]);
      await achievements.unlock([
        UnlockedAchievement(id: 'first-fulfilled', at: now()),
        UnlockedAchievement(id: 'beat-1000', at: now()),
      ]);
      const size = Size(412, 1500);
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);
      // Os retratos lidos de verdade antes da tela, para o golden mostrá-los.
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        final context = tester.element(find.byType(SizedBox));
        for (final character in await characters.characters()) {
          await precacheImage(AssetImage(character.imageFor(null)), context);
        }
      });
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          themeMode: theme,
          child: MediaQuery(
            data: const MediaQueryData(size: size, disableAnimations: true),
            child: BlocProvider(
              create: (_) => RatingCubit(
                rating,
                progress: progress,
                now: now,
                characters: characters,
                achievements: achievements,
              )..load(),
              child: const RatingScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Os retratos decodificam fora do relógio falso do teste.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(RatingScreen),
        matchesGoldenFile('goldens/rating_screen/${theme.name}.png'),
      );
    });
  }
}
