import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

import 'conclusion_robot.dart';
import 'variant.dart';

/// O que o jogador acumula: o rating, as mensagens da conclusão da partida e
/// as conquistas.
class ProgressRobot {
  const ProgressRobot(this.$);

  final PatrolIntegrationTester $;

  /// O rating no perfil, a partir da tela inicial (e volta para ela).
  Future<int> rating() async {
    await $(HomeKeys.settingsButton).tap();
    await $(SettingsKeys.profileTile).tap();
    await $(ProfileKeys.ratingValue).scrollTo();
    final value = $.tester
        .widget<Text>(find.byKey(ProfileKeys.ratingValue))
        .data!;
    await _backHome();
    return int.parse(value);
  }

  /// No perfil: quantas partidas contaram para o rating.
  Future<void> expectRatedGames(String text) async {
    await $(HomeKeys.settingsButton).tap();
    await $(SettingsKeys.profileTile).tap();
    await $(ProfileKeys.ratingGames).scrollTo();
    expectText(
      $.tester.widget<Text>(find.byKey(ProfileKeys.ratingGames)).data,
      text,
    );
    await _backHome();
  }

  /// Na conclusão da partida, o rating com a variação.
  Future<void> expectRatingChanged() =>
      ConclusionRobot($).expectRatingChanged();

  /// As mensagens da conclusão da partida, em ordem.
  Future<List<String>> feedback() => ConclusionRobot($).feedback();

  /// O aviso de conquista desbloqueada por cima da tela, com o nome dela;
  /// depois ele some sozinho.
  Future<void> expectAchievementToast(String title) async {
    // O aviso não recebe toques: basta existir na tela.
    await $(AchievementsKeys.toast).waitUntilExists();
    expectText(
      $.tester.widget<Text>(find.byKey(AchievementsKeys.toastTitle)).data,
      title,
    );
    await $.pumpAndSettle();
    expect(find.byKey(AchievementsKeys.toast), findsNothing);
  }

  /// Toca no aviso de conquista enquanto ele está na tela e espera o
  /// detalhe dela abrir (T51, A6).
  Future<void> tapAchievementToast() async {
    await $(AchievementsKeys.toast).waitUntilVisible();
    await $.tester.tap(find.byKey(AchievementsKeys.toast));
    await $(AchievementsKeys.detail).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// Na lista de conquistas, abre o detalhe de [id].
  Future<void> openAchievement(String id) async {
    await $(AchievementsKeys.item(id)).scrollTo().tap();
    await $(AchievementsKeys.detail).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// O detalhe aberto é o de uma conquista obtida, com o nome [title] e a
  /// data completa.
  Future<void> expectDetailUnlocked(String title) async {
    await $(AchievementsKeys.detailDate).waitUntilVisible();
    expectText(
      $.tester.widget<Text>(find.byKey(AchievementsKeys.detailTitle)).data,
      title,
    );
    expect(find.byKey(AchievementsKeys.detailShortcut), findsNothing);
  }

  /// O detalhe aberto é o de uma que falta, com o atalho [shortcut].
  Future<void> expectDetailLocked(String shortcut) async {
    await $(AchievementsKeys.detailShortcut).waitUntilVisible();
    expect(find.byKey(AchievementsKeys.detailDate), findsNothing);
    expectTextIn(find.byKey(AchievementsKeys.detailShortcut), shortcut);
  }

  /// "Ver a partida" no detalhe: abre a revisão da partida de origem.
  Future<void> openDetailGame() async {
    await $(AchievementsKeys.detailOpenGame).scrollTo().tap();
    await $(GameDetailsKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// O atalho do detalhe de uma que falta.
  Future<void> tapDetailShortcut() async {
    await $(AchievementsKeys.detailShortcut).scrollTo().tap();
    await $.pumpAndSettle();
    expect(find.byKey(AchievementsKeys.detail), findsNothing);
  }

  /// Os detalhes do rating, a partir do cartão do jogador na tela inicial.
  Future<void> openRatingDetails() async {
    await $(HomeKeys.playerCard).scrollTo().tap();
    await $(RatingKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// Nos detalhes do rating: o gráfico e [games] partidas no histórico, a
  /// mais recente com a variação [latestChange] (`+` ou `−`).
  Future<void> expectRatingHistory(int games, {String? latestChange}) async {
    await $(RatingKeys.chart).waitUntilVisible();
    await $(RatingKeys.entry(games - 1)).scrollTo();
    expect(find.byKey(RatingKeys.entry(games)), findsNothing);
    if (latestChange != null) {
      await $(RatingKeys.entryChange(0)).scrollTo();
      expect(
        $.tester.widget<Text>(find.byKey(RatingKeys.entryChange(0))).data,
        startsWith(latestChange),
      );
    }
  }

  /// Sem partidas que contaram: o convite no lugar do histórico.
  Future<void> expectRatingHistoryEmpty() async {
    await $(RatingKeys.emptyHistory).scrollTo();
    expect(find.byKey(RatingKeys.chart), findsNothing);
  }

  Future<void> closeRatingDetails() async {
    await $(BackButton).tap();
    await $.pumpAndSettle();
  }

  Future<void> openAchievements() async {
    await $(HomeKeys.achievementsButton).tap();
    await $(AchievementsKeys.screen).waitUntilVisible();
  }

  Future<void> expectUnlocked(String id) async {
    await $(AchievementsKeys.unlockedOn(id)).scrollTo();
  }

  Future<void> expectLocked(String id) async {
    await $(AchievementsKeys.locked(id)).scrollTo();
  }

  Future<void> _backHome() async {
    while (find.byKey(HomeKeys.screen).hitTestable().evaluate().isEmpty) {
      await $(BackButton).tap();
      await $.pumpAndSettle();
    }
  }
}
