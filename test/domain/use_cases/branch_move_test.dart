import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/variation_tree.dart';
import 'package:lucena/domain/use_cases/branch_comments.dart';
import 'package:lucena/domain/use_cases/branch_move.dart';

TreeMove _m(String uci) => TreeMove(
  label: uci,
  fen: '8/8/8/8/8/8/8/8 w - - 0 1',
  move: Move.parse(uci),
);

void main() {
  final tree = VariationTree(
    startFen: '8/8/8/8/8/8/8/8 w - - 0 1',
    main: [_m('e2e3'), _m('e7e6'), _m('e3e4')],
    branches: [
      VariationBranch(id: 'b1', at: 0, moves: [_m('g2g4'), _m('e7e6')]),
    ],
  );

  group('BranchMove.match', () {
    test('próximo lance da principal', () {
      expect(
        BranchMove.match(tree, const TreePosition.main(0), 'e2e3'),
        const TreePosition.main(1),
      );
    });
    test('primeiro lance de um ramo que nasce ali', () {
      expect(
        BranchMove.match(tree, const TreePosition.main(0), 'g2g4'),
        const TreePosition.branch('b1', 1),
      );
    });
    test('dentro do ramo, só o próximo dele', () {
      const at = TreePosition.branch('b1', 1);
      expect(
        BranchMove.match(tree, at, 'e7e6'),
        const TreePosition.branch('b1', 2),
      );
      expect(BranchMove.match(tree, at, 'e3e4'), isNull);
    });
    test('fora da árvore: nulo', () {
      expect(
        BranchMove.match(tree, const TreePosition.main(0), 'a1a2'),
        isNull,
      );
      expect(
        BranchMove.match(tree, const TreePosition.main(3), 'e3e4'),
        isNull,
      );
    });
  });

  group('BranchComments.at', () {
    const texts = LessonTexts({
      'L.d.m1': ['resposta das pretas'],
      'L.d.m2': ['segundo lance'],
    });
    test('ply 2 usa o m1 da demo de erro', () {
      expect(
        BranchComments.at(texts: texts, lessonId: 'L', ply: 2, demoId: 'd'),
        'resposta das pretas',
      );
      expect(
        BranchComments.at(texts: texts, lessonId: 'L', ply: 3, demoId: 'd'),
        'segundo lance',
      );
    });
    test('ply 1: fala do erro, senão texto neutro', () {
      expect(
        BranchComments.at(
          texts: texts,
          lessonId: 'L',
          ply: 1,
          mistakeSay: 'erro',
          fallback: 'x',
        ),
        'erro',
      );
      expect(
        BranchComments.at(texts: texts, lessonId: 'L', ply: 1, fallback: 'x'),
        'x',
      );
    });
  });
}
