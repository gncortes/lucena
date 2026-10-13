import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/talk_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/use_cases/game_events.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  LocalTalkRepository reopen() => LocalTalkRepository(PreferencesService());
  final started = DateTime.utc(2026, 10, 12);

  test('snapshot antigo mantém compatibilidade sem fechamentos nem dica', () {
    final loaded = TalkSnapshot.fromJson({
      'game': started.toIso8601String(),
      'plies': 0,
      'memory': TalkMemory.empty.toJson(),
      'line': 'hello',
    })!;
    expect(loaded.lineId, 'hello');
    expect(loaded.dismissedLineIds, isEmpty);
    expect(loaded.speechHintShown, isFalse);
  });

  test('fechamentos e balão fechado sobrevivem à reabertura', () async {
    await reopen().save(
      TalkSnapshot(
        gameStartedAt: started,
        plies: 5,
        memory: TalkMemory.empty,
        dismissedLineIds: const ['first', 'second', 'third'],
        speechHintShown: true,
      ),
    );
    final loaded = (await reopen().load())!;
    expect(loaded.lineId, isNull);
    expect(loaded.dismissedLineIds, ['first', 'second', 'third']);
    expect(loaded.speechHintShown, isTrue);
  });

  test(
    'intervalo global permanece ao substituir snapshot de outra partida',
    () async {
      expect(await reopen().loadSpeechHintShownAt(), isNull);
      await reopen().saveSpeechHintShownAt(started);
      await reopen().save(
        TalkSnapshot(
          gameStartedAt: started.add(const Duration(days: 1)),
          plies: 0,
          memory: TalkMemory.empty,
        ),
      );
      expect(await reopen().loadSpeechHintShownAt(), started);
      expect((await reopen().load())!.dismissedLineIds, isEmpty);
    },
  );

  test('timestamp inválido não impede a próxima dica', () async {
    await PreferencesService().setString('talk.speechHint.shownAt', 'invalid');
    expect(await reopen().loadSpeechHintShownAt(), isNull);
  });
}
