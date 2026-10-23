import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

/// Valida o arquivo do banco da Corrida (formato versão 2, ver
/// `tools/build_race_problems.py`): posição legal, e toda a árvore de lances
/// jogável no tabuleiro. A tablebase confere o resto (`--verify` do gerador).
void main() {
  final json = jsonDecode(
    io.File('assets/race/race_problems.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final problems = (json['problems'] as List).cast<Map<String, dynamic>>();

  /// Quantos nós de vez do jogador tem a árvore.
  int size(Map<String, dynamic> node) =>
      1 +
      [
        for (final branch in (node['m'] as Map<String, dynamic>).values)
          if ((branch as Map<String, dynamic>)['n'] != null)
            size(branch['n'] as Map<String, dynamic>),
      ].fold(0, (a, b) => a + b);

  Position play(Position position, String uci) {
    final move = Move.parse(uci);
    expect(move, isNotNull, reason: uci);
    expect(position.isLegal(move!), isTrue, reason: '$uci em ${position.fen}');
    return position.play(move);
  }

  /// Anda por toda a árvore: lances ótimos e lentos legais, resposta legal, e
  /// fim só em mate ou no fim da linha (sem resposta nem continuação).
  void walk(Position position, Map<String, dynamic> node, String id) {
    final distance = node['d'] as int;
    expect(distance.isOdd, isTrue, reason: '$id: o jogador dá o mate');
    final moves = node['m'] as Map<String, dynamic>;
    expect(moves, isNotEmpty, reason: id);
    final slower = [for (final m in (node['w'] as List? ?? const [])) '$m'];
    for (final uci in slower) {
      play(position, uci);
      expect(moves.containsKey(uci), isFalse, reason: '$id: $uci');
    }
    final accepted = [for (final m in (node['a'] as List? ?? const [])) '$m'];
    for (final uci in accepted) {
      play(position, uci);
      expect(moves.containsKey(uci), isFalse, reason: '$id: $uci');
      expect(slower.contains(uci), isFalse, reason: '$id: $uci');
      expect(
        distance,
        greaterThan(15),
        reason: '$id: tolerância só em linha longa',
      );
    }
    for (final entry in moves.entries) {
      final after = play(position, entry.key);
      final branch = entry.value as Map<String, dynamic>;
      expect(branch.containsKey('r'), branch.containsKey('n'), reason: id);
      if (distance == 1) {
        expect(after.isCheckmate, isTrue, reason: '$id: ${entry.key}');
      }
      if (branch['n'] == null) continue;
      expect(after.isGameOver, isFalse, reason: id);
      final next = play(after, branch['r'] as String);
      final child = branch['n'] as Map<String, dynamic>;
      expect((child['d'] as int) < distance, isTrue, reason: id);
      walk(next, child, id);
    }
  }

  test('versão 2, ids únicos e no máximo 10 por faixa', () {
    expect(json['version'], 2);
    final ids = problems.map((p) => p['id']).toSet();
    expect(ids, hasLength(problems.length));
    final perBucket = <int, int>{};
    for (final p in problems) {
      final bucket = p['bucket'] as int;
      perBucket[bucket] = (perBucket[bucket] ?? 0) + 1;
    }
    expect(perBucket.values, everyElement(lessThanOrEqualTo(10)));
    expect(
      perBucket.keys.every(
        (b) => b >= 300 && b <= 2600 && b % (b < 1500 ? 50 : 25) == 0,
      ),
      isTrue,
    );
  });

  test('as faixas vão de 300 a 2600 (50 até 1500, 25 depois)', () {
    final buckets = problems.map((p) => p['bucket'] as int).toSet();
    expect(buckets.reduce((a, b) => a < b ? a : b), 300);
    expect(buckets.reduce((a, b) => a > b ? a : b), 2600);
    final levels = [for (final p in problems) p['level'] as int];
    expect(levels, [...levels]..sort());
  });

  test('300 a 850 são mates curtos sintéticos, na ordem da régua', () {
    for (final p in problems) {
      final bucket = p['bucket'] as int;
      if (bucket >= 900) continue;
      expect(p['source'], 'synthetic', reason: '${p['id']}');
      expect(p['goal'], 'mate', reason: '${p['id']}');
      final mateIn = ((p['dtm'] as int) + 1) ~/ 2;
      final allowed = bucket <= 500
          ? 1
          : bucket <= 650
          ? 2
          : bucket == 700
          ? 1
          : bucket == 750
          ? 2
          : 3;
      expect(mateIn, allowed, reason: '${p['id']}');
      if (bucket >= 700 && bucket <= 750) {
        expect(['KBBK', 'KBNK'], contains(p['kind']), reason: '${p['id']}');
      } else if (bucket <= 650) {
        expect(['KQK', 'KRK'], contains(p['kind']), reason: '${p['id']}');
      }
    }
  });

  test('de 900 em diante: sem mate trivial e sem linha longa demais', () {
    for (final p in problems) {
      final bucket = p['bucket'] as int;
      if (bucket < 900) continue;
      expect(p['source'], 'lichess', reason: '${p['id']}');
      final dtm = p['dtm'] as int;
      if (p['goal'] == 'mate') {
        final floor = bucket < 1200
            ? 3
            : bucket < 1600
            ? 5
            : 7;
        expect(dtm, greaterThanOrEqualTo(floor), reason: '${p['id']}');
      } else {
        final ceiling = bucket <= 1000
            ? 21
            : bucket <= 1200
            ? 31
            : bucket <= 1500
            ? 45
            : 999;
        expect(dtm, lessThanOrEqualTo(ceiling), reason: '${p['id']}');
      }
    }
  });

  for (final problem in problems) {
    final id = problem['id'] as String;
    group(id, () {
      final fen = problem['fen'] as String;

      test('a faixa é a do nível, o tema é do filtro', () {
        final level = problem['level'] as int;
        expect(
          level < 1500 ? level ~/ 50 * 50 : level ~/ 25 * 25,
          problem['bucket'],
        );
        expect(problem['theme'], anyOf('rook', 'pawns', 'queen', 'minor'));
      });

      test('a posição é legal e até 7 peças', () {
        final position = Chess.fromSetup(Setup.parseFen(fen));
        expect(position.isGameOver, isFalse);
        expect(position.board.occupied.size, lessThanOrEqualTo(7));
      });

      test('a árvore é jogável e cabe no teto', () {
        final tree = problem['tree'] as Map<String, dynamic>;
        expect(size(tree), lessThanOrEqualTo(40));
        expect(tree['d'], problem['dtm']);
        expect((tree['m'] as Map).length, lessThanOrEqualTo(3));
        walk(Chess.fromSetup(Setup.parseFen(fen)), tree, id);
      });
    });
  }
}
