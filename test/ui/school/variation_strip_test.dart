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
  bool hideUnseen = false,
  Set<TreePosition> revealed = const {},
  ValueChanged<int>? onReveal,
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
            hideUnseen: hideUnseen,
            revealed: revealed,
            onReveal: onReveal,
          ),
        ),
      ),
    ),
  );
}

String plain(Text text) => (text.data ?? text.textSpan!.toPlainText())
    .replaceAll(RegExp('[\u2066\u2069]'), '');

void main() {
  test('comentário: o lance do começo sai; como sujeito, a frase fica '
      'inteira (r6 E9)', () {
    expect(
      VariationStrip.withoutLeadingMove('1...Re6. O rei volta.'),
      'O rei volta.',
    );
    expect(
      VariationStrip.withoutLeadingMove(
        '3.Rf5 é um bom lance: a vitória continua garantida.',
      ),
      '3.Rf5 é um bom lance: a vitória continua garantida.',
    );
  });

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

  testWidgets('lances ocultos: o bloco cobre o que falta, toca para revelar '
      'e o lance coberto não recebe toque', (tester) async {
    final reveals = <int>[];
    final selected = <TreePosition>[];
    await pump(
      tester,
      tree(),
      const TreePosition.main(2),
      hideUnseen: true,
      revealed: {const TreePosition.main(1), const TreePosition.main(2)},
      onReveal: reveals.add,
      onSelect: selected.add,
    );
    // A medida dos lances vem depois do 1º layout.
    await tester.pump();
    final block = find.byKey(LessonKeys.variationHiddenBlock(0));
    expect(block, findsOneWidget);
    final area = tester.getRect(block);
    expect(area.height, closeTo(28, .5));
    // Em 360 dp a linha quebra: o bloco com a key é o da 1ª linha visual.
    for (final ply in [3]) {
      final text = tester.getRect(
        find.descendant(
          of: find.byKey(LessonKeys.variationMove(ply)),
          matching: find.byType(Text),
        ),
      );
      expect(area.left, lessThanOrEqualTo(text.left + .5));
      expect(area.right, greaterThanOrEqualTo(text.right - .5));
    }
    await tester.tap(block);
    expect(reveals, [0]);
    expect(selected, isEmpty);
  });

  testWidgets('sem o botão ligado a faixa mostra tudo, sem bloco', (
    tester,
  ) async {
    await pump(tester, tree(), const TreePosition.main(1));
    expect(find.byKey(LessonKeys.variationHiddenBlock(0)), findsNothing);
    expect(find.byKey(LessonKeys.variationHiddenToggle), findsNothing);
  });

  testWidgets('trocar o lance da vez com tudo à vista não rola o painel '
      '(o cabeçalho da faixa fica)', (tester) async {
    VariationBranch branch(String id, int at) => VariationBranch(
      id: id,
      at: at,
      moves: [m('${at + 1}.g4?'), m('Rg6')],
      result: VariationResult.draw,
    );
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final t = tree(branches: [branch('a', 1), branch('b', 3)]);
    Future<void> show(TreePosition position) => tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SizedBox(
            height: 330,
            child: SingleChildScrollView(
              controller: controller,
              child: VariationStrip(
                tree: t,
                position: position,
                text: List.filled(120, 'texto').join(' '),
                onSelect: (_) {},
                hideUnseen: false,
                revealed: const {},
              ),
            ),
          ),
        ),
      ),
    );
    tester.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await show(const TreePosition.main(1));
    expect(controller.position.maxScrollExtent, greaterThan(100));
    await show(const TreePosition.main(5));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });

  group('lista rolável (faixa fixa, linhas rolam)', () {
    VariationBranch branch(String id, int at) => VariationBranch(
      id: id,
      at: at,
      moves: [m('${at + 1}.g4?'), m('Rg6')],
      result: VariationResult.draw,
    );

    Future<void> show(
      WidgetTester tester,
      TreePosition position, {
      double maxHeight = 220,
      bool disableAnimations = false,
    }) async {
      tester.view
        ..physicalSize = const Size(360, 780)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 780),
              disableAnimations: disableAnimations,
            ),
            child: Scaffold(
              body: VariationStrip(
                tree: tree(branches: [branch('a', 1), branch('b', 3)]),
                position: position,
                text: 'Comment.',
                onSelect: (_) {},
                maxHeight: maxHeight,
                onToggleHidden: () {},
              ),
            ),
          ),
        ),
      );
    }

    ScrollPosition listPosition(WidgetTester tester) => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(LessonKeys.variationStripList),
            matching: find.byType(Scrollable),
          ),
        )
        .position;

    /// A barra pinta o polegar? Só o pintor dela, sem o que há dentro.
    bool thumbDrawn(WidgetTester tester) {
      final finder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter is ScrollbarPainter,
      );
      final paint = tester.widget<CustomPaint>(finder.first);
      final size = tester.getSize(finder.first);
      final canvas = TestRecordingCanvas();
      paint.foregroundPainter!.paint(canvas, size);
      return canvas.invocations.any(
        (call) =>
            call.invocation.memberName == #drawRRect ||
            call.invocation.memberName == #drawRect,
      );
    }

    testWidgets('o lance da vez sobe ao alto da lista; cabeçalho e botão '
        'ficam; a barra aparece', (tester) async {
      await show(tester, const TreePosition.main(1));
      expect(listPosition(tester).maxScrollExtent, greaterThan(0));
      expect(listPosition(tester).pixels, 0);
      await show(tester, const TreePosition.main(5));
      await tester.pumpAndSettle();
      final listTop = tester
          .getTopLeft(find.byKey(LessonKeys.variationStripList))
          .dy;
      final currentTop = tester
          .getTopLeft(find.byKey(LessonKeys.variationStripCurrent))
          .dy;
      final position = listPosition(tester);
      expect(position.pixels, greaterThan(0));
      expect(
        currentTop - listTop < 48 ||
            position.pixels == position.maxScrollExtent,
        isTrue,
        reason: 'currentTop=$currentTop listTop=$listTop',
      );
      expect(find.byKey(LessonKeys.variationMove(1)), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(LessonKeys.variationMove(1))).dy,
        lessThan(listTop),
      );
      expect(find.byKey(LessonKeys.variationHiddenToggle), findsOneWidget);
      expect(
        thumbDrawn(tester),
        isTrue,
        reason: 'barra fixa com conteúdo fora de vista',
      );
      // Voltar ao primeiro lance leva a lista ao começo.
      await show(tester, const TreePosition.main(1));
      await tester.pumpAndSettle();
      expect(listPosition(tester).pixels, 0);
    });

    testWidgets('tudo cabe: não rola e não há barra', (tester) async {
      await show(tester, const TreePosition.main(5), maxHeight: 900);
      await tester.pumpAndSettle();
      expect(listPosition(tester).maxScrollExtent, 0);
      expect(listPosition(tester).pixels, 0);
      expect(thumbDrawn(tester), isFalse);
    });

    testWidgets('sem animação, a rolagem pula direto', (tester) async {
      await show(tester, const TreePosition.main(1), disableAnimations: true);
      await show(tester, const TreePosition.main(5), disableAnimations: true);
      await tester.pump();
      await tester.pump();
      expect(listPosition(tester).pixels, greaterThan(0));
    });
  });
}
