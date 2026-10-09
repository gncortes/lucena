import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/school/widgets/exercise_layout.dart';

/// T60: a geometria do modo exercício, em contas puras.
void main() {
  const header = 120.0;
  const footer = 96.0;

  for (final (name, area, expected) in [
    // Celular pequeno: a largura manda.
    ('celular pequeno 360×640', const Size(360, 520), 288.0),
    // Celular grande: a largura manda.
    ('celular grande 412×915', const Size(412, 800), 396.0),
    ('tablet 800×1280', const Size(800, 1150), 784.0),
    // Tablet deitado: a altura manda.
    ('tablet deitado 1280×800', const Size(1280, 700), 468.0),
  ]) {
    test('boardSize, $name: o maior que cabe', () {
      final size = ExerciseLayout.boardSize(
        area,
        header: header,
        footer: footer,
      );
      expect(size, expected);
      expect(size, lessThanOrEqualTo(area.width - 2 * ExerciseLayout.gutter));
      expect(size + header + footer, lessThanOrEqualTo(area.height));
    });
  }

  test('boardSize: nunca menor que o mínimo jogável', () {
    expect(
      ExerciseLayout.boardSize(const Size(100, 100), header: 90, footer: 90),
      ExerciseLayout.minBoard,
    );
  });

  test('solvingRect: no centro da tela quando cabe', () {
    const area = Size(412, 800);
    final rect = ExerciseLayout.solvingRect(
      area,
      header: 60,
      footer: footer,
      centerY: 380,
    );
    expect(rect.center.dx, 206);
    expect(rect.center.dy, 380);
  });

  test('solvingRect: enunciado alto, desce só o necessário', () {
    const area = Size(412, 800);
    final rect = ExerciseLayout.solvingRect(
      area,
      header: 200,
      footer: footer,
      centerY: 300,
    );
    expect(rect.top, 200 + ExerciseLayout.gutter);
    expect(rect.bottom, lessThanOrEqualTo(800 - footer));
  });

  test('solvingRect: sem centro dado, no meio do espaço livre', () {
    const area = Size(412, 800);
    final rect = ExerciseLayout.solvingRect(
      area,
      header: header,
      footer: footer,
    );
    expect(rect.center.dy, header + (800 - header - footer) / 2);
  });

  test('explainingRect: no alto, deixando a folha da fala', () {
    final rect = ExerciseLayout.explainingRect(
      const Size(412, 700),
      sheetRoom: 280,
    );
    expect(rect.top, ExerciseLayout.gutter);
    expect(rect.height, 396);
    expect(rect.center.dx, 206);
  });
}
