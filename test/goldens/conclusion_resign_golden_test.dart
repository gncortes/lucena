import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/conclusion/widgets/conclusion_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../testing/fakes/fake_achievements_repository.dart';
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

/// P9 B (canvas `SugAchadoP9`, coluna B): a conclusão de uma partida perdida
/// por desistência contra o Percival, em 411x914.
void main() {
  // O final com aula liberada que o canvas mostra ("Treinar este final").
  const position = EndgamePosition(
    id: 'queen.queenVsRook.0001',
    category: 'queen',
    subcategory: 'queenVsRook',
    fen: '8/8/3k4/8/8/4K3/r7/6Q1 w - - 0 1',
    goal: PositionGoal.win,
    verified: true,
  );

  testWidgets('conclusão · desistência · claro', (tester) async {
    await Goldens.loadFonts();
    final now = FakeNow(DateTime.utc(2026, 11, 6, 12));
    final progress = FakeProgressRepository();
    final characters = AssetCharacterRepository(const AssetService());
    final positions = FakePositionsRepository(const [position]);
    late ConclusionCubit cubit;
    await tester.runAsync(() async {
      final id = await progress.addAttempt(
        Attempt(
          positionId: position.id,
          playedAt: now(),
          outcome: AttemptOutcome.loss,
          fulfilled: false,
          opponent: OpponentKind.maia,
          opponentLevel: 1400,
          startFen: position.fen,
          userSide: Side.white,
          endReason: GameEndReason.resign,
          moves: const ['g1g5', 'a2a3', 'g5f5', 'a3a4'],
        ),
      );
      cubit = ConclusionCubit(
        progress: progress,
        rating: FakeRatingRepository(),
        achievements: FakeAchievementsRepository(),
        journey: FakeJourneyRepository(),
        speedruns: FakeSpeedrunRepository(progress),
        positions: positions,
        characters: characters,
        now: now,
        analysis: FakeAnalysisRepository(),
        reviews: FakeGameReviewRepository(),
      );
      await cubit.load(id, 'pt');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    addTearDown(cubit.close);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await tester.runAsync(settings.load);
    const size = Size(411, 914);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
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
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
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
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Treinar este final'), findsOneWidget);
    await expectLater(
      find.byType(ConclusionScreen),
      matchesGoldenFile('goldens/conclusion/resign_light.png'),
    );
  });
}
