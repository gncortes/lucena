import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/variation_tree.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/widgets/lesson_part_widgets.dart';

import '../../../testing/test_app.dart';

TreeMove m(String label) => TreeMove(label: label, fen: label);

VariationTree tree({List<VariationBranch> branches = const []}) =>
    VariationTree(
      startFen: 'start',
      main: [m('1.Rf4'), m('1...Re6'), m('2.Re4'), m('2...Rd6'), m('3.Rf5')],
      branches: branches,
    );

Future<void> pump(
  WidgetTester tester,
  VariationTree tree,
  TreePosition position, {
  void Function(TreePosition)? onSelect,
  Size size = const Size(360, 740),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    TestApp(
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: VariationStrip(
            tree: tree,
            position: position,
            text: 'Comment.',
            onSelect: onSelect ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

String plain(Text text) => (text.data ?? text.textSpan!.toPlainText())
    .replaceAll(RegExp('[\u2066\u2069]'), '');

void main() {
  testWidgets('a notação da fala: sem "1..." no meio da linha, 1 botão por '
      'lance', (tester) async {
    await pump(tester, tree(), const TreePosition.main(2));
    expect(
      plain(tester.widget(find.byKey(LessonKeys.variationStripCurrent))),
      'Re6',
    );
    for (var ply = 1; ply <= 5; ply++) {
      expect(find.byKey(LessonKeys.variationMove(ply)), findsOneWidget);
    }
    expect(find.text('\u20662.Re4\u2069'), findsOneWidget);
    expect(find.text('\u20662...Rd6\u2069'), findsNothing);
    expect(find.text('\u2066Rd6\u2069'), findsOneWidget);
  });

  testWidgets('a linha que abre pelas pretas mantém o "1..."', (tester) async {
    await pump(
      tester,
      VariationTree(startFen: 's', main: [m('1...Re6'), m('2.Re4')]),
      const TreePosition.main(1),
    );
    expect(
      plain(tester.widget(find.byKey(LessonKeys.variationStripCurrent))),
      '1...Re6',
    );
  });

  testWidgets('o rótulo de acessibilidade não leva os isolantes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, tree(), const TreePosition.main(2));
    expect(find.bySemanticsLabel('Re6'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ramo: recuado 16 dp, com = e alvos de 48 dp; toque avisa o '
      'lugar', (tester) async {
    final branch = VariationBranch(
      id: 'b',
      at: 2,
      moves: [m('2.Rd4?'), m('2...Re5')],
      result: VariationResult.draw,
    );
    final taps = <TreePosition>[];
    await pump(
      tester,
      tree(branches: [branch]),
      const TreePosition.main(3),
      onSelect: taps.add,
    );
    final main = tester.getRect(find.byKey(LessonKeys.variationMove(1)));
    final alt = tester.getRect(
      find.byKey(LessonKeys.variationBranchMove('b', 1)),
    );
    expect(alt.left - main.left, closeTo(16, 1));
    expect(alt.top, greaterThan(main.bottom - 1));
    for (final key in [
      LessonKeys.variationMove(1),
      LessonKeys.variationBranchMove('b', 1),
      LessonKeys.variationBranchMove('b', 2),
    ]) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
    }
    expect(find.byKey(LessonKeys.variationResult('b')), findsOneWidget);
    await tester.tap(find.byKey(LessonKeys.variationBranchMove('b', 2)));
    expect(taps, [const TreePosition.branch('b', 2)]);
  });

  for (final size in const [Size(360, 640), Size(360, 740), Size(412, 917)]) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('sem overflow em $size, fonte $scale', (tester) async {
        final branch = VariationBranch(
          id: 'b',
          at: 2,
          moves: [m('2.Rd4?'), m('2...Re5'), m('3.Rf5'), m('3...Rd6')],
          result: VariationResult.draw,
        );
        await pump(
          tester,
          tree(branches: [branch]),
          const TreePosition.branch('b', 1),
          size: size,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
