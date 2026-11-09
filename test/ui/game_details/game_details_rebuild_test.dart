import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';
import 'package:lucena/ui/game_details/widgets/game_details_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// Deixa o teste emitir um estado como a revisão faz a cada tique.
class _TickCubit extends GameDetailsCubit {
  _TickCubit(
    super.gameId, {
    required super.progress,
    super.rating,
    super.characters,
    super.reviews,
  });

  void tick(GameDetailsState next) => emit(next);
}

void main() {
  testWidgets('um tique da revisão não reconstrói o tabuleiro', (tester) async {
    final progress = FakeProgressRepository();
    final id = await progress.addAttempt(
      Attempt(
        positionId: 'basic.queen.0001',
        playedAt: DateTime.utc(2026, 10, 5, 12),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        startFen: GameRules.initial.fen,
        moves: const ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'],
        userSide: Side.white,
        endReason: GameEndReason.checkmate,
      ),
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final cubit = _TickCubit(
      id,
      reviews: FakeGameReviewRepository(),
      progress: progress,
      rating: FakeRatingRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider<GameDetailsCubit>.value(
          value: cubit,
          child: const GameDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = tester.widget<Chessboard>(find.byKey(GameDetailsKeys.board));
    cubit.tick(
      cubit.state.copyWith(
        reviewProgress: 0.5,
        annotating: {2},
        engineDepths: {2: 10},
      ),
    );
    await tester.pumpAndSettle();
    final after = tester.widget<Chessboard>(find.byKey(GameDetailsKeys.board));

    expect(identical(before, after), isTrue);
    cubit.tick(cubit.state.copyWith(selected: 0));
    await tester.pumpAndSettle();
    expect(
      identical(
        before,
        tester.widget<Chessboard>(find.byKey(GameDetailsKeys.board)),
      ),
      isFalse,
    );
  });
}
