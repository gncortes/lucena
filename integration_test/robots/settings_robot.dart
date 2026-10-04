import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

/// Telas de Configurações, de idioma e de tema.
class SettingsRobot {
  const SettingsRobot(this.$);

  final PatrolIntegrationTester $;

  Future<void> expectVisible() async {
    await $(SettingsKeys.screen).waitUntilVisible();
  }

  void expectTitle(String text) {
    expect($.tester.widget<Text>(find.byKey(SettingsKeys.title)).data, text);
  }

  void expectLanguageValue(String text) {
    expect(
      $.tester.widget<Text>(find.byKey(SettingsKeys.languageValue)).data,
      text,
    );
  }

  Future<void> openLanguages() async {
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
    expect(
      $.tester.widget<Text>(find.byKey(SettingsKeys.themeValue)).data,
      text,
    );
  }

  Future<void> openThemes() async {
    await $(SettingsKeys.themeTile).tap();
    await $(SettingsKeys.themeScreen).waitUntilVisible();
  }

  Future<void> expectThemesVisible() async {
    await $(SettingsKeys.themeScreen).waitUntilVisible();
  }

  Future<void> chooseTheme(AppThemeMode mode) async {
    await $(SettingsKeys.themeOption(mode)).tap();
  }

  Future<void> expectBoardAppearanceValue(String text) async {
    await $(SettingsKeys.boardAppearanceValue).scrollTo();
    expect(
      $.tester.widget<Text>(find.byKey(SettingsKeys.boardAppearanceValue)).data,
      text,
    );
  }

  /// Volta uma tela pela seta da barra superior.
  Future<void> back() async {
    await $(BackButton).tap();
  }
}
