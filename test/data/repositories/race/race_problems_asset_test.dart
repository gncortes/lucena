import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

/// Valida o arquivo do banco de problemas: posição legal, de quem joga e o
/// lance da solução legal. A tablebase confere o resto (ver
/// `tools/build_race_problems.py`).
void main() {
  final json = jsonDecode(
    io.File('assets/race/race_problems.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final problems = (json['problems'] as List).cast<Map<String, dynamic>>();

  test('o banco de teste tem ao menos 10 problemas, com ids únicos', () {
    expect(problems.length, greaterThanOrEqualTo(10));
    final ids = problems.map((p) => p['id']).toSet();
    expect(ids, hasLength(problems.length));
  });

  test('os níveis crescem do primeiro ao último', () {
    final levels = [for (final p in problems) p['level'] as int];
    expect(levels, [...levels]..sort());
  });

  for (final problem in problems) {
    final id = problem['id'] as String;
    group(id, () {
      final fen = problem['fen'] as String;

      test('a posição é legal e a vez é das brancas ou das pretas', () {
        // fromSetup recusa posição ilegal (reis, peões na fileira errada...).
        final position = Chess.fromSetup(Setup.parseFen(fen));
        expect(position.isGameOver, isFalse);
        expect(fen.split(' ')[1], anyOf('w', 'b'));
      });

      test('o lance da solução é legal para quem joga', () {
        final position = Chess.fromSetup(Setup.parseFen(fen));
        final move = Move.parse(problem['solution'] as String);
        expect(move, isNotNull);
        expect(position.isLegal(move!), isTrue);
      });

      test('o tema é um dos do filtro', () {
        expect(problem['theme'], anyOf('rook', 'pawns', 'queen', 'minor'));
      });

      test('a posição de partida não é o empate conhecido', () {
        // O final 8/8/3k4/8/3K4/3P4/8/8 w é empate: nunca entra no banco.
        expect(fen.startsWith('8/8/3k4/8/3K4/3P4/8/8 '), isFalse);
      });
    });
  }
}
