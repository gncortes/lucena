import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

/// Tela de perfil, o painel de faixas de rating e o resumo em Configurações.
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
    await $(ProfileKeys.levelField).waitUntilVisible();
  }

  Future<void> enterNickname(String text) async {
    await $(ProfileKeys.nicknameField).enterText(text);
  }

  /// Abre o painel de faixas de rating.
  Future<void> openLevels() async {
    await $(ProfileKeys.levelField).tap();
    await $(ProfileKeys.levelSheet).waitUntilVisible();
  }

  /// Marca uma faixa no painel aberto; ela só vale depois de confirmar.
  Future<void> markLevel(RatingLevel level) async {
    await $(ProfileKeys.levelOption(level))
        .scrollTo(
          view: find.descendant(
            of: find.byKey(ProfileKeys.levelSheet),
            matching: find.byType(Scrollable),
          ),
        )
        .tap();
  }

  /// Abre o painel, marca a faixa e confirma; o painel fecha.
  Future<void> chooseLevel(RatingLevel level) async {
    await openLevels();
    await markLevel(level);
    await $(ProfileKeys.levelConfirmButton).tap();
    await $.pumpAndSettle();
  }

  /// Fecha o painel tocando fora dele, sem confirmar.
  Future<void> dismissLevels() async {
    await $.tester.tapAt(const Offset(20, 100));
    await $.pumpAndSettle();
  }

  /// Um texto (nome ou intervalo de uma faixa) aparece no painel.
  void expectInLevels(String text) {
    expect(
      find.descendant(
        of: find.byKey(ProfileKeys.levelSheet),
        matching: find.text(text),
      ),
      findsOneWidget,
    );
  }

  /// Salvar volta para Configurações.
  Future<void> save() async {
    await $(ProfileKeys.saveButton).scrollTo().tap();
    await $.pumpAndSettle();
  }

  void expectFields({required String nickname, required String level}) {
    final field = $.tester.widget<TextField>(
      find.byKey(ProfileKeys.nicknameField),
    );
    expect(field.controller!.text, nickname);
    expect(_text(ProfileKeys.levelName), level);
  }

  /// O resumo "apelido · faixa" na tela de Configurações.
  Future<void> expectSummary(String text) async {
    await $(SettingsKeys.profileValue).waitUntilVisible();
    expect(_text(SettingsKeys.profileValue), text);
  }

  String? _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data;
}
