import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/core/widgets/exercise_result_mark.dart';

void main() {
  Future<Icon> mark(WidgetTester tester, {required bool correct}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExerciseResultMark(correct: correct)),
      ),
    );
    return tester.widget<Icon>(find.byKey(TrainingKeys.exerciseResultMark));
  }

  testWidgets('acerto é check_circle verde', (tester) async {
    final icon = await mark(tester, correct: true);
    expect(icon.icon, Icons.check_circle);
    expect(icon.color, AppColors.successColor);
  });

  testWidgets('erro é cancel vermelho', (tester) async {
    final icon = await mark(tester, correct: false);
    expect(icon.icon, Icons.cancel);
    expect(icon.color, AppColors.errorColor);
  });
}
