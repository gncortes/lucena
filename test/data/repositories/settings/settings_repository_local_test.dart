import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/settings/settings_repository_local.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  // Cada chamada cria repositório e serviço novos, como ao reabrir o app.
  LocalSettingsRepository reopen() =>
      LocalSettingsRepository(PreferencesService());

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('sem nada gravado, segue o idioma do sistema', () async {
    expect(await reopen().load(), const AppSettings());
  });

  test('o idioma gravado volta ao reabrir', () async {
    await reopen().save(const AppSettings(languageCode: 'es'));

    expect(await reopen().load(), const AppSettings(languageCode: 'es'));
  });

  test('voltar para o idioma do sistema apaga o idioma gravado', () async {
    await reopen().save(const AppSettings(languageCode: 'ar'));
    await reopen().save(const AppSettings());

    expect(await reopen().load(), const AppSettings());
  });

  test('sem nada gravado, o tema segue o aparelho', () async {
    expect((await reopen().load()).themeMode, AppThemeMode.system);
  });

  test('o tema gravado volta ao reabrir, junto com o idioma', () async {
    const settings = AppSettings(
      languageCode: 'ar',
      themeMode: AppThemeMode.dark,
    );
    await reopen().save(settings);

    expect(await reopen().load(), settings);
  });

  test('voltar o tema para o do aparelho também é gravado', () async {
    await reopen().save(const AppSettings(themeMode: AppThemeMode.dark));
    await reopen().save(const AppSettings());

    expect(await reopen().load(), const AppSettings());
  });

  test(
    'sem nada gravado, o tabuleiro vem com a aparência de fábrica',
    () async {
      expect((await reopen().load()).board, const BoardSettings());
    },
  );

  test('cores, peças e coordenadas do tabuleiro voltam ao reabrir', () async {
    const settings = AppSettings(
      board: BoardSettings(
        colors: BoardColors.green,
        pieces: PieceStyle.merida,
        coordinates: false,
      ),
    );
    await reopen().save(settings);

    expect(await reopen().load(), settings);
  });

  test('o comportamento do tabuleiro volta ao reabrir', () async {
    const settings = AppSettings(
      board: BoardSettings(
        moveMethod: MoveMethod.tap,
        showLegalMoves: false,
        highlightLastMove: false,
        animation: false,
        premoves: false,
        notation: MoveNotation.letters,
      ),
    );
    await reopen().save(settings);

    expect(await reopen().load(), settings);
  });

  test('as preferências do relógio voltam ao reabrir', () async {
    expect((await reopen().load()).clock, const ClockSettings());

    const settings = AppSettings(
      clock: ClockSettings(
        position: ClockPosition.bottom,
        lowTimeVibration: false,
      ),
    );
    await reopen().save(settings);

    expect(await reopen().load(), settings);
  });

  test('o último ritmo do speedrun e o da Jornada voltam ao reabrir', () async {
    final start = (await reopen().load()).clock;
    expect(start.speedrunTime, SpeedrunPaces.standard);
    expect(start.journeyTime, isNull);

    const settings = AppSettings(
      clock: ClockSettings(
        speedrunTime: TimeControl(
          initial: Duration(minutes: 3),
          increment: Duration(seconds: 2),
        ),
        journeyTime: TimeControl(initial: Duration(minutes: 10)),
      ),
    );
    await reopen().save(settings);
    expect(await reopen().load(), settings);

    // Voltar para "sem relógio" na Jornada também fica gravado.
    await reopen().save(const AppSettings());
    expect((await reopen().load()).clock.journeyTime, isNull);
  });

  test(
    'falas dos personagens: ligadas de fábrica, desligar fica gravado',
    () async {
      expect((await reopen().load()).characterTalk, isTrue);
      await reopen().save(const AppSettings(characterTalk: false));
      expect((await reopen().load()).characterTalk, isFalse);
    },
  );
}
