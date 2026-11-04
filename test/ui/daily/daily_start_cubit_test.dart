import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/daily_final.dart';
import 'package:lucena/domain/models/maia_level.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/daily/view_models/daily_start_cubit.dart';

import '../../../testing/fakes/fake_daily_final_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';

void main() {
  final now = FakeNow(DateTime(2026, 10, 22, 9));
  final day = DateTime(2026, 10, 22);

  test('início: a partida de hoje no nível da pessoa', () async {
    final rating = FakeRatingRepository();
    final cubit = DailyStartCubit(
      daily: FakeDailyFinalRepository(),
      rating: rating,
      now: now,
    );
    addTearDown(cubit.close);
    await cubit.load();

    final level = MaiaLevels.nearest((await rating.current()).rounded);
    expect(
      cubit.state,
      isA<DailyStartReady>().having(
        (s) => s.location,
        'location',
        Routes.dailyGame(
          DailyFinal(date: day, position: samplePositions.first),
          level: level,
        ),
      ),
    );
  });

  test(
    'início sem final hoje: estado vazio, sem abertura registrada',
    () async {
      final cubit = DailyStartCubit(
        daily: FakeDailyFinalRepository(none: true),
        rating: FakeRatingRepository(),
        now: now,
      );
      addTearDown(cubit.close);
      await cubit.load();

      expect(cubit.state, isA<DailyStartEmpty>());
    },
  );
}
