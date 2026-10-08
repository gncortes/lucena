import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Confere que todo texto (não os ícones) dentro de [region] está numa linha
/// só e não foi cortado: nenhum rótulo quebrou.
void expectNoWrappedText(WidgetTester tester, Finder region) {
  final texts = find.descendant(of: region, matching: find.byType(Text));
  expect(texts, findsWidgets);
  for (final element in texts.evaluate()) {
    RenderParagraph? paragraph;
    void visit(Element child) {
      if (paragraph != null) return;
      final render = child.renderObject;
      if (child.widget is RichText && render is RenderParagraph) {
        paragraph = render;
        return;
      }
      child.visitChildren(visit);
    }

    element.visitChildren(visit);
    final text = (element.widget as Text).data;
    expect(paragraph, isNotNull, reason: '"$text" sem parágrafo');
    expect(paragraph!.maxLines, 1, reason: '"$text" pode quebrar');
    expect(paragraph!.didExceedMaxLines, isFalse, reason: '"$text" cortado');
  }
}
