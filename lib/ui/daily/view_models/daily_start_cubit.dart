import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/daily/daily_final_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/streak_rules.dart';
import '../../../routing/routes.dart';

/// Para onde vai o `/daily` (o toque da home e do lembrete): a partida do
/// final de hoje, com o Maia no nível do rating da pessoa. Sem final hoje,
/// volta à home.
sealed class DailyStartState {
  const DailyStartState();
}

class DailyStartLoading extends DailyStartState {
  const DailyStartLoading();
}

class DailyStartReady extends DailyStartState {
  const DailyStartReady(this.location);

  final String location;
}

class DailyStartCubit extends Cubit<DailyStartState> {
  DailyStartCubit({
    required this._daily,
    required this._rating,
    required this._now,
    this._activity,
    this._analytics = const NoAnalyticsRepository(),
    this.entry = 'home',
  }) : super(const DailyStartLoading());

  final DailyFinalRepository _daily;
  final RatingRepository _rating;
  final Now _now;
  final ActivityRepository? _activity;
  final AnalyticsRepository _analytics;

  /// De onde o final do dia abriu: `home|aviso|lembrete|link`.
  final String entry;

  Future<void> load() async {
    final daily = await _daily.of(_now());
    final rating = await _rating.current();
    if (daily != null) {
      final days = await _activity?.days() ?? const <DateTime>{};
      unawaited(
        _analytics.log(
          AnalyticsEvents.finalDiaAberto(
            entrada: entry,
            sequencia: StreakRules.of(days, _now()).current,
            jaJogouHoje: await _daily.record(_now()) != null,
          ),
        ),
      );
    }
    if (isClosed) return;
    emit(
      DailyStartReady(
        daily == null
            ? Routes.home
            : Routes.dailyGame(
                daily,
                level: MaiaLevels.nearest(rating.rounded),
              ),
      ),
    );
  }
}
