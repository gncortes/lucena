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
        step: 5,
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

  test('o "Antes do desafio" feito persiste ao reabrir', () async {
    final repository = LocalOnboardingRepository(PreferencesService());
    await repository.save(const Onboarding(linkSetupDone: true));
    final loaded = await LocalOnboardingRepository(PreferencesService()).load();
    expect(loaded.linkSetupDone, isTrue);
    expect(loaded.done, isFalse);
  });

  test('done legado não exige novo onboarding nem infere escolha', () async {
    final preferences = PreferencesService();
    await preferences.setBool('tour.done', value: true);
    final loaded = await LocalOnboardingRepository(preferences).load();
    expect(loaded.done, isTrue);
    expect(loaded.selectedRating, isNull);
    expect(loaded.inProgress, isFalse);
  });

  test(
    'o passo do tour antigo migra para a chave nova e a velha some',
    () async {
      Future<int> migrated(String? legacy) async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final preferences = PreferencesService();
        if (legacy != null) await preferences.setString('tour.step', legacy);
        final step = (await LocalOnboardingRepository(preferences).load()).step;
        expect(await preferences.getString('tour.step'), isNull);
        return step;
      }

      expect(await migrated(null), 0);
      expect(await migrated('3'), 0);
      expect(await migrated('11'), 0);
      expect(await migrated('12'), 4);
      expect(await migrated('13'), 4);
    },
  );

  test('a chave nova vale e não é sobrescrita pela antiga', () async {
    final preferences = PreferencesService();
    await preferences.setString('tour.step', '12');
    await preferences.setString('tour.stepV2', '2');
    final repository = LocalOnboardingRepository(preferences);
    expect((await repository.load()).step, 2);
    await repository.save(const Onboarding(step: 4));
    expect(await preferences.getString('tour.stepV2'), '4');
    expect((await repository.load()).step, 4);
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
