import 'package:flutter/widgets.dart';

import '../../../domain/models/app_accent.dart';
import '../../../domain/models/app_theme_mode.dart';

abstract final class SettingsKeys {
  static const screen = Key('settings.screen');
  static const version = Key('settings.version');
  static const title = Key('settings.title');
  static const profileTile = Key('settings.profile');
  static const profileValue = Key('settings.profile.value');

  static const languageTile = Key('settings.language');
  static const languageValue = Key('settings.language.value');

  static const languageScreen = Key('settings.language.screen');
  static const languageSystem = Key('settings.language.option.system');

  /// Opção de um idioma na tela de idioma, pelo código (`es`, `pt_PT`).
  static Key languageOption(String code) =>
      Key('settings.language.option.$code');

  static const themeTile = Key('settings.theme');
  static const themeValue = Key('settings.theme.value');
  static const themeScreen = Key('settings.theme.screen');

  /// Opção de um tema na tela de tema.
  static Key themeOption(AppThemeMode mode) =>
      Key('settings.theme.option.${mode.code}');

  /// Cor do app na tela de tema, e o nome da cor escolhida.
  static Key accentOption(AppAccent accent) =>
      Key('settings.theme.accent.${accent.code}');
  static const accentValue = Key('settings.theme.accent.value');

  static const boardAppearanceTile = Key('settings.boardAppearance');
  static const boardAppearanceValue = Key('settings.boardAppearance.value');

  static const clockTile = Key('settings.clock');
  static const clockValue = Key('settings.clock.value');

  /// Entrada da tela de depuração do Maia (só em build de desenvolvimento).
  static const maiaDebugTile = Key('settings.maiaDebug');
  static const boardBehaviorTile = Key('settings.boardBehavior');
  static const boardBehaviorValue = Key('settings.boardBehavior.value');

  static const characterTalkSwitch = Key('settings.characterTalk');
  static const tourTile = Key('settings.tour');
}
