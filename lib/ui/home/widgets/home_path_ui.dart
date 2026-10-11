import 'package:flutter/material.dart';

import '../../../domain/models/home_layout.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/home_suggestion.dart';
import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';

/// Como cada caminho aparece: o ícone, o nome, o texto (que muda com o
/// nível), a tela que ele abre e a key do cartão na tela inicial.
extension HomePathUi on HomePath {
  IconData get icon => switch (this) {
    HomePath.learn => Icons.school_outlined,
    HomePath.journey => Icons.hiking_rounded,
    HomePath.forYou => Icons.route_outlined,
    HomePath.endgames => Icons.auto_stories_outlined,
    HomePath.speedrun => Icons.timer_outlined,
    HomePath.train => Icons.grid_view_rounded,
  };

  String title(AppLocalizations l10n) => switch (this) {
    HomePath.learn => l10n.homeLearn,
    HomePath.journey => l10n.homeJourney,
    HomePath.forYou => l10n.homeForYou,
    HomePath.endgames => l10n.homeEndgames,
    HomePath.speedrun => l10n.homeSpeedrun,
    HomePath.train => l10n.homeTrain,
  };

  /// O texto para o nível [level] (sem nível, o de quem começa).
  String body(AppLocalizations l10n, RatingLevel? level) {
    final text = level == null
        ? HomePathText.standard
        : HomeSuggestion.textOf(this, level);
    return switch ((this, text)) {
      (HomePath.learn, HomePathText.player) => l10n.homeLearnBodyPlayer,
      (HomePath.learn, _) => l10n.homeLearnBody,
      (HomePath.journey, HomePathText.player) => l10n.homeJourneyBodyPlayer,
      (HomePath.journey, _) => l10n.homeJourneyBody,
      (HomePath.speedrun, HomePathText.challenge) =>
        l10n.homeSpeedrunBodyChallenge,
      (HomePath.speedrun, _) => l10n.homeSpeedrunBody,
      (HomePath.forYou, _) => l10n.homeForYouBody,
      (HomePath.endgames, _) => l10n.homeEndgamesBody,
      (HomePath.train, _) => l10n.homeTrainBody,
    };
  }

  String get route => switch (this) {
    HomePath.learn => Routes.school,
    HomePath.journey => Routes.journey,
    HomePath.forYou => Routes.endgamesFiltered(forYou: true),
    HomePath.endgames => Routes.endgamesFiltered(forYou: false),
    HomePath.speedrun => Routes.speedruns,
    HomePath.train => Routes.catalog,
  };

  /// A key do cartão na tela inicial (a mesma de antes de dar para
  /// escolher).
  Key get homeKey => switch (this) {
    HomePath.learn => HomeKeys.schoolButton,
    HomePath.journey => HomeKeys.journeyButton,
    HomePath.forYou => HomeKeys.forYouButton,
    HomePath.endgames => HomeKeys.endgamesButton,
    HomePath.speedrun => HomeKeys.speedrunButton,
    HomePath.train => HomeKeys.catalogButton,
  };
}
