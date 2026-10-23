import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/settings/settings_repository_local.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/endgame_filter.dart';
import 'package:lucena/domain/models/history_filter.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/rating_period.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena_ui/lucena_ui.dart';
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

  test('sem nada gravado, nenhuma cor do app está escolhida', () async {
    expect((await reopen().load()).accent, isNull);
  });

  test('a cor do app gravada volta ao reabrir, junto com o tema', () async {
    const settings = AppSettings(
      themeMode: AppThemeMode.dark,
      accent: AppAccent.pink,
    );
    await reopen().save(settings);

    expect(await reopen().load(), settings);
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

  test('o último ritmo do speedrun, o da Maratona e o da Jornada voltam ao '
      'reabrir', () async {
    final start = (await reopen().load()).clock;
    // Nada escolhido ainda: o speedrun abre no ritmo do nível do jogador.
    expect(start.speedrunTime, isNull);
    expect(start.marathonTime, isNull);
    expect(start.journeyTime, isNull);

    const settings = AppSettings(
      clock: ClockSettings(
        speedrunTime: TimeControl(
          initial: Duration(minutes: 3),
          increment: Duration(seconds: 2),
        ),
        marathonTime: TimeControl(initial: Duration(seconds: 30)),
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

  test('os filtros das aulas de finais voltam ao reabrir', () async {
    expect((await reopen().load()).endgamesFilter, const EndgameFilter());
    const filter = EndgameFilter(
      kinds: {EndgameKind.rook, EndgameKind.pawn},
      levels: {RatingLevel.intermediate},
      statuses: {EndgameLessonStatus.open},
      sort: EndgameSort.easiest,
    );
    await reopen().save(const AppSettings(endgamesFilter: filter));
    expect((await reopen().load()).endgamesFilter, filter);
  });

  test('sons: ligados de fábrica, desligar fica gravado', () async {
    expect((await reopen().load()).sound, isTrue);
    await reopen().save(const AppSettings(sound: false));
    expect((await reopen().load()).sound, isFalse);
  });

  test('vibração: ligada de fábrica, desligar fica gravado', () async {
    expect((await reopen().load()).vibration, isTrue);
    await reopen().save(const AppSettings(vibration: false));
    expect((await reopen().load()).vibration, isFalse);
  });

  test('o tempo de pensar gravado antes da T60 é ignorado sem erro', () async {
    await PreferencesService().setString('lessons.thinkMinutes', '5');
    await PreferencesService().setBool('lessons.thinkChosen', value: true);

    final loaded = await reopen().load();
    expect(loaded, const AppSettings());
  });

  test('a aba e os filtros do Histórico voltam ao reabrir', () async {
    const saved = AppSettings(
      historyTab: HistoryTab.marathon,
      historyGamesFilter: GamesHistoryFilter(
        period: RatingPeriod.week,
        result: AttemptOutcome.loss,
        pace: GamesHistoryFilter.noClock,
      ),
      historyClassicFilter: SpeedrunHistoryFilter(pace: PaceCategory.blitz),
      historyMarathonFilter: SpeedrunHistoryFilter(
        level: SpeedrunCategory.advanced,
      ),
    );
    await reopen().save(saved);

    expect(await reopen().load(), saved);
  });

  test(
    'lances ocultos (T69): ligado por padrão, e o valor volta ao reabrir',
    () async {
      expect((await reopen().load()).lessonHiddenMoves, isTrue);
      await reopen().save(const AppSettings(lessonHiddenMoves: false));
      expect((await reopen().load()).lessonHiddenMoves, isFalse);
      await reopen().save(const AppSettings());
      expect((await reopen().load()).lessonHiddenMoves, isTrue);
    },
  );
}
