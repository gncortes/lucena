import 'dart:io' as io;
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository_device.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository_maia.dart';
import 'package:lucena/data/services/maia_service.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/think_time_policy.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_opponent_repository.dart';
import '../../../../testing/fakes/fake_pace_repository.dart';

void main() {
  late MaiaService service;
  late FakeNow now;
  late List<Duration> waits;

  setUp(() {
    service = MaiaService(
      () => io.File('assets/models/maia3-5m.bin').readAsBytes(),
    );
    addTearDown(service.dispose);
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    waits = [];
  });

  MaiaOpponentRepository maia({int seed = 1}) => MaiaOpponentRepository(
    service,
    now: now,
    random: Random(seed),
    wait: (duration) async => waits.add(duration),
  );

  const budget = Duration(seconds: 2);

  test('o Maia responde lances legais em vários níveis', () async {
    final position = GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 b - - 0 1')!;
    for (final level in [1000, 1400, 2600]) {
      final move = await maia().pickMove(
        position,
        thinkTime: budget,
        kind: OpponentKind.maia,
        level: level,
      );

      expect(move, isNotNull);
      expect(position.isLegal(move!), isTrue);
    }
  });

  test('sorteios diferentes dão lances diferentes na mesma posição', () async {
    final moves = <String>{};
    for (var seed = 0; seed < 12; seed++) {
      final move = await maia(seed: seed).pickMove(
        GameRules.initial,
        thinkTime: budget,
        kind: OpponentKind.maia,
        level: 1000,
      );
      moves.add(move!.uci);
    }

    expect(moves.length, greaterThan(1));
  });

  test('recaptura óbvia sai quase na hora', () async {
    // As brancas acabaram de tomar em d5: retomar com o peão é o lance.
    final position = GameRules.fromFen(
      'rnbqkb1r/ppp1pppp/8/3N4/8/8/PPPP1PPP/R1BQKBNR b KQkq - 0 3',
    )!;

    final move = await maia().pickMove(
      position,
      thinkTime: budget,
      kind: OpponentKind.maia,
      level: 1800,
    );

    expect(move!.uci, 'd8d5');
    expect(waits.single, lessThan(const Duration(milliseconds: 400)));
  });

  test('posição com dúvida leva mais tempo que a recaptura', () async {
    await maia().pickMove(
      GameRules.fromFen(
        'r2q1rk1/pp2bppp/2n1bn2/3p4/3P4/2NBBN2/PP3PPP/R2Q1RK1 w - - 4 11',
      )!,
      thinkTime: budget,
      kind: OpponentKind.maia,
      level: 1800,
    );

    expect(waits.single, greaterThan(ThinkTimePolicy.instant * 1.3));
    expect(waits.single, lessThanOrEqualTo(budget));
  });

  test('o tempo já gasto na conta sai da espera', () async {
    final repository = MaiaOpponentRepository(
      service,
      now: now,
      random: Random(1),
      wait: (duration) async => waits.add(duration),
    );
    // O relógio anda 5 s durante a conta: não sobra nada para esperar.
    final pending = repository.pickMove(
      GameRules.initial,
      thinkTime: budget,
      kind: OpponentKind.maia,
      level: 1400,
    );
    now.advance(const Duration(seconds: 5));

    expect(await pending, isNotNull);
    expect(waits, isEmpty);
  });

  test('posição sem lances não tem resposta', () async {
    final move = await maia().pickMove(
      GameRules.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1')!,
      thinkTime: budget,
      kind: OpponentKind.maia,
      level: 1400,
    );

    expect(move, isNull);
    expect(waits, isEmpty);
  });

  test('cada pedido vai para o motor escolhido', () async {
    final maiaFake = FakeOpponentRepository();
    final stockfishFake = FakeOpponentRepository();
    final OpponentRepository device = DeviceOpponentRepository(
      maia: maiaFake,
      stockfish: stockfishFake,
    );
    final history = <Position>[GameRules.initial];

    await device.pickMove(
      GameRules.initial,
      thinkTime: budget,
      kind: OpponentKind.maia,
      level: 1600,
      history: history,
    );
    await device.pickMove(GameRules.initial, thinkTime: budget);

    expect(maiaFake.levels, [1600]);
    expect(maiaFake.histories.single, same(history));
    expect(stockfishFake.kinds, [OpponentKind.stockfish]);
  });

  test(
    'no bullet o Maia pensa menos, sem deixar de jogar lance legal',
    () async {
      final position = GameRules.fromFen('8/8/8/4k3/8/8/2PK4/8 w - - 0 1')!;
      Future<Duration> thinking(TimeControl time) async {
        waits.clear();
        final paced = MaiaOpponentRepository(
          service,
          now: now,
          pace: FakePaceRepository(),
          random: Random(5),
          wait: (duration) async => waits.add(duration),
        );
        for (var move = 0; move < 6; move++) {
          final picked = await paced.pickMove(
            position,
            thinkTime: budget,
            kind: OpponentKind.maia,
            level: 1400,
            time: time,
          );
          expect(position.isLegal(picked!), isTrue);
        }
        return waits.fold<Duration>(Duration.zero, (sum, wait) => sum + wait);
      }

      final bullet = await thinking(
        const TimeControl(initial: Duration(minutes: 1)),
      );
      final rapid = await thinking(
        const TimeControl(initial: Duration(minutes: 10)),
      );
      expect(bullet, lessThan(rapid));
    },
  );
}
