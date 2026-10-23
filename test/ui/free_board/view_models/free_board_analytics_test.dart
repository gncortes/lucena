import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';

import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_draw_offer_repository.dart';
import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_opponent_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';

void main() {
  late FakeNow now;
  late FakeOngoingGameRepository games;
  late FakeAnalyticsRepository analytics;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    games = FakeOngoingGameRepository();
    analytics = FakeAnalyticsRepository();
  });

  FreeBoardCubit build({
    Position? start = GameRules.initial,
    GameMode mode = const GameMode(),
  }) => FreeBoardCubit(
    now: now,
    haptics: FakeHapticsRepository(),
    settings: FakeSettingsRepository(),
    games: games,
    opponent: FakeOpponentRepository(now: now),
    progress: FakeProgressRepository(),
    draws: FakeDrawOfferRepository(),
    analytics: analytics,
    start: start,
    mode: mode,
  );

  void play(FreeBoardCubit cubit, List<String> ucis) {
    for (final uci in ucis) {
      cubit.play(NormalMove.fromUci(uci));
      now.advance(const Duration(seconds: 3));
    }
  }

  test('tabuleiro livre: começo, primeiro lance e fim, uma vez cada', () async {
    final cubit = build();
    await cubit.open();
    now.advance(const Duration(seconds: 5));
    play(cubit, ['f2f3', 'e7e5', 'g2g4', 'd8h4']);
    await cubit.saved();

    final started = analytics.eventsNamed('partida_iniciada').single.params;
    expect(started, containsPair('modo', 'livre'));
    expect(started, containsPair('lado', 'ambos'));
    expect(started, containsPair('adversario', 'dois_jogadores'));
    // A posição vai como id, nunca como FEN.
    expect(started['posicao_id'], startsWith('custom_'));
    expect(started.values, isNot(contains(GameRules.initial.fen)));

    final first = analytics.eventsNamed('partida_primeiro_lance').single;
    expect(first.params, containsPair('tempo_s', 5));

    final end = analytics.eventsNamed('partida_fim').single.params;
    expect(end, containsPair('motivo', 'mate'));
    expect(end, containsPair('lances', 4));
    await cubit.close();
  });

  test('nova partida conta o começo de novo', () async {
    final cubit = build();
    await cubit.open();
    play(cubit, ['e2e4']);
    cubit.newGame();
    play(cubit, ['d2d4']);
    await cubit.saved();
    expect(analytics.eventsNamed('partida_iniciada'), hasLength(2));
    expect(analytics.eventsNamed('partida_primeiro_lance'), hasLength(2));
    await cubit.close();
  });

  test('a partida que volta não conta o começo', () async {
    final first = build();
    await first.open();
    play(first, ['e2e4']);
    await first.leave();
    await first.close();
    analytics.events.clear();

    final again = build(start: null);
    await again.open();
    play(again, ['e7e5']);
    await again.saved();
    expect(analytics.eventsNamed('partida_iniciada'), isEmpty);
    expect(analytics.eventsNamed('partida_primeiro_lance'), isEmpty);
    await again.close();
  });

  test('treino do catálogo contra o Maia: desistir é derrota', () async {
    final cubit = build(
      start: GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1'),
      mode: const GameMode(
        opponent: OpponentKind.maia,
        level: 1100,
        userSide: Side.white,
        goal: PositionGoal.win,
        positionId: 'kq_k_1',
      ),
    );
    await cubit.open();
    cubit.resign();
    await cubit.saved();

    final started = analytics.eventsNamed('partida_iniciada').single.params;
    expect(started, containsPair('modo', 'catalogo'));
    expect(started, containsPair('posicao_id', 'kq_k_1'));
    expect(started, containsPair('meta', 'win'));
    expect(started, containsPair('lado', 'brancas'));
    expect(started, containsPair('nivel', 1100));

    final end = analytics.eventsNamed('partida_fim').single.params;
    expect(end, containsPair('resultado', 'derrota'));
    expect(end, containsPair('lances', 0));
    await cubit.close();
  });
}
