import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/theme_cycle_rules.dart';

/// H-LIC-50 (B18): 70 firma, 30 a 69 reforça, abaixo de 30 refaz.
void main() {
  test('limites do ciclo: 70, 69, 30 e 29', () {
    expect(ThemeCycleRules.result(100), ThemePhase.firm);
    expect(ThemeCycleRules.result(70), ThemePhase.firm);
    expect(ThemeCycleRules.result(69), ThemePhase.reinforce);
    expect(ThemeCycleRules.result(30), ThemePhase.reinforce);
    expect(ThemeCycleRules.result(29), ThemePhase.redo);
    expect(ThemeCycleRules.result(0), ThemePhase.redo);
  });
}
