import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/move_tree.dart';

import '../../../testing/script_fixture.dart';

void main() {
  final script = scriptFixture();
  final ex1 = script.stages[0].examples[0];
  final ex2 = script.stages[0].examples[1];

  test('exemplo 1: o certo e a linha, na ordem do jogo', () {
    final tree = MoveTree.build(ex1);
    expect([for (final n in tree.nodes) n.uci], ['d3e4', 'e8f7']);
    expect(tree.nodes[0].san, 'Ke4');
    expect(tree.nodes[0].id, 'd3e4');
    expect(tree.nodes[1].id, 'd3e4-e8f7');
    expect(tree.nodes[0].number, 1);
    expect(tree.nodes[0].side, Side.white);
    expect(tree.nodes[1].side, Side.black);
    expect(tree.nodes.every((n) => !n.variant), isTrue);
  });

  test('exemplo 2: o certo na principal e o alternativo como variante', () {
    final tree = MoveTree.build(ex2);
    final main = tree.nodes.firstWhere((n) => n.uci == 'e8e7');
    final alt = tree.nodes.firstWhere((n) => n.uci == 'e8f7');
    expect(main.variant, isFalse);
    expect(alt.variant, isTrue);
    expect(main.side, Side.black);
    expect(tree.nodes.indexOf(main), lessThan(tree.nodes.indexOf(alt)));
    expect(tree.node(alt.id), same(alt));
    expect(tree.node('nada'), isNull);
  });

  test('of(step) acha os nós do passo pela identidade', () {
    final tree = MoveTree.build(ex1);
    final nodes = tree.of(ex1.question!.rightStep);
    expect(nodes.map((n) => n.uci), ['d3e4']);
    expect(tree.of(ex1.entry.first), isEmpty);
  });

  test('aluno de pretas (vira) numa linha que começa com lance das brancas: '
      'as pretas ficam com o número das brancas', () {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    final example = ScriptExample.fromJson({
      'id': 'louco',
      'fen': start,
      'vira': true,
      'objetivo': 'tarefa',
      'entrada': [
        {'fen': start, 't': 'e1'},
      ],
      'linha': [
        {
          'fen': 'rnbqkbnr/pppppppp/8/8/8/5P2/PPPPP1PP/RNBQKBNR b KQkq - 0 1',
          'lance': 'f2f3',
          't': 'l1',
        },
        {
          'fen': 'rnbqkbnr/pppp1ppp/8/4p3/8/5P2/PPPPP1PP/RNBQKBNR w KQkq - 0 2',
          'lance': 'e7e5',
          't': 'l2',
        },
        {
          'fen':
              'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2',
          'lance': 'g2g4',
          't': 'l3',
        },
        {
          'fen':
              'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
          'lance': 'd8h4',
          't': 'l4',
        },
      ],
    });
    final tree = MoveTree.build(example);
    expect(
      [
        for (final n in tree.nodes)
          '${n.number}${n.side == Side.white ? '.' : '...'}${n.san}',
      ],
      ['1.f3', '1...e5', '2.g4', '2...Qh4#'],
    );
  });

  test('ScriptTracks.steps monta o trecho de cada trilha', () {
    final q = ex2.question!;
    expect(ScriptTracks.steps(ex2, ScriptTracks.entry), ex2.entry);
    expect(ScriptTracks.steps(ex2, ScriptTracks.main).first, q.rightStep);
    expect(ScriptTracks.steps(ex2, ScriptTracks.reveal).first, q.reveal);
    final alt = ScriptTracks.steps(ex2, ScriptTracks.alt('e8f7'));
    expect(alt.first.t, 'altA');
    expect(alt[2], q.rightStep);
  });
}
