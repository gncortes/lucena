import '../../../domain/models/daily_final.dart';
import '../../../domain/models/week_summary.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/streak_rules.dart';
import '../../../domain/use_cases/week_rules.dart';
import '../activity/activity_repository.dart';
import '../daily/daily_final_repository.dart';
import '../progress/progress_repository.dart';
import '../rating/rating_repository.dart';

/// O resumo da semana de agora (E1.23).
abstract class WeekRepository {
  Future<WeekSummary> summary();
}

/// Junta as partidas, o rating, a sequência e os finais do dia da semana.
class LocalWeekRepository implements WeekRepository {
  const LocalWeekRepository({
    required this._progress,
    required this._rating,
    required this._activity,
    required this._daily,
    required this._now,
  });

  final ProgressRepository _progress;
  final RatingRepository _rating;
  final ActivityRepository _activity;
  final DailyFinalRepository _daily;
  final Now _now;

  @override
  Future<WeekSummary> summary() async {
    final now = _now();
    final week = StreakRules.week(now);
    final attempts = await _progress.allAttempts();
    final from = await _rating.at(week.first);
    final to = await _rating.current();
    final streak = StreakRules.of(await _activity.days(), now);
    final daily = <DailyRecord>[
      for (final day in week)
        if (!day.isAfter(now)) ?await _daily.record(day),
    ];
    return WeekRules.of(
      now: now,
      played: [for (final attempt in attempts) attempt.playedAt],
      daily: daily,
      ratingFrom: from.rounded,
      ratingTo: to.rounded,
      streakDays: streak.current,
    );
  }
}
