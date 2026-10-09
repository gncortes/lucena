import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// Telas de Configurações, de idioma e de tema.
class SettingsRobot {
  const SettingsRobot(this.$);

  final PatrolIntegrationTester $;

  Future<void> _openGroup(Key tile, Key screen) async {
    if ($(screen).exists) return;
    // Vindo de outro grupo ou de uma tela folha, volta ao menu principal.
    await backToMenu();
    await $(tile).scrollTo().tap();
    await $(screen).waitUntilVisible();
  }

  /// No menu principal, abre o grupo Aparência (se já não estiver nele).
  Future<void> openAppearance() =>
      _openGroup(SettingsKeys.appearanceTile, SettingsKeys.appearanceScreen);

  /// No menu principal, abre o grupo Jogo (se já não estiver nele).
  Future<void> openGame() =>
      _openGroup(SettingsKeys.gameTile, SettingsKeys.gameScreen);

  /// No menu principal, abre o grupo Som (se já não estiver nele).
  Future<void> openSound() =>
      _openGroup(SettingsKeys.soundTile, SettingsKeys.soundScreen);

  /// No menu principal, abre a tela Sobre (se já não estiver nela).
  Future<void> openAbout() =>
      _openGroup(SettingsKeys.aboutTile, SettingsKeys.aboutScreen);

  /// Volta pela seta até o menu principal das Configurações.
  Future<void> backToMenu() async {
    for (var i = 0; i < 3 && !$(SettingsKeys.screen).exists; i++) {
      await $(BackButton).tap();
      await $.pumpAndSettle();
    }
    await $(SettingsKeys.screen).waitUntilVisible();
  }

  /// Volta pela seta até a tela inicial.
  Future<void> backToHome() async {
    for (var i = 0; i < 5 && !$(HomeKeys.screen).exists; i++) {
      await $(BackButton).tap();
      await $.pumpAndSettle();
    }
    await $(HomeKeys.screen).waitUntilVisible();
  }

  /// Liga ou desliga os sons do jogo.
  Future<void> toggleSound() async {
    await openSound();
    await $(SettingsKeys.soundSwitch).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// O interruptor dos sons está ligado ou desligado.
  Future<void> expectSound({required bool enabled}) async {
    await openSound();
    await $(SettingsKeys.soundSwitch).scrollTo();
    expect(
      $.tester
          .widget<SwitchListTile>(find.byKey(SettingsKeys.soundSwitch))
          .value,
      enabled,
    );
  }

  /// Liga ou desliga a vibração.
  Future<void> toggleVibration() async {
    await openSound();
    await $(SettingsKeys.vibrationSwitch).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// O interruptor da vibração está ligado ou desligado.
  Future<void> expectVibration({required bool enabled}) async {
    await openSound();
    await $(SettingsKeys.vibrationSwitch).scrollTo();
    expect(
      $.tester
          .widget<SwitchListTile>(find.byKey(SettingsKeys.vibrationSwitch))
          .value,
      enabled,
    );
  }

  Future<void> expectVisible() async {
    await $(SettingsKeys.screen).waitUntilVisible();
  }

  void expectTitle(String text) {
    expectText(
      $.tester.widget<Text>(find.byKey(SettingsKeys.title)).data,
      text,
    );
  }

  void expectLanguageValue(String text) {
    expectText(
      $.tester.widget<Text>(find.byKey(SettingsKeys.languageValue)).data,
      text,
    );
  }

  Future<void> openLanguages() async {
    await openAppearance();
    await $(SettingsKeys.languageTile).tap();
    await $(SettingsKeys.languageScreen).waitUntilVisible();
  }

  Future<void> expectLanguagesVisible() async {
    await $(SettingsKeys.languageScreen).waitUntilVisible();
  }

  Future<void> chooseLanguage(AppLanguage language) async {
    await $(SettingsKeys.languageOption(language.code)).scrollTo().tap();
  }

  Future<void> chooseSystemLanguage() async {
    await $(SettingsKeys.languageSystem).scrollTo().tap();
  }

  void expectThemeValue(String text) {
    expectText(
      $.tester.widget<Text>(find.byKey(SettingsKeys.themeValue)).data,
      text,
    );
  }

  Future<void> openThemes() async {
    await openAppearance();
    await $(SettingsKeys.themeTile).tap();
    await $(SettingsKeys.themeScreen).waitUntilVisible();
  }

  Future<void> expectThemesVisible() async {
    await $(SettingsKeys.themeScreen).waitUntilVisible();
  }

  Future<void> chooseTheme(AppThemeMode mode) async {
    await $(SettingsKeys.themeOption(mode)).tap();
  }

  /// Na tela de tema, a cor do app.
  Future<void> chooseAccent(AppAccent accent) async {
    await $(SettingsKeys.accentOption(accent)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  void expectAccentValue(String text) {
    expectText(
      $.tester.widget<Text>(find.byKey(SettingsKeys.accentValue)).data,
      text,
    );
  }

  Future<void> expectBoardAppearanceValue(String text) async {
    await openAppearance();
    await $(SettingsKeys.boardAppearanceValue).scrollTo();
    expectText(
      $.tester.widget<Text>(find.byKey(SettingsKeys.boardAppearanceValue)).data,
      text,
    );
  }

  /// Volta uma tela pela seta da barra superior.
  Future<void> back() async {
    await $(BackButton).tap();
  }
}
