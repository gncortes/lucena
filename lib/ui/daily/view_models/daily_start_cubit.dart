import '../../../domain/models/load_failure.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';

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
/// o estado é [DailyStartEmpty] (volta ao Início com um aviso).
sealed class DailyStartState {
  const DailyStartState();
}

class DailyStartLoading extends DailyStartState {
  const DailyStartLoading();
}

class DailyStartFailed extends DailyStartState {
  const DailyStartFailed(this.failure);
  final LoadFailure failure;
}

/// Não há final publicado para hoje (H-DES-03).
class DailyStartEmpty extends DailyStartState {
  const DailyStartEmpty();
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
    try {
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
        daily == null
            ? const DailyStartEmpty()
            : DailyStartReady(
                Routes.dailyGame(
                  daily,
                  level: MaiaLevels.nearest(rating.rounded),
                ),
              ),
      );
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) emit(DailyStartFailed(LoadFailure.of(error)));
    }
  }
}
