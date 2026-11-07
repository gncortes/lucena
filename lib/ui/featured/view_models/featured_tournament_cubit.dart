import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../data/repositories/featured/featured_repository.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/use_cases/featured_rules.dart';
import '../../../domain/use_cases/now.dart';

/// A tela de um torneio: o resumo, os links e os finais dele.
class FeaturedTournamentState {
  final LoadFailure? failure;
  const FeaturedTournamentState({
    this.failure,
    this.ready = false,
    this.tournament,
    this.items = const [],
    this.ongoing = false,
  });

  final bool ready;

  /// Nulo depois de pronto: o torneio não existe mais.
  final FeaturedTournament? tournament;
  final List<FeaturedItem> items;
  final bool ongoing;
}

class FeaturedTournamentCubit extends Cubit<FeaturedTournamentState> {
  FeaturedTournamentCubit({
    required this.id,
    required this._featured,
    required this._progress,
    required this._now,
  }) : super(const FeaturedTournamentState());

  final String id;
  final FeaturedRepository _featured;
  final FeaturedProgressRepository _progress;
  final Now _now;

  Future<void> load() async {
    _retryLoad = () => load();
    try {
      await _load();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) {
        emit(FeaturedTournamentState(failure: LoadFailure.of(error)));
      }
    }
  }

  Future<void> Function()? _retryLoad;
  Future<void> retryLoad() async {
    emit(const FeaturedTournamentState());
    await _retryLoad?.call();
  }

  Future<void> _load() async {
    final catalog = await _featured.catalog();
    final played = await _progress.played();
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
      ),
    );
  }
}
