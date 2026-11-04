import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/demo_offer_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/demo_offer_rules.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_now.dart';

/// H-LIC-51: oferta da demo no máximo 2 vezes, com 3 dias entre elas.
void main() {
  final day = DateTime.utc(2026, 11, 4, 10);

  test('demo com 0 ofertas vê a oferta', () {
    expect(
      DemoOfferRules.shouldOffer(const DemoOfferState(), demo: true, now: day),
      isTrue,
    );
  });

  test('comprador nunca vê', () {
    expect(
      DemoOfferRules.shouldOffer(const DemoOfferState(), demo: false, now: day),
      isFalse,
    );
  });

  test('2 ofertas: não vê mais, nem depois de muito tempo', () {
    final state = DemoOfferState(count: 2, lastShown: day);
    expect(
      DemoOfferRules.shouldOffer(
        state,
        demo: true,
        now: day.add(const Duration(days: 30)),
      ),
      isFalse,
    );
  });

  test('a 2ª oferta só depois de 3 dias', () {
    final state = DemoOfferState(count: 1, lastShown: day);
    bool at(Duration d) =>
        DemoOfferRules.shouldOffer(state, demo: true, now: day.add(d));
    expect(at(const Duration(days: 2, hours: 23)), isFalse);
    expect(at(const Duration(days: 3)), isTrue);
  });

  group('contador persistido', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('sobrevive a reabrir o app e usa o Now', () async {
      final now = FakeNow(day);
      await LocalDemoOfferRepository(
        PreferencesService(),
        now,
      ).markShown(TrainingCourse.pilares);
      final back = await LocalDemoOfferRepository(
        PreferencesService(),
        now,
      ).load(TrainingCourse.pilares);
      expect(back.count, 1);
      expect(back.lastShown, day);
      expect(
        (await LocalDemoOfferRepository(
          PreferencesService(),
          now,
        ).load(TrainingCourse.escola)).count,
        0,
      );
    });

    test('valor estragado vale como zero ofertas', () async {
      await PreferencesService().setString(
        LocalDemoOfferRepository.key(TrainingCourse.pilares),
        '{{',
      );
      final back = await LocalDemoOfferRepository(
        PreferencesService(),
        FakeNow(day),
      ).load(TrainingCourse.pilares);
      expect(back.count, 0);
    });
  });
}
