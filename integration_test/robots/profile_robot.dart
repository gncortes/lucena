import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

/// Tela de perfil e o resumo dela em Configurações.
class ProfileRobot {
  const ProfileRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir de Configurações.
  Future<void> open() async {
    await $(SettingsKeys.profileTile).tap();
    await expectVisible();
  }

  Future<void> expectVisible() async {
    await $(ProfileKeys.screen).waitUntilVisible();
    await $(ProfileKeys.saveButton).waitUntilVisible();
  }

  Future<void> enterNickname(String text) async {
    await $(ProfileKeys.nicknameField).enterText(text);
  }

  Future<void> enterRating(String text) async {
    await $(ProfileKeys.ratingField).enterText(text);
  }

  /// Salvar com dados válidos volta para Configurações.
  Future<void> save() async {
    await $(ProfileKeys.saveButton).scrollTo().tap();
    await $.pumpAndSettle();
  }

  void expectFields({required String nickname, required String rating}) {
    expect(_field(ProfileKeys.nicknameField).controller!.text, nickname);
    expect(_field(ProfileKeys.ratingField).controller!.text, rating);
  }

  void expectRatingError(String text) {
    expect(_field(ProfileKeys.ratingField).decoration!.errorText, text);
  }

  /// O resumo "apelido · rating" na tela de Configurações.
  Future<void> expectSummary(String text) async {
    await $(SettingsKeys.profileValue).waitUntilVisible();
    expect(
      $.tester.widget<Text>(find.byKey(SettingsKeys.profileValue)).data,
      text,
    );
  }

  TextField _field(Key key) => $.tester.widget<TextField>(find.byKey(key));
}
