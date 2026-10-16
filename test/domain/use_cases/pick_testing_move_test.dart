import 'dart:convert';
import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/use_cases/pick_testing_move.dart';

/// Análise de mentira: o que cada posição (FEN) devolve, na ordem do motor.
AnalyseLines fake(Map<String, List<(String, int)>> table) {
  return (position, {required lines, required deep}) async {
    final rows = table[position.fen] ?? const [];
    return [
      for (final (uci, white) in rows.take(lines))
        EngineLine(
          score: EngineScore(centipawns: white),
          moves: [uci],
        ),
    ];
  };
}

/// Stockfish de verdade (o do PATH), para a posição do print.
AnalyseLines stockfish() {
  final info = RegExp(
    r'^info .*depth (\d+) .*multipv (\d+) score (cp|mate) (-?\d+).* pv (\S+)',
  );
  return (position, {required lines, required deep}) async {
    final process = await Process.start('stockfish', const []);
    final found = <int, EngineLine>{};
    final done = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .firstWhere((line) {
          final m = info.firstMatch(line);
          if (m != null) {
            final sign = position.turn == Side.white ? 1 : -1;
            final value = int.parse(m.group(4)!) * sign;
            found[int.parse(m.group(2)!)] = EngineLine(
              score: m.group(3) == 'cp'
                  ? EngineScore(centipawns: value)
                  : EngineScore(mate: value),
              moves: [m.group(5)!],
            );
          }
          return line.startsWith('bestmove');
        });
    process.stdin
      ..writeln('setoption name MultiPV value $lines')
      ..writeln('position fen ${position.fen}')
      ..writeln('go depth ${deep ? 16 : 12}');
    await done;
    process.kill();
    return [for (final key in found.keys.toList()..sort()) found[key]!];
  };
}

void main() {
  const start = '8/8/8/7P/8/8/K5k1/8 w - - 0 1';
  Position root() => Chess.fromSetup(Setup.parseFen(start));
  String after(String uci) => root().play(Move.parse(uci)!).fen;

  test(
    'empate: entre lances iguais, o que deixa menos respostas que salvam',
    () async {
      final pick = PickTestingMove(
        fake({
          start: [('a2b2', 0), ('a2a3', 0)],
          after('a2b2'): [
            ('g2g3', 0),
            ('g2f3', 0),
            ('g2h3', 0),
            ('g2f2', 0),
            ('g2h2', 0),
          ],
          after('a2a3'): [('g2g3', 0), ('g2f3', 400), ('g2h3', 400)],
        }),
      );
      expect(await pick.pick(root()), 'a2a3');
    },
  );

  test('empate com as mesmas respostas: o rei que avança', () async {
    final rows = [('g2g3', 0), ('g2f3', 0)];
    final pick = PickTestingMove(
      fake({
        start: [('a2a1', 0), ('a2b3', 0)],
        after('a2a1'): rows,
        after('a2b3'): rows,
      }),
    );
    // Sem peão o alvo é o rei inimigo: Rb3 se aproxima, Ra1 se afasta.
    expect(await pick.pick(root()), 'a2b3');
  });

  test('ganhando: o melhor lance do motor', () async {
    final pick = PickTestingMove(
      fake({
        start: [('a2b2', 900), ('a2a3', 880)],
      }),
    );
    expect(await pick.pick(root()), 'a2b2');
  });

  test('sem resposta do motor: nulo', () async {
    expect(await PickTestingMove(fake({})).pick(root()), isNull);
  });

  test('a posição do print: o rei não fica indo e voltando', () async {
    if (Process.runSync('which', ['stockfish']).exitCode != 0) {
      markTestSkipped('sem stockfish no PATH');
      return;
    }
    Position position = Chess.fromSetup(
      Setup.parseFen('8/1k6/8/8/8/8/2K3P1/8 b - - 0 1'),
    );
    final engine = stockfish();
    final pick = PickTestingMove(engine);
    final line = <String>[];
    // O aluno joga o melhor lance de defesa; a máquina responde pela regra.
    for (var turn = 0; turn < 6; turn++) {
      final student = (await engine(position, lines: 1, deep: false)).first;
      final reply = Move.parse(student.moves.first)!;
      line.add(position.makeSan(reply).$2);
      position = position.play(reply);
      final uci = await pick.pick(position);
      expect(uci, isNotNull);
      final move = Move.parse(uci!)!;
      line.add(position.makeSan(move).$2);
      position = position.play(move);
    }
    // ignore: avoid_print
    print('Linha: ${line.join(' ')}');
    expect(line.toSet().length, greaterThan(4));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
