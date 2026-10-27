import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/streak.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/streak_rules.dart';

/// A Sequência: dias seguidos, recorde, a semana e o mês de hoje.
class StreakState {
  const StreakState({
    this.ready = false,
    this.streak = Streak.none,
    this.today,
    this.active = const {},
    this.run = const {},
  });

  final bool ready;
  final Streak streak;
  final DateTime? today;

  /// Os dias com atividade, à meia-noite.
  final Set<DateTime> active;

  /// Os dias da sequência atual (os outros dias ativos ficam mais claros).
  final Set<DateTime> run;

  List<DateTime> get week =>
      today == null ? const [] : StreakRules.week(today!);
  List<DateTime> get month =>
      today == null ? const [] : StreakRules.month(today!);
}

class StreakCubit extends Cubit<StreakState> {
  StreakCubit({
    required this._activity,
    required this._now,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const StreakState());

  final AnalyticsRepository _analytics;
  final ActivityRepository _activity;
  final Now _now;

  Future<void> load() async {
    final days = await _activity.days();
    if (isClosed) return;
    final now = _now();
    final streak = StreakRules.of(days, now);
    unawaited(
      _analytics.log(
        AnalyticsEvents.sequenciaVista(
          sequencia: streak.current,
          recorde: streak.record,
        ),
      ),
    );
    emit(
      StreakState(
        ready: true,
        streak: streak,
        today: StreakRules.day(now),
        active: {for (final at in days) StreakRules.day(at)},
        run: StreakRules.run(days, now).toSet(),
      ),
    );
  }
}
