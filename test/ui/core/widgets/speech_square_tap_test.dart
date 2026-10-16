import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';
import 'package:lucena/ui/core/widgets/square_flash.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:lucena/ui/lesson_script/widgets/script_board.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';

import '../../../../testing/test_app.dart';

void main() {
  const fala =
      'As casas-chave são f5, g5 e h5. Jogue 1.Rg7 e depois [e4] e Rg7.';

  Future<List<String>> pumpFala(WidgetTester tester, {bool taps = true}) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SpeechText(
            text: fala,
            style: const TextStyle(fontSize: 16),
            onSquareTap: taps ? tapped.add : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tapped;
  }

  List<TextSpan> spans(WidgetTester tester) {
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(SpeechText),
        matching: find.byType(RichText),
      ),
    );
    final out = <TextSpan>[];
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) out.add(span);
      return true;
    });
    return out;
  }

  testWidgets('casa solta e marcada viram alvo; lance em notação não', (
    tester,
  ) async {
    await pumpFala(tester);
    final targets = [
      for (final s in spans(tester))
        if (s.recognizer != null) s.text,
    ];
    expect(targets, ['f5', 'g5', 'h5', 'e4']);
    for (final s in spans(tester).where((s) => s.recognizer != null)) {
      expect(s.style?.fontWeight, FontWeight.w700);
    }
  });

  testWidgets('o toque chama o callback com a casa', (tester) async {
    final tapped = await pumpFala(tester);
    await tester.tapOnText(find.textRange.ofSubstring('g5'));
    await tester.tapOnText(find.textRange.ofSubstring('e4'));
    expect(tapped, ['g5', 'e4']);
  });

  testWidgets('sem callback a casa solta fica como texto comum', (
    tester,
  ) async {
    await pumpFala(tester, taps: false);
    expect(spans(tester).where((s) => s.recognizer != null), isEmpty);
  });

  testWidgets('no balão, o toque na casa ou ao lado dela realça a casa e não '
      'abre a fala inteira; longe dela, abre', (tester) async {
    final tapped = <String>[];
    var opens = 0;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: Builder(
            builder: (context) => ScriptSpeech(
              texts: const ['Mantenha o rei em f6 ou g6, e o peão passa.'],
              metrics: ScriptSpeechMetrics.of(context),
              onSquareTap: tapped.add,
              onOpen: () => opens++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapOnText(find.textRange.ofSubstring('f6'));
    // O dedo cai um pouco ao lado das duas letras: ainda é a casa.
    final g6 = find.textRange.ofSubstring('g6').evaluate().single;
    final box = g6.renderObject
        .getBoxesForSelection(
          TextSelection(
            baseOffset: g6.textRange.start,
            extentOffset: g6.textRange.end,
          ),
        )
        .single
        .toRect();
    await tester.tapAt(
      g6.renderObject.localToGlobal(box.centerRight + const Offset(8, 3)),
    );
    expect(tapped, ['f6', 'g6']);
    expect(opens, 0);
    await tester.tapOnText(find.textRange.ofSubstring('Mantenha'));
    expect(opens, 1);
    expect(tapped, ['f6', 'g6']);
  });

  testWidgets('SquareFlash: realça, repete e some em 1,5 s', (tester) async {
    final flash = SquareFlash();
    addTearDown(flash.dispose);
    var calls = 0;
    flash.addListener(() => calls++);
    flash.show('f5');
    expect(flash.square, 'f5');
    await tester.pump(const Duration(milliseconds: 1000));
    flash.show('f5');
    expect(calls, 2);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(flash.square, 'f5');
    flash.show('g5');
    expect(flash.square, 'g5');
    await tester.pump(SquareFlash.duration);
    expect(flash.square, isNull);
  });

  testWidgets('o tabuleiro realça a casa tocada e o realce some', (
    tester,
  ) async {
    final flash = SquareFlash();
    addTearDown(flash.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptBoard(
            state: const LessonScriptState(
              ready: true,
              fen: '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
            ),
            size: 320,
            settings: const BoardSettings(),
            showMarks: false,
            flash: flash,
            onMove: (_) {},
          ),
        ),
      ),
    );
    Set<Shape> shapes() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).shapes;
    expect(shapes(), isEmpty);
    flash.show('f5');
    await tester.pump();
    expect(shapes().map((s) => (s as Circle).orig), [Square.f5]);
    await tester.pump(SquareFlash.duration);
    expect(shapes(), isEmpty);
  });
}
