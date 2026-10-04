import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/maia/maia_model.dart';
import 'package:lucena/data/services/maia/maia_weights.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

/// Compara o Maia em Dart com as saídas do PyTorch oficial
/// (`test/fixtures/maia/reference.json`, de `tools/maia/make_fixtures.py`).
void main() {
  final reference = jsonDecode(
    io.File('test/fixtures/maia/reference.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = (reference['cases'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  late final MaiaModel model;

  setUpAll(() {
    final bytes = io.File('assets/models/maia3-5m.bin').readAsBytesSync();
    model = MaiaModel(MaiaWeights.parse(bytes));
  });

  List<Position> historyOf(Map<String, dynamic> fixture) {
    var position = GameRules.fromFen(fixture['fen'] as String)!;
    final history = [position];
    for (final uci in (fixture['moves'] as List<dynamic>).cast<String>()) {
      position = position.play(Move.parse(uci)!);
      history.add(position);
    }
    return history;
  }

  MaiaEvaluation evaluate(Map<String, dynamic> fixture) => model.evaluate(
    historyOf(fixture),
    selfElo: fixture['selfElo'] as int,
    oppoElo: fixture['oppoElo'] as int,
  );

  test('the fixtures cover every level, both sides and special moves', () {
    final names = cases.map((fixture) => fixture['name'] as String).toList();
    for (final level in [1000, 1400, 1800, 2200, 2600]) {
      expect(names, contains('start@${level}v$level'));
    }
    expect(names, contains('castling-black@1400v1400'));
    expect(names, contains('en-passant@1400v1400'));
    expect(names, contains('promotion-capture-black@1400v1400'));
    expect(cases.length, greaterThan(60));
  });

  for (final fixture in cases) {
    test('matches PyTorch on ${fixture['name']}', () {
      final evaluation = evaluate(fixture);
      final expected = (fixture['policy'] as Map<String, dynamic>)
          .cast<String, num>();

      expect(historyOf(fixture).last.fen, fixture['position']);
      expect(evaluation.policy.keys.toSet(), expected.keys.toSet());
      for (final MapEntry(key: move, value: probability) in expected.entries) {
        expect(
          evaluation.policy[move],
          closeTo(probability, _tolerance),
          reason: move,
        );
      }
      expect(evaluation.policy.keys.first, fixture['best']);

      final value = (fixture['value'] as Map<String, dynamic>)
          .cast<String, num>();
      expect(evaluation.win, closeTo(value['win']!, _tolerance));
      expect(evaluation.draw, closeTo(value['draw']!, _tolerance));
      expect(evaluation.loss, closeTo(value['loss']!, _tolerance));
      expect(evaluation.ponder, closeTo(fixture['ponder'] as num, _tolerance));
    });
  }

  test('probabilities add up to one and are sorted', () {
    final evaluation = evaluate(cases.first);
    final probabilities = evaluation.policy.values.toList();

    expect(probabilities.reduce((a, b) => a + b), closeTo(1, 1e-9));
    expect(probabilities, [...probabilities]..sort((a, b) => b.compareTo(a)));
    expect(
      evaluation.win + evaluation.draw + evaluation.loss,
      closeTo(1, 1e-9),
    );
  });

  test('the rating changes the prediction', () {
    final history = [GameRules.fromFen('8/8/8/4k3/8/8/8/R3K3 w - - 0 1')!];
    final beginner = model.evaluate(history, selfElo: 1000, oppoElo: 1000);
    final master = model.evaluate(history, selfElo: 2600, oppoElo: 2600);

    expect(
      (beginner.policy['a1a4']! - master.policy['a1a4']!).abs(),
      greaterThan(0.05),
    );
    expect(master.win, greaterThan(beginner.win));
  });

  test('only the last positions of a long game count', () {
    final fixture = cases.firstWhere(
      (fixture) => fixture['name'] == 'italian-long-history@1800v1800',
    );
    final history = historyOf(fixture);
    final recent = history.sublist(history.length - 8);

    expect(model.encode(recent), model.encode(history));
  });

  test('a short game repeats its first position', () {
    final start = GameRules.initial;
    final tokens = model.encode([start]);

    // Peão branco em e2 (casa 12), canal 0, nas 8 posições do histórico.
    for (var slot = 0; slot < 8; slot++) {
      expect(tokens[12 * 96 + slot * 12], 1);
    }
    expect(tokens.where((value) => value == 1).length, 32 * 8);
  });

  test('rejects a file that is not a weights file', () {
    expect(
      () => MaiaWeights.parse(Uint8List.fromList(utf8.encode('not weights'))),
      throwsFormatException,
    );
  });
}

/// A conta em Dart não soma na mesma ordem do PyTorch; a diferença medida nas
/// probabilidades fica abaixo de 1e-5.
const double _tolerance = 1e-4;
