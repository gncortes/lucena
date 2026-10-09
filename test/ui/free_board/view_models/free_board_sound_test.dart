import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_sound.dart';
import 'package:lucena/domain/models/haptic_event.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/sound/game_sounds.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';

import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_opponent_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_sound_repository.dart';

void main() {
  late FakeNow now;
  late FakeSettingsRepository settings;
  late FakeSoundRepository sound;
  late FakeHapticsRepository haptics;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    settings = FakeSettingsRepository();
    sound = FakeSoundRepository();
    haptics = FakeHapticsRepository();
  });

  FreeBoardCubit build({Position? start, ClockConfig? clock}) {
    final cubit = FreeBoardCubit(
      now: now,
      haptics: haptics,
      settings: settings,
      games: FakeOngoingGameRepository(),
      opponent: FakeOpponentRepository(now: now),
      progress: FakeProgressRepository(),
      sounds: GameSounds(settings, sound),
      start: start ?? GameRules.initial,
      clock: clock,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('cada lance vibra: lance, captura e xeque', () async {
    final cubit = build();
    for (final uci in ['e2e4', 'd7d5', 'e4d5', 'd8d5', 'f1b5']) {
      cubit.play(NormalMove.fromUci(uci));
    }
    await settle();
    expect(haptics.events, [
      HapticEvent.move,
      HapticEvent.move,
      HapticEvent.capture,
      HapticEvent.capture,
      HapticEvent.check,
    ]);
  });

  test('com a vibração desligada, nenhum lance vibra', () async {
    settings.settings = const AppSettings(vibration: false);
    final cubit = build();
    cubit.play(NormalMove.fromUci('e2e4'));
    await settle();
    expect(haptics.events, isEmpty);
  });

  test('cada lance faz o seu som: lance, captura e xeque', () async {
    final cubit = build();
    for (final uci in ['e2e4', 'd7d5', 'e4d5', 'd8d5', 'f1b5']) {
      cubit.play(NormalMove.fromUci(uci));
    }
    await settle();
    expect(sound.played, [
      GameSound.move,
      GameSound.move,
      GameSound.capture,
      GameSound.capture,
      GameSound.check,
    ]);
  });

  test('lance ilegal não faz som', () async {
    final cubit = build();
    cubit.play(NormalMove.fromUci('e2e5'));
    await settle();
    expect(sound.played, isEmpty);
  });

  test('com os sons desligados, o lance não faz som', () async {
    settings.settings = const AppSettings(sound: false);
    final cubit = build();
    cubit.play(NormalMove.fromUci('e2e4'));
    await settle();
    expect(sound.played, isEmpty);
  });

  test('o relógio avisa uma vez quando o tempo fica curto', () async {
    const fifteen = TimeControl(initial: Duration(seconds: 15));
    final cubit = build(clock: ClockConfig.same(fifteen));
    cubit.play(NormalMove.fromUci('e2e4'));
    await settle();
    sound.played.clear();

    now.advance(const Duration(seconds: 4));
    cubit.tick();
    await settle();
    expect(sound.played, isEmpty);

    now.advance(const Duration(seconds: 2));
    cubit.tick();
    now.advance(const Duration(seconds: 1));
    cubit.tick();
    await settle();
    expect(sound.played, [GameSound.lowTime]);
  });
}
