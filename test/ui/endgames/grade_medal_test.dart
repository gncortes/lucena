import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';
import 'package:lucena/ui/endgames/widgets/grade_widgets.dart';

import '../../../testing/test_app.dart';

/// A folga embaixo do glifo `star_rounded` (Material Icons, grade de 24): a
/// ponta das pernas fica em y ≈ 19,93, então sobra 4,07/24 da caixa.
const _glyphBottomGap = 4.07 / 24;

void main() {
  Future<List<Rect>> stars(WidgetTester tester, double ratio) async {
    await tester.pumpWidget(
      TestApp(
        child: Center(
          child: GradeMedal(
            grade: ExerciseGrade.perfect,
            size: 20,
            sideRatio: ratio,
          ),
        ),
      ),
    );
    final found = find.byIcon(Icons.star_rounded);
    expect(found, findsNWidgets(3));
    final rects = [for (var i = 0; i < 3; i++) tester.getRect(found.at(i))];
    rects.sort((a, b) => a.left.compareTo(b.left));
    return rects;
  }

  /// A base do desenho da estrela (a ponta das pernas), na tela.
  double drawingBottom(Rect icon) =>
      icon.bottom - _glyphBottomGap * icon.height;

  testWidgets('M2 (CompEstrelas proporcao=0.5): as três estrelas com a base do '
      'desenho no mesmo pixel', (tester) async {
    final rects = await stars(tester, GradeMedal.compactSideRatio);
    final [left, middle, right] = rects;
    expect(middle.height, 20);
    expect(left.height, 10);
    expect(right.height, 10);
    // Mesma linha de base (resíduo de ~0,3 px em 20: abaixo de meio pixel).
    expect(drawingBottom(left), closeTo(drawingBottom(middle), 0.5));
    expect(drawingBottom(right), closeTo(drawingBottom(middle), 0.5));
    expect(drawingBottom(left), drawingBottom(right));
    // As laterais encostam na do meio (margem de -3 px em 20).
    expect(middle.left - left.right, closeTo(-3, 0.01));
    expect(right.left - middle.right, closeTo(-3, 0.01));
  });

  testWidgets('a medalha grande (padrão 0,6) segue como antes: laterais com a '
      'base da caixa na da do meio, sem sobreposição', (tester) async {
    final [left, middle, right] = await stars(
      tester,
      GradeMedal.defaultSideRatio,
    );
    expect(left.height, 12);
    expect(left.bottom, middle.bottom);
    expect(right.bottom, middle.bottom);
    expect(left.right, middle.left);
    expect(middle.right, right.left);
  });
}
