import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/featured/featured_alerts_repository.dart';
import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../data/repositories/featured/featured_repository.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/use_cases/featured_rules.dart';
import '../../../domain/use_cases/now.dart';

/// A tela de um torneio: o resumo, os links e os finais dele.
class FeaturedTournamentState {
  const FeaturedTournamentState({
    this.ready = false,
    this.tournament,
    this.items = const [],
    this.ongoing = false,
    this.alertAvailable = false,
    this.alertOn = false,
  });

  final bool ready;

  /// Nulo depois de pronto: o torneio não existe mais.
  final FeaturedTournament? tournament;
  final List<FeaturedItem> items;
  final bool ongoing;

  /// Há canal de aviso (E1.20/E1.21)? Sem ele, o interruptor não aparece.
  final bool alertAvailable;
  final bool alertOn;

  FeaturedTournamentState copyWith({bool? alertOn}) => FeaturedTournamentState(
    ready: ready,
    tournament: tournament,
    items: items,
    ongoing: ongoing,
    alertAvailable: alertAvailable,
    alertOn: alertOn ?? this.alertOn,
  );
}

class FeaturedTournamentCubit extends Cubit<FeaturedTournamentState> {
  FeaturedTournamentCubit({
    required this.id,
    required this._featured,
    required this._progress,
    required this._alerts,
    required this._now,
  }) : super(const FeaturedTournamentState());

  final String id;
  final FeaturedRepository _featured;
  final FeaturedProgressRepository _progress;
  final FeaturedAlertsRepository _alerts;
  final Now _now;

  Future<void> load() async {
    final catalog = await _featured.catalog();
    final played = await _progress.played();
    final alertOn = _alerts.available && await _alerts.tournamentEnabled(id);
    if (isClosed) return;
    final tournament = catalog.tournament(id);
    final now = _now();
    emit(
      FeaturedTournamentState(
        ready: true,
        tournament: tournament,
        items: [
          for (final item in FeaturedRules.items(catalog, played, now: now))
            if (item.endgame.tournamentId == id) item,
        ],
        ongoing: tournament?.isOngoing(now) ?? false,
        alertAvailable: _alerts.available,
        alertOn: alertOn,
      ),
    );
  }

  Future<void> setAlert({required bool value}) async {
    if (!_alerts.available) return;
    emit(state.copyWith(alertOn: value));
    await _alerts.setTournamentEnabled(id, value: value);
  }
}
