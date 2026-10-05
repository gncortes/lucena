import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/free_board/widgets/character_bar.dart';

void main() {
  const size = Size(200, 80);

  test('a ponta sai da lateral esquerda, perto da base, num caminho só', () {
    final path = BubblePainter.pathFor(size, tail: 10);
    final bounds = path.getBounds();
    expect(bounds.left, closeTo(0, 0.5));
    expect(bounds.right, closeTo(200, 0.5));
    // A pontinha, perto da base, faz parte do balão.
    expect(path.contains(const Offset(2, 54)), isTrue);
    expect(path.contains(const Offset(2, 39)), isFalse);
    // Fora da ponta, a lateral do corpo começa depois dela.
    expect(path.contains(const Offset(4, 10)), isFalse);
  });

  test('em idiomas da direita para a esquerda, a ponta fica à direita', () {
    final path = BubblePainter.pathFor(size, tail: 10, tailOnRight: true);
    expect(path.contains(const Offset(198, 54)), isTrue);
    expect(path.contains(const Offset(196, 10)), isFalse);
    expect(path.contains(const Offset(4, 10)), isTrue);
  });
}
