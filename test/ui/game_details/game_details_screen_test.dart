import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';
import 'package:lucena/ui/game_details/widgets/game_details_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeRatingRepository rating;

  setUp(() {
    progress = FakeProgressRepository();
    rating = FakeRatingRepository();
  });

  // Mate do pastor: as brancas ganham em 7 lances.
  final game = Attempt(
    positionId: 'basic.queen.0001',
    playedAt: DateTime.utc(2026, 10, 5, 12),
    outcome: AttemptOutcome.win,
    fulfilled: true,
    opponent: OpponentKind.maia,
    opponentLevel: 1000,
    startFen: GameRules.initial.fen,
    moves: const ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'],
    moveTimes: const [
      Duration(seconds: 2),
      Duration(milliseconds: 3400),
      Duration(seconds: 1),
      Duration(seconds: 1),
      Duration(seconds: 65),
      Duration(seconds: 4),
      Duration(milliseconds: 500),
    ],
    userSide: Side.white,
    endReason: GameEndReason.checkmate,
    userTime: const TimeControl(initial: Duration(minutes: 5)),
  );

  Future<GameDetailsCubit> pump(WidgetTester tester, int id) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      rating: rating,
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    // O tabuleiro lê as peças e as cores das preferências.
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const GameDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  String boardFen(WidgetTester tester) =>
      tester.widget<PositionBoard>(find.byKey(GameDetailsKeys.board)).fen;

  String plain(WidgetTester tester, Key key) {
    final text = tester.widget<Text>(find.byKey(key));
    return text.data ?? text.textSpan!.toPlainText();
  }

  testWidgets('o cabeçalho diz contra quem, o resultado e o rating', (
    tester,
  ) async {
    final id = await progress.addAttempt(game);
    await rating.rate(game, userSide: Side.white, drawGoal: false, gameId: id);
    await pump(tester, id);

    expect(find.byKey(GameDetailsKeys.screen), findsOneWidget);
    expect(plain(tester, GameDetailsKeys.opponent), 'Coco (1000)');
    expect(plain(tester, GameDetailsKeys.result), 'Win · Checkmate');
    final after = (await rating.history()).single.rating.rounded;
    expect(find.text('$after'), findsOneWidget);
  });

  testWidgets('a tabela traz cada lance com o tempo que levou', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id);

    for (var index = 0; index < game.moves.length; index++) {
      expect(find.byKey(GameDetailsKeys.move(index)), findsOneWidget);
    }
    expect(plain(tester, GameDetailsKeys.moveTime(0)), '2.0 s');
    expect(plain(tester, GameDetailsKeys.moveTime(1)), '3.4 s');
    // Acima de um minuto, em minutos e segundos.
    expect(plain(tester, GameDetailsKeys.moveTime(4)), '1:05');
    // Numeração das jogadas: 4 linhas para 7 lances.
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('4.'), findsOneWidget);
    expect(find.text('5.'), findsNothing);
  });

  testWidgets('tocar num lance mostra a posição depois dele', (tester) async {
    final id = await progress.addAttempt(game);
    final cubit = await pump(tester, id);
    // Abre no último lance: o mate.
    expect(boardFen(tester), cubit.state.moves.last.position.fen);

    await tester.tap(find.byKey(GameDetailsKeys.move(0)));
    await tester.pumpAndSettle();

    expect(cubit.state.shownIndex, 0);
    expect(boardFen(tester), cubit.state.moves.first.position.fen);
    expect(
      Position.setupPosition(
        Rule.chess,
        Setup.parseFen(boardFen(tester)),
      ).board.pieceAt(Square.e4),
      Piece.whitePawn,
    );
  });

  testWidgets('partida que não existe mais: o aviso', (tester) async {
    await pump(tester, 99);

    expect(find.byKey(GameDetailsKeys.notFound), findsOneWidget);
    expect(find.byKey(GameDetailsKeys.board), findsNothing);
  });
}
