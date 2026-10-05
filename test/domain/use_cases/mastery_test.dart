import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/domain/use_cases/mastery.dart';

import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  final ladder = sampleLadder;
  final queen = ladder[0].challenges[0].id;
  final rook = ladder[0].challenges[1].id;
  final rung1200 = ladder[1].challenges.single.id;

  test('sem partidas: o primeiro degrau aberto, o resto trancado', () {
    final progress = Mastery.of(ladder, {});

    expect(progress.rungs.map((r) => r.status), [
      RungStatus.open,
      RungStatus.locked,
      RungStatus.locked,
    ]);
    expect(progress.current!.rung.id, '1000');
    expect(progress.next!.rung.id, '1200');
    expect(progress.rungs.first.remaining, 2);
  });

  test('concluir um desafio só não libera o degrau seguinte', () {
    final progress = Mastery.of(ladder, {queen});

    expect(progress.rungs[0].completed, {queen});
    expect(progress.rungs[0].status, RungStatus.open);
    expect(progress.rungs[1].status, RungStatus.locked);
    expect(progress.before('1200')!.remaining, 1);
  });

  test('concluir todos os desafios do degrau libera o seguinte', () {
    final progress = Mastery.of(ladder, {queen, rook});

    expect(progress.rungs[0].status, RungStatus.completed);
    expect(progress.rungs[1].status, RungStatus.open);
    expect(progress.current!.rung.id, '1200');
    expect(progress.next!.rung.id, 'stockfish');
  });

  test('desafio de degrau trancado não libera nada adiante', () {
    // O 1200 concluído (partida de outra versão), mas o 1000 não.
    final progress = Mastery.of(ladder, {rung1200});

    expect(progress.rungs[1].status, RungStatus.locked);
    expect(progress.rungs[2].status, RungStatus.locked);
  });

  test('tudo concluído: Jornada terminada, sem degrau atual', () {
    final all = {
      for (final rung in ladder)
        for (final challenge in rung.challenges) challenge.id,
    };
    final progress = Mastery.of(ladder, all);

    expect(progress.current, isNull);
    expect(progress.next, isNull);
  });

  group('adversário do desafio', () {
    test('lê o Maia com nível e o Stockfish', () {
      expect(
        OpponentRef.tryParse('maia:1200'),
        const OpponentRef(kind: OpponentKind.maia, level: 1200),
      );
      expect(
        OpponentRef.tryParse('stockfish'),
        const OpponentRef(kind: OpponentKind.stockfish),
      );
      expect(OpponentRef.tryParse('twoPlayers'), isNull);
      expect(OpponentRef.tryParse('maia'), isNull);
    });

    test('o código volta igual', () {
      for (final code in ['maia:1000', 'stockfish']) {
        expect(OpponentRef.tryParse(code)!.code, code);
      }
    });
  });
}
