import '../../../domain/models/week_summary.dart';
import '../../core/l10n/l10n.dart';

/// "subiu 40 pontos", "caiu 12 pontos" ou "o rating ficou em 1152": o
/// `trend` e o `points` das frases da semana.
({String trend, int points}) _trend(WeekSummary week) => switch (week.points) {
  > 0 => (trend: 'up', points: week.points),
  < 0 => (trend: 'down', points: -week.points),
  _ => (trend: 'same', points: week.ratingTo),
};

/// O título da Sua semana.
String weekHeadline(AppLocalizations l10n, WeekSummary week) {
  if (week.finals == 0) return l10n.weekHeadlineEmpty;
  final trend = _trend(week);
  return l10n.weekHeadline(week.finals, trend.trend, trend.points);
}

/// O texto da notificação de domingo.
String weekNotification(AppLocalizations l10n, WeekSummary week) {
  final trend = _trend(week);
  return l10n.weekNotifText(week.finals, trend.trend, trend.points);
}

/// O `day` de [AppLocalizations.weekBestDay].
String weekdayKey(DateTime day) => const [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
][day.weekday - DateTime.monday];
