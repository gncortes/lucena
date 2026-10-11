import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/talk_repository.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/use_cases/game_events.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'o tour começa por ver e o passo e o degrau voltam ao reabrir',
    () async {
      LocalOnboardingRepository reopen() =>
          LocalOnboardingRepository(PreferencesService());

      expect(await reopen().load(), const Onboarding());
      await reopen().save(const Onboarding(step: 3));
      expect((await reopen().load()).step, 3);
      await reopen().save(const Onboarding(done: true, startRung: '1400'));
      expect(
        await reopen().load(),
        const Onboarding(done: true, startRung: '1400'),
      );
    },
  );

  test(
    'escolha explícita e replay persistem, e escolha pode ser limpa',
    () async {
      final repository = LocalOnboardingRepository(PreferencesService());
      const choice = Onboarding(
        done: true,
        step: 12,
        selectedRating: 1530,
        byHand: false,
        inProgress: true,
      );
      await repository.save(choice);
      expect(
        await LocalOnboardingRepository(PreferencesService()).load(),
        choice,
      );
      await repository.save(
        choice.copyWith(selectedRating: () => null, byHand: true),
      );
      final loaded = await repository.load();
      expect(loaded.selectedRating, isNull);
      expect(loaded.byHand, isTrue);
      expect(loaded.done, isTrue);
      expect(loaded.inProgress, isTrue);
    },
  );

  test('done legado não exige novo onboarding nem infere escolha', () async {
    final preferences = PreferencesService();
    await preferences.setBool('tour.done', value: true);
    final loaded = await LocalOnboardingRepository(preferences).load();
    expect(loaded.done, isTrue);
    expect(loaded.selectedRating, isNull);
    expect(loaded.inProgress, isFalse);
  });

  test('a memória do personagem volta com a partida', () async {
    final snapshot = TalkSnapshot(
      gameStartedAt: DateTime.utc(2026, 10, 4, 12),
      plies: 5,
      memory: const TalkMemory(
        scores: [10, -300],
        spoken: ['magician.gameStart.1'],
        emotion: Emotion.nervous,
      ),
      lineId: 'magician.gameStart.1',
    );
    await LocalTalkRepository(PreferencesService()).save(snapshot);
    final loaded = await LocalTalkRepository(PreferencesService()).load();

    expect(loaded!.gameStartedAt, snapshot.gameStartedAt);
    expect(loaded.plies, 5);
    expect(loaded.memory, snapshot.memory);
    expect(loaded.lineId, 'magician.gameStart.1');
  });
}
