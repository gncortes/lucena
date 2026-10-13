import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/variation_tree.dart';

TreeMove m(String label) => TreeMove(label: label, fen: 'fen $label');

void main() {
  final tree = VariationTree(
    startFen: 'start',
    main: [m('1.a'), m('1...b'), m('2.c'), m('2...d')],
    branches: [
      VariationBranch(
        id: 'x',
        at: 2,
        moves: [m('2.e'), m('2...f')],
        result: VariationResult.draw,
        comment: 'alt',
        commentByPly: const {2: 'second'},
      ),
      VariationBranch(id: 'y', at: 2, moves: [m('2.g')]),
    ],
  );

  test('rows: principal até o lance do ponto, ramos, resto', () {
    final rows = tree.rows;
    expect(rows.length, 4);
    expect([for (final r in rows[0].moves) r.shown], ['1.a', 'b', '2.c']);
    expect(rows[1].branch!.id, 'x');
    expect([for (final r in rows[1].moves) r.shown], ['2.e', 'f']);
    expect(rows[1].result, VariationResult.draw);
    expect(rows[2].branch!.id, 'y');
    expect(rows[2].result, isNull);
    expect([for (final r in rows[3].moves) r.shown], ['2...d']);
  });

  test('previous: o 1º lance do ramo volta ao ponto de partida', () {
    expect(
      tree.previous(const TreePosition.branch('x', 1)),
      const TreePosition.main(2),
    );
    expect(
      tree.previous(const TreePosition.branch('x', 2)),
      const TreePosition.branch('x', 1),
    );
    expect(
      tree.previous(const TreePosition.main(0)),
      const TreePosition.main(0),
    );
    expect(tree.canPrevious(const TreePosition.main(0)), isFalse);
    expect(tree.canPrevious(const TreePosition.branch('x', 1)), isTrue);
  });

  test('next: segue o ramo e para no fim dele', () {
    expect(
      tree.next(const TreePosition.branch('x', 1)),
      const TreePosition.branch('x', 2),
    );
    expect(tree.canNext(const TreePosition.branch('x', 2)), isFalse);
    expect(
      tree.next(const TreePosition.branch('x', 2)),
      const TreePosition.branch('x', 2),
    );
    expect(tree.next(const TreePosition.main(2)), const TreePosition.main(3));
    expect(tree.canNext(const TreePosition.main(4)), isFalse);
  });

  test('contains, fenAt e comentário do ramo', () {
    expect(tree.contains(const TreePosition.branch('x', 2)), isTrue);
    expect(tree.contains(const TreePosition.branch('x', 3)), isFalse);
    expect(tree.contains(const TreePosition.branch('z', 1)), isFalse);
    expect(tree.contains(const TreePosition.main(5)), isFalse);
    expect(tree.fenAt(const TreePosition.main(0)), 'start');
    expect(tree.fenAt(const TreePosition.branch('x', 2)), 'fen 2...f');
    expect(tree.commentAt(const TreePosition.branch('x', 1)), 'alt');
    expect(tree.commentAt(const TreePosition.branch('x', 2)), 'second');
    expect(tree.commentAt(const TreePosition.main(1)), isNull);
  });

  test('stateOf: jogado, da vez e por jogar (base do modo T69)', () {
    const current = TreePosition.branch('x', 1);
    expect(tree.stateOf(current, current), VariationMoveState.current);
    expect(
      tree.stateOf(const TreePosition.main(2), current),
      VariationMoveState.played,
    );
    expect(
      tree.stateOf(const TreePosition.main(3), current),
      VariationMoveState.upcoming,
    );
    expect(
      tree.stateOf(const TreePosition.branch('x', 2), current),
      VariationMoveState.upcoming,
    );
  });

  test('checkpoint da variante: ida e volta no JSON', () {
    const variation = VariationCheckpoint(
      source: VariationCheckpoint.speech,
      step: 'intro',
      line: 0,
      branch: 'd2',
      ply: 1,
      open: true,
    );
    final checkpoint = LessonCheckpoint(
      lessonId: 'l',
      step: 0,
      variation: variation,
    );
    final back = LessonCheckpoint.fromJson(checkpoint.toJson())!;
    expect(back.variation, variation);
    expect(back, checkpoint);
    expect(
      LessonCheckpoint.fromJson(
        const LessonCheckpoint(lessonId: 'l', step: 0).toJson(),
      )!.variation,
      isNull,
    );
  });
}
