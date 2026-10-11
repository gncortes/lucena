import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/speedrun_category.dart';

import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  final speedruns = sampleSpeedruns;

  test('o speedrun do Coco é de iniciante, não aparece no intermediário', () {
    final coco = speedruns.firstWhere((s) => s.kind == SpeedrunKind.rung);
    expect(SpeedrunCategories.of(coco), SpeedrunCategory.beginner);
  });

  test('final com dificuldade própria fica com ela', () {
    for (final speedrun in speedruns) {
      final own = speedrun.category;
      if (own != null) expect(SpeedrunCategories.of(speedrun), own);
    }
  });

  test('a Jornada completa aparece em todas', () {
    for (final speedrun in speedruns) {
      if (speedrun.kind == SpeedrunKind.full) {
        expect(SpeedrunCategories.of(speedrun), isNull);
      }
    }
  });
}
