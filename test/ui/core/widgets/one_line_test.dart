import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/one_line.dart';

void main() {
  testWidgets('rótulo longo num espaço curto: uma linha só, menor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(width: 60, child: OneLine('Ultra Bullet')),
        ),
      ),
    );
    final text = tester.renderObject<RenderParagraph>(
      find.text('Ultra Bullet'),
    );
    // O texto é medido sem limite de largura (não quebra) e depois
    // encolhido para caber nos 60.
    expect(text.size.width, greaterThan(60));
    // Quebra nenhuma: o texto inteiro numa linha, encolhido para caber.
    expect(tester.getSize(find.byType(OneLine)).width, lessThanOrEqualTo(60));
  });
}
