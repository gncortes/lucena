// Mede o Maia em Dart contra as fixtures: maior diferença para o PyTorch e
// tempo por posição.
//
// Uso (na raiz do repositório):
//   dart run tools/maia/benchmark.dart                  (JIT)
//   dart compile exe tools/maia/benchmark.dart -o /tmp/maia_benchmark
//   /tmp/maia_benchmark                                 (AOT, como no app)
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/services/maia/maia_model.dart';
import 'package:lucena/data/services/maia/maia_weights.dart';

void main() {
  final load = Stopwatch()..start();
  final bytes = io.File('assets/models/maia3-5m.bin').readAsBytesSync();
  final model = MaiaModel(MaiaWeights.parse(bytes));
  io.stdout.writeln('carregar os pesos: ${load.elapsedMilliseconds} ms');

  final reference = jsonDecode(
    io.File('test/fixtures/maia/reference.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = (reference['cases'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  var worst = 0.0;
  var sameBest = 0;
  final times = <int>[];
  for (var round = 0; round < 3; round++) {
    for (final fixture in cases) {
      var position = Chess.fromSetup(Setup.parseFen(fixture['fen'] as String));
      final history = <Position>[position];
      for (final uci in (fixture['moves'] as List<dynamic>).cast<String>()) {
        position = position.play(Move.parse(uci)!) as Chess;
        history.add(position);
      }
      final watch = Stopwatch()..start();
      final evaluation = model.evaluate(
        history,
        selfElo: fixture['selfElo'] as int,
        oppoElo: fixture['oppoElo'] as int,
      );
      times.add(watch.elapsedMicroseconds);
      if (round > 0) continue;
      final expected = (fixture['policy'] as Map<String, dynamic>)
          .cast<String, num>();
      for (final MapEntry(key: move, value: probability) in expected.entries) {
        final difference = (evaluation.policy[move]! - probability).abs();
        if (difference > worst) worst = difference;
      }
      if (evaluation.policy.keys.first == fixture['best']) sameBest++;
    }
  }
  // A primeira rodada aquece (JIT e cache); o tempo vem das outras duas.
  final warm = times.sublist(cases.length)..sort();
  io.stdout
    ..writeln('lance mais provável igual: $sameBest de ${cases.length}')
    ..writeln(
      'maior diferença de probabilidade: ${worst.toStringAsExponential(2)}',
    )
    ..writeln(
      'tempo por posição (ms): mediana ${_ms(warm[warm.length ~/ 2])}, '
      'mínimo ${_ms(warm.first)}, máximo ${_ms(warm.last)}, '
      'primeira ${_ms(times.first)}',
    );
}

String _ms(int microseconds) => (microseconds / 1000).toStringAsFixed(1);
