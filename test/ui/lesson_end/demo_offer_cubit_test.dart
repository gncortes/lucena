import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/demo_offer_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/lesson_end/view_models/demo_offer_cubit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_now.dart';

/// B20/B21: a oferta aparece no máximo 2 vezes, com 3 dias entre elas.
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<bool?> decide(FakeNow now, {bool demo = true}) async {
    final cubit = DemoOfferCubit(
      course: TrainingCourse.pilares,
      repository: LocalDemoOfferRepository(PreferencesService(), now),
      demo: demo,
      now: now,
    );
    await cubit.decide();
    return cubit.state;
  }

  test('duas ofertas com 3 dias entre elas, depois nunca mais', () async {
    final start = DateTime.utc(2026, 11, 4, 10);
    final now = FakeNow(start);
    expect(await decide(now), isTrue);
    expect(await decide(now), isFalse);
    now.value = start.add(const Duration(days: 3));
    expect(await decide(now), isTrue);
    now.value = start.add(const Duration(days: 30));
    expect(await decide(now), isFalse);
  });

  test('comprador nunca vê e não gasta o contador', () async {
    final now = FakeNow(DateTime.utc(2026, 11, 4));
    expect(await decide(now, demo: false), isFalse);
    expect(await decide(now), isTrue);
  });
}
