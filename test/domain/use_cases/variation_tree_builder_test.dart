import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/variation_tree.dart';
import 'package:lucena/domain/use_cases/speech_lines.dart';
import 'package:lucena/domain/use_cases/speech_links.dart';
import 'package:lucena/domain/use_cases/variation_tree_builder.dart';

void main() {
  const start = '8/5k2/8/8/4K3/6P1/8/8 w - - 2 2';

  SpeechLine line() {
    var position = Chess.fromSetup(Setup.parseFen(start)) as Position;
    final fens = [position.fen];
    final moves = <Move>[];
    for (final uci in ['e4d3', 'f7e7', 'd3e4']) {
      final move = Move.parse(uci)!;
      moves.add(move);
      position = position.play(move);
      fens.add(position.fen);
    }
    return SpeechLine(
      links: [
        for (final (i, text) in ['2.Kd3', 'Ke7', '3.Ke4'].indexed)
          SpeechLink(start: i, end: i + 1, text: text, isMove: true),
      ],
      fens: fens,
      moves: moves,
    );
  }

  test('a árvore da fala: rótulos, ramo refeito, glifo e resultado', () {
    final tree = VariationTreeBuilder.fromSpeech(
      line: line(),
      branches: const [
        CitedBranch(
          id: 'b',
          at: 2,
          uci: ['g3g4', 'e7d6'],
          glyphs: ['?', null],
          result: VariationResult.draw,
        ),
      ],
      comment: (id, ply) => ply == null ? 'alt' : null,
    );
    expect(tree.main.length, 3);
    expect(tree.main.first.label, '2.Kd3');
    final branch = tree.branchOf('b')!;
    expect(branch.at, 2);
    expect(branch.moves.first.label, '3.g4?');
    expect(branch.moves.last.label, '3...Kd6');
    expect(branch.result, VariationResult.draw);
    expect(branch.comment, 'alt');
    expect(
      tree.fenAt(const TreePosition.branch('b', 1)),
      isNot(tree.main[2].fen),
    );
  });

  test('ramo ilegal ou depois do fim da linha fica de fora', () {
    final tree = VariationTreeBuilder.fromSpeech(
      line: line(),
      branches: const [
        CitedBranch(id: 'bad', at: 2, uci: ['a1a8']),
        CitedBranch(id: 'late', at: 9, uci: ['g3g4']),
      ],
    );
    expect(tree.branches, isEmpty);
  });
}
