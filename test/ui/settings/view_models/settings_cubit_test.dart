import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';

import 'package:lucena/domain/models/game_sound.dart';

import '../../../../testing/fakes/fake_sound_repository.dart';

void main() {
  late FakeSettingsRepository repository;

  SettingsCubit build() =>
      SettingsCubit(repository, languages: AppLanguage.selectable);

  setUp(() => repository = FakeSettingsRepository());

  test('começa sem estado até ler as preferências', () {
    expect(build().state, isNull);
  });

  blocTest<SettingsCubit, AppSettings?>(
    'carrega o idioma gravado',
    setUp: () => repository.settings = const AppSettings(languageCode: 'fr'),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const AppSettings(languageCode: 'fr')],
  );

  blocTest<SettingsCubit, AppSettings?>(
    'trocar a cor do app muda o estado na hora e grava, sem mexer no tema',
    setUp: () =>
        repository.settings = const AppSettings(themeMode: AppThemeMode.dark),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setAccent(AppAccent.purple);
    },
    expect: () => [
      const AppSettings(themeMode: AppThemeMode.dark),
      const AppSettings(themeMode: AppThemeMode.dark, accent: AppAccent.purple),
    ],
    verify: (_) => expect(repository.saved, [
      const AppSettings(themeMode: AppThemeMode.dark, accent: AppAccent.purple),
    ]),
  );

  blocTest<SettingsCubit, AppSettings?>(
    'trocar o idioma muda o estado na hora e grava',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setLanguage(AppLanguage.spanish);
    },
    expect: () => [const AppSettings(), const AppSettings(languageCode: 'es')],
    verify: (_) =>
        expect(repository.saved, [const AppSettings(languageCode: 'es')]),
  );

  blocTest<SettingsCubit, AppSettings?>(
    'voltar para o idioma do sistema limpa a escolha e grava',
    setUp: () => repository.settings = const AppSettings(languageCode: 'ar'),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setLanguage(null);
    },
    expect: () => [const AppSettings(languageCode: 'ar'), const AppSettings()],
    verify: (_) => expect(repository.saved, [const AppSettings()]),
  );

  blocTest<SettingsCubit, AppSettings?>(
    'trocar o tema muda o estado na hora, grava e mantém o idioma',
    setUp: () => repository.settings = const AppSettings(languageCode: 'ar'),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setThemeMode(AppThemeMode.dark);
    },
    expect: () => [
      const AppSettings(languageCode: 'ar'),
      const AppSettings(languageCode: 'ar', themeMode: AppThemeMode.dark),
    ],
    verify: (_) => expect(repository.saved, [
      const AppSettings(languageCode: 'ar', themeMode: AppThemeMode.dark),
    ]),
  );

  blocTest<SettingsCubit, AppSettings?>(
    'trocar o idioma mantém o tema escolhido',
    setUp: () =>
        repository.settings = const AppSettings(themeMode: AppThemeMode.dark),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setLanguage(AppLanguage.spanish);
    },
    skip: 1,
    expect: () => [
      const AppSettings(languageCode: 'es', themeMode: AppThemeMode.dark),
    ],
  );

  blocTest<SettingsCubit, AppSettings?>(
    'trocar as peças muda o estado na hora, grava e mantém o resto',
    setUp: () => repository.settings = const AppSettings(languageCode: 'ar'),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setBoard(const BoardSettings(pieces: PieceStyle.merida));
    },
    skip: 1,
    expect: () => [
      const AppSettings(
        languageCode: 'ar',
        board: BoardSettings(pieces: PieceStyle.merida),
      ),
    ],
    verify: (cubit) => expect(repository.saved, [cubit.state]),
  );

  blocTest<SettingsCubit, AppSettings?>(
    'restaurar a aparência do tabuleiro volta ao padrão e grava',
    setUp: () => repository.settings = const AppSettings(
      themeMode: AppThemeMode.dark,
      board: BoardSettings(
        colors: BoardColors.brown,
        pieces: PieceStyle.pixel,
        coordinates: false,
      ),
    ),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.resetBoardAppearance();
    },
    skip: 1,
    expect: () => [const AppSettings(themeMode: AppThemeMode.dark)],
    verify: (cubit) => expect(repository.saved, [cubit.state]),
  );

  group('sons', () {
    test('desligar grava a escolha e não toca nada', () async {
      final repository = FakeSettingsRepository();
      final sound = FakeSoundRepository();
      final cubit = SettingsCubit(
        repository,
        languages: AppLanguage.selectable,
        sound: sound,
      );
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.setSound(enabled: false);

      expect(cubit.state!.sound, isFalse);
      expect(repository.saved.last.sound, isFalse);
      expect(sound.played, isEmpty);
    });

    test(
      'ligar grava a escolha e toca o som de um lance, de amostra',
      () async {
        final repository = FakeSettingsRepository(
          const AppSettings(sound: false),
        );
        final sound = FakeSoundRepository();
        final cubit = SettingsCubit(
          repository,
          languages: AppLanguage.selectable,
          sound: sound,
        );
        addTearDown(cubit.close);
        await cubit.load();

        await cubit.setSound(enabled: true);

        expect(repository.saved.last.sound, isTrue);
        expect(sound.played, [GameSound.move]);
      },
    );
  });
}
