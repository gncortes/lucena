import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository_local.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  // Cada chamada cria repositório e serviço novos, como ao reabrir o app.
  LocalOngoingGameRepository reopen() =>
      LocalOngoingGameRepository(PreferencesService());

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  const startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  test('sem nada gravado, não há partida em andamento', () async {
    expect(await reopen().load(), isNull);
  });

  test('a partida sem relógio volta igual ao reabrir', () async {
    const snapshot = GameSnapshot(
      startFen: startFen,
      moves: ['e2e4', 'e7e5', 'g1f3'],
      orientation: Side.black,
    );
    await reopen().save(snapshot);

    expect(await reopen().load(), snapshot);
  });

  test(
    'o relógio volta com os tempos e o instante em que a vez começou',
    () async {
      final snapshot = GameSnapshot(
        startFen: startFen,
        moves: const ['e2e4'],
        playerSide: Side.white,
        onScreen: false,
        clock: ClockState(
          config: const ClockConfig(
            white: TimeControl(
              initial: Duration(minutes: 3),
              increment: Duration(seconds: 2),
            ),
            black: TimeControl(initial: Duration(minutes: 1)),
          ),
          white: const Duration(minutes: 2, seconds: 58, milliseconds: 400),
          black: const Duration(minutes: 1),
          running: Side.black,
          turnStartedAt: DateTime.utc(2026, 1, 1, 12, 0, 3, 600),
        ),
      );
      await reopen().save(snapshot);

      expect(await reopen().load(), snapshot);
    },
  );

  test('relógio parado volta parado', () async {
    const snapshot = GameSnapshot(
      startFen: startFen,
      clock: ClockState(
        config: ClockConfig(
          white: TimeControl(initial: Duration(minutes: 5)),
          black: TimeControl(initial: Duration(minutes: 5)),
        ),
        white: Duration(minutes: 4),
        black: Duration(minutes: 5),
      ),
    );
    await reopen().save(snapshot);

    expect(await reopen().load(), snapshot);
  });

  test('gravar de novo substitui a partida anterior', () async {
    await reopen().save(const GameSnapshot(startFen: startFen));
    const later = GameSnapshot(startFen: startFen, moves: ['d2d4']);
    await reopen().save(later);

    expect(await reopen().load(), later);
  });

  test('apagar esquece a partida', () async {
    await reopen().save(const GameSnapshot(startFen: startFen));
    await reopen().clear();

    expect(await reopen().load(), isNull);
  });

  test('gravação ilegível é descartada', () async {
    await PreferencesService().setString('game.ongoing', '{"startFen": 12');

    expect(await reopen().load(), isNull);
    expect(await PreferencesService().getString('game.ongoing'), isNull);
  });

  test('gravação com campos faltando é descartada', () async {
    await PreferencesService().setString('game.ongoing', '{"moves": []}');

    expect(await reopen().load(), isNull);
  });
}
