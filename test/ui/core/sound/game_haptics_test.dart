import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/haptic_event.dart';
import 'package:lucena/ui/core/sound/game_haptics.dart';

import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';

void main() {
  late FakeHapticsRepository haptics;

  setUp(() => haptics = FakeHapticsRepository());

  GameHaptics build([AppSettings settings = const AppSettings()]) =>
      GameHaptics(FakeSettingsRepository(settings), haptics);

  test('ligada (o padrão): vibra', () async {
    await build().play(HapticEvent.celebrate);
    expect(haptics.events, [HapticEvent.celebrate]);
  });

  test('desligada: não chama o aparelho', () async {
    final feel = build(const AppSettings(vibration: false));
    for (final event in HapticEvent.values) {
      await feel.play(event);
    }
    await feel.move('Qh5+');
    expect(haptics.events, isEmpty);
  });

  test('o lance vibra como o som: lance, captura e xeque', () async {
    final feel = build();
    for (final san in ['e4', 'exd5', 'Bb5+', 'Qxf7#']) {
      await feel.move(san);
    }
    expect(haptics.events, [
      HapticEvent.move,
      HapticEvent.capture,
      HapticEvent.check,
      HapticEvent.check,
    ]);
  });

  test('o aviso de pouco tempo respeita também a chave do relógio', () async {
    await build(
      const AppSettings(clock: ClockSettings(lowTimeVibration: false)),
    ).play(HapticEvent.warning);
    expect(haptics.events, isEmpty);
  });
}
