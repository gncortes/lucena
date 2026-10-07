import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';

import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  const threeTwo = TimeControl(
    initial: Duration(minutes: 3),
    increment: Duration(seconds: 2),
  );

  test('os ritmos em grupos: ultra bullet, bullet, blitz e rápido', () {
    final groups = SpeedrunPaces.groups;
    expect(groups.keys, [
      PaceCategory.ultraBullet,
      PaceCategory.bullet,
      PaceCategory.blitz,
      PaceCategory.rapid,
    ]);
    // Ultra bullet: só o tempo, sem acréscimo.
    expect(groups[PaceCategory.ultraBullet]!.map((t) => t.code), [
      '10+0',
      '15+0',
      '30+0',
    ]);
    expect(groups[PaceCategory.bullet]!.map((t) => t.code), ['60+0', '120+1']);
    expect(groups[PaceCategory.blitz]!.map((t) => t.code), [
      '180+0',
      '180+2',
      '300+3',
    ]);
    expect(groups[PaceCategory.rapid]!.map((t) => t.code), ['600+0', '900+10']);
  });

  test('o ritmo padrão mantém o id de antes; os outros levam o ritmo', () {
    expect(
      SpeedrunPaces.idFor('rung.1000', SpeedrunPaces.standard),
      'rung.1000',
    );
    expect(SpeedrunPaces.idFor('rung.1000', threeTwo), 'rung.1000@180+2');
    expect(SpeedrunPaces.parse('rung.1000@180+2'), ('rung.1000', threeTwo));
    expect(SpeedrunPaces.parse('rung.1000'), (
      'rung.1000',
      SpeedrunPaces.standard,
    ));
  });

  test(
    'o speedrun num ritmo tem as mesmas etapas com o relógio dele',
    () async {
      final bases = await FakeJourneyRepository().speedruns();
      final base = bases.first;
      final variant = SpeedrunPaces.resolve(bases, '${base.id}@180+2')!;

      expect(variant.id, '${base.id}@180+2');
      expect(variant.time, threeTwo);
      expect(variant.stages.length, base.stages.length);
      expect(variant.stages.every((stage) => stage.time == threeTwo), isTrue);
      expect(SpeedrunPaces.resolve(bases, 'outro'), isNull);
      expect(SpeedrunPaces.resolve(bases, base.id)?.id, base.id);
    },
  );

  test('cada ritmo é um speedrun próprio', () async {
    final bases = await FakeJourneyRepository().speedruns();
    final Speedrun base = bases.first;
    expect(
      SpeedrunPaces.withTime(base, threeTwo).id,
      isNot(SpeedrunPaces.withTime(base, SpeedrunPaces.standard).id),
    );
  });
}
