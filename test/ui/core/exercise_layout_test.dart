import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/board/exercise_layout.dart';

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

  test('solvingRect: no centro dado quando cabe', () {
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

  test('solvingRect: enunciado alto encolhe o tabuleiro, sem tirá-lo do '
      'centro', () {
    const area = Size(412, 800);
    final rect = ExerciseLayout.solvingRect(area, header: 200, footer: footer);
    expect(rect.center.dy, (800 - footer) / 2);
    expect(rect.top, greaterThanOrEqualTo(200 + ExerciseLayout.gutter));
    expect(rect.bottom, lessThanOrEqualTo(800 - footer));
  });

  test('solvingRect: sem centro dado, no centro do espaço útil', () {
    const area = Size(412, 800);
    final rect = ExerciseLayout.solvingRect(
      area,
      header: header,
      footer: footer,
    );
    expect(rect.center.dy, (800 - footer) / 2);
  });

  test('headerRoom: o enunciado fica com o que sobra acima do menor '
      'tabuleiro', () {
    const area = Size(412, 800);
    final room = ExerciseLayout.headerRoom(area, footer: footer);
    final rect = ExerciseLayout.solvingRect(
      area,
      header: 10000,
      footer: footer,
    );
    expect(rect.top - ExerciseLayout.gutter, closeTo(room, 0.001));
  });

  test('explainingRect, escola: no centro do espaço acima da folha', () {
    const area = Size(412, 900);
    final rect = ExerciseLayout.explainingRect(
      area,
      sheetRoom: 280,
      lowered: true,
    );
    final sheet = ExerciseLayout.sheetTop(area, sheetRoom: 280, lowered: true);
    expect(sheet, 900 - 280 + ExerciseLayout.gutter);
    expect(rect.center.dy, sheet / 2);
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
