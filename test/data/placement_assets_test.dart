import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os dados do teste de nível (T52) lidos do disco: o mapa de habilidades e o
/// banco de perguntas, gerados por `tools/placement/`. Confere o que o app
/// assume ao ler os dois arquivos.
void main() {
  final skills = jsonDecode(
    io.File('assets/placement/skills.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final bank = jsonDecode(
    io.File('assets/placement/items.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final nodes = (skills['nodes'] as List).cast<Map<String, dynamic>>();
  final items = (bank['items'] as List).cast<Map<String, dynamic>>();
  final nodeIds = {for (final node in nodes) node['id'] as String};

  const groups = {'rules', 'mates', 'pawns', 'queenRook', 'minor', 'tactics'};
  const bands = {
    'beginner',
    'casual',
    'intermediate',
    'advanced',
    'expert',
    'master',
  };
  const kinds = {'school', 'endgame', 'catalog', 'new'};

  test('todo nó tem id único, grupo, faixa e pré-requisitos que existem', () {
    expect(nodeIds, hasLength(nodes.length));
    for (final node in nodes) {
      expect(groups, contains(node['group']), reason: '${node['id']}');
      expect(bands, contains(node['band']), reason: '${node['id']}');
      expect(node['midgameTactic'], isA<bool>(), reason: '${node['id']}');
      for (final parent in node['requires'] as List) {
        expect(nodeIds, contains(parent), reason: '${node['id']}');
      }
      final lessons = (node['lessons'] as List).cast<Map<String, dynamic>>();
      expect(lessons, isNotEmpty, reason: '${node['id']}');
      for (final lesson in lessons) {
        expect(kinds, contains(lesson['kind']), reason: '${node['id']}');
      }
    }
  });

  test('só a tática de meio-jogo fica de fora do roteiro', () {
    final midgame = [
      for (final node in nodes)
        if (node['midgameTactic'] == true) node['id'],
    ];
    expect(midgame, ['tactics.basic']);
  });

  test('todo item é de um nó do mapa, com tipo e resposta coerentes', () {
    final ids = <String>{};
    for (final item in items) {
      final id = item['id'] as String;
      expect(ids.add(id), isTrue, reason: 'id repetido: $id');
      expect(nodeIds, contains(item['node']), reason: id);
      expect(item['difficulty'], isA<int>(), reason: id);
      expect((item['prompt'] as String).startsWith('placement'), isTrue);
      expect(['own', 'lichess'], contains(item['source']), reason: id);
      switch (item['type']) {
        case 'squares':
          expect(item['squares'] as List, isNotEmpty, reason: id);
        case 'move':
          final moves = (item['moves'] as List).cast<String>();
          final accept = (item['accept'] as List).cast<List<dynamic>>();
          expect(accept, hasLength((moves.length + 1) ~/ 2), reason: id);
          for (var turn = 0; turn < accept.length; turn++) {
            expect(accept[turn], contains(moves[2 * turn]), reason: id);
          }
        case 'choice':
          final options = (item['options'] as List).cast<String>();
          expect(options.length, inInclusiveRange(2, 4), reason: id);
          expect(options, contains(item['answer']), reason: id);
        default:
          fail('$id: tipo ${item['type']}');
      }
    }
  });

  test('a linha de cada pergunta de lance é legal para o dartchess', () {
    for (final item in items.where((item) => item['type'] == 'move')) {
      Position position = Chess.fromSetup(
        Setup.parseFen(item['fen'] as String),
      );
      for (final uci in (item['moves'] as List).cast<String>()) {
        final move = Move.parse(uci);
        expect(move, isNotNull, reason: '${item['id']}: $uci');
        expect(position.isLegal(move!), isTrue, reason: '${item['id']}: $uci');
        position = position.play(
          move is NormalMove ? position.normalizeMove(move) : move,
        );
      }
    }
  });

  test('todo nó tem pergunta, salvo os isentos do build_items.py', () {
    const exempt = {
      'pawns.shoulder',
      'pawns.spareTempi',
      'pawns.correspondingSquares',
    };
    final tested = {for (final item in items) item['node']};
    for (final id in nodeIds.difference(exempt)) {
      expect(tested, contains(id), reason: id);
    }
  });
}
