import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// O Perfil (E1.11), "Seus dados", "Seu nível" aberto por ele e o resumo em
/// Configurações.
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
    await $(ProfileKeys.rowLevel).waitUntilVisible();
  }

  /// Abre "Seus dados" pelo lápis do cabeçalho.
  Future<void> openData() async {
    await $(ProfileKeys.editData).tap();
    await $(AccountKeys.dataScreen).waitUntilVisible();
  }

  /// Em "Seus dados" (abre, se preciso), troca o apelido.
  Future<void> enterNickname(String text) async {
    if (!$(AccountKeys.dataScreen).exists) await openData();
    await $(AccountKeys.nickname).enterText(text);
  }

  /// "Salvar" em "Seus dados": volta para o Perfil.
  Future<void> saveData() async {
    await $(AccountKeys.dataSave).scrollTo().tap();
    await $.pumpAndSettle();
    await expectVisible();
  }

  /// "Nível" abre "Seu nível"; "Informar o meu rating" com o rating da
  /// faixa (como do Lichess, que não converte) volta para o Perfil, gravado.
  Future<void> chooseLevel(RatingLevel level) async {
    await $(ProfileKeys.rowLevel).scrollTo().tap();
    await $(LevelKeys.screen).waitUntilVisible();
    await _tap(LevelKeys.option(LevelChoice.manual));
    await _tap(LevelKeys.continueButton);
    await $(LevelKeys.ratingScreen).waitUntilVisible();
    await $(LevelKeys.ratingField).enterText(level.rating.toString());
    await $(LevelKeys.ratingSource(RatingOrigin.lichess)).scrollTo().tap();
    await $(LevelKeys.ratingUse).tap();
    await $.pumpAndSettle();
    await expectVisible();
  }

  /// "Nível" e, em "Seu nível", o teste de nível.
  Future<void> openPlacement() async {
    await $(ProfileKeys.rowLevel).scrollTo().tap();
    await $(LevelKeys.screen).waitUntilVisible();
    await _tap(LevelKeys.option(LevelChoice.test));
    await _tap(LevelKeys.continueButton);
  }

  /// "Seu objetivo": abre a folha, marca [goal] e salva (grava na hora).
  Future<void> chooseGoal(GoalPreference goal) async {
    await $(ProfileKeys.rowGoal).scrollTo().tap();
    await $(GoalKeys.sheet).waitUntilVisible();
    await $(GoalKeys.option(goal)).tap();
    await $(GoalKeys.sheetSave).tap();
    await $.pumpAndSettle();
  }

  /// O voltar do Perfil: Configurações.
  Future<void> close() async {
    await $(BackButton).tap();
    await $.pumpAndSettle();
    await $(SettingsKeys.screen).waitUntilVisible();
  }

  /// O nome do cabeçalho e o rating na linha "Nível".
  void expectFields({required String name, required int rating}) {
    expectText(_text(ProfileKeys.headerName), name);
    expect(
      find.descendant(
        of: find.byKey(ProfileKeys.rowLevel),
        matching: find.textContaining('$rating'),
      ),
      findsOneWidget,
    );
  }

  /// O resumo "apelido · faixa" na tela de Configurações.
  Future<void> expectSummary(String text) async {
    await $(SettingsKeys.profileValue).waitUntilVisible();
    expectText(_text(SettingsKeys.profileValue), text);
  }

  // As opções de "Seu nível" rolam: traz a opção para a tela antes de tocar.
  Future<void> _tap(Key key) async {
    await $(key).scrollTo();
    await $.tester.ensureVisible(find.byKey(key));
    await $.pumpAndSettle();
    await $(key).tap();
    await $.pumpAndSettle();
  }

  String? _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data;
}
