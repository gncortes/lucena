import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// O que o jogador acumula: o rating, as mensagens do fim da partida e as
/// conquistas.
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

  /// No fim da partida, a linha do rating.
  Future<void> expectRatingChanged() async {
    await $(FreeBoardKeys.ratingValue).waitUntilVisible();
  }

  /// As mensagens do fim da partida, em ordem.
  Future<List<String>> feedback() async {
    await $.pump(const Duration(milliseconds: 500));
    await $.pumpAndSettle();
    final texts = <String>[];
    for (var index = 0; ; index++) {
      final finder = find.byKey(FreeBoardKeys.feedback(index));
      if (finder.evaluate().isEmpty) return texts;
      texts.add(
        $.tester
            .widgetList<Text>(
              find.descendant(of: finder, matching: find.byType(Text)),
            )
            .first
            .data!,
      );
    }
  }

  /// O aviso de conquista desbloqueada por cima da tela, com o nome dela;
  /// depois ele some sozinho.
  Future<void> expectAchievementToast(String title) async {
    await $(AchievementsKeys.toast).waitUntilVisible();
    expectText(
      $.tester.widget<Text>(find.byKey(AchievementsKeys.toastTitle)).data,
      title,
    );
    await $.pumpAndSettle();
    expect(find.byKey(AchievementsKeys.toast), findsNothing);
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
