import '../../../domain/models/history_filter.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/rating_period.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';

/// Os textos dos filtros do Histórico.
abstract final class HistoryLabels {
  /// O período como o resto do app o chama (7 dias, 1 ano, Todas).
  static String period(AppLocalizations l10n, RatingPeriod period) =>
      switch (period) {
        RatingPeriod.all => l10n.profileRatingPeriodAll,
        RatingPeriod.year => l10n.ratingPeriodYear,
        _ => l10n.ratingPeriodDays(period.days!),
      };

  /// O ritmo de um filtro de partidas: uma categoria ou sem relógio.
  static String gamePace(AppLocalizations l10n, String value) =>
      value == GamesHistoryFilter.noClock
      ? l10n.challengeNoClock
      : PaceCategory.fromCode(value)!.label(l10n);

  static String level(AppLocalizations l10n, SpeedrunCategory level) =>
      switch (level) {
        SpeedrunCategory.beginner => l10n.profileLevelBeginner,
        SpeedrunCategory.intermediate => l10n.profileLevelIntermediate,
        SpeedrunCategory.advanced => l10n.profileLevelAdvanced,
      };

  /// Com a primeira letra maiúscula (o mês sai minúsculo em alguns idiomas).
  static String capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  /// [text] isolado como LTR dentro de um texto RTL (ritmo `5+3`, `+N`): a
  /// direção do parágrafo continua a do idioma.
  static String ltr(String text) => '\u2066$text\u2069';
}
