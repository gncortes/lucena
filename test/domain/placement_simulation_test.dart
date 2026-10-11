import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';

import '../../testing/placement_simulation.dart';
import '../../testing/placement_synthetic.dart';

/// A simulação da T52 (Parte 4.5) em tamanho de CI: 40 jogadores de cada tipo
/// (Rasch puro, que também refaz o teste; desatento; e os três cenários de
/// lacuna), uns 240 testes, com semente fixa. As metas são as do documento;
/// a rodada grande fica no `tools/placement/simulate.dart`. Mapa e banco
/// SINTÉTICOS até o banco de verdade chegar.
void main() {
  test('o motor atinge as metas da simulação', () {
    final report = simulate(
      skills: SkillMap.fromJson(syntheticSkillsJson()),
      bank: PlacementBank.fromJson(syntheticItemsJson()),
      schoolLessons: schoolLessons,
      endgameLessons: endgameLessons,
      count: 40,
      seed: 52,
    );
    expect(report.rasch.neighborRate, greaterThanOrEqualTo(0.9));
    expect(report.rasch.exactRate, greaterThanOrEqualTo(0.6));
    expect(report.careless.neighborRate, greaterThanOrEqualTo(0.9));
    expect(report.gapRate, greaterThanOrEqualTo(0.9));
    expect(report.falseSkipRate, lessThanOrEqualTo(0.05));
    expect(
      report.allRight!.index,
      greaterThanOrEqualTo(RatingLevel.expert.index),
    );
    expect(report.allWrong, RatingLevel.beginner);
    expect(report.exposure, greaterThanOrEqualTo(0.4));
    expect(report.meanFirstJump, inInclusiveRange(200, 400));
    expect(report.meanConfirmationMove, lessThan(50));
    expect(report.passes, isTrue);
  });
}
