import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/coach/your_game_filter_repository.dart';
import '../../../data/repositories/coach/coach_repository.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/coach/your_game_summary.dart';

enum YourGameStatus { loading, ready, error }

final class YourGameState {
  const YourGameState({
    this.status = YourGameStatus.loading,
    this.timeControl,
    this.games = const [],
    this.stats = CoachStats.blank,
    this.summary,
    this.platform,
  });

  final YourGameStatus status;

  /// `null` = Todos.
  final TimeControl? timeControl;
  final List<CoachGame> games;
  final CoachStats stats;
  final YourGameSummary? summary;

  /// A conta ligada (o "do Lichess" do subtítulo).
  final Platform? platform;

  YourGameState copyWith({
    YourGameStatus? status,
    TimeControl? Function()? timeControl,
    List<CoachGame>? games,
    CoachStats? stats,
    YourGameSummary? summary,
    Platform? Function()? platform,
  }) => YourGameState(
    status: status ?? this.status,
    timeControl: timeControl != null ? timeControl() : this.timeControl,
    games: games ?? this.games,
    stats: stats ?? this.stats,
    summary: summary ?? this.summary,
    platform: platform != null ? platform() : this.platform,
  );
}

/// A aba Seu jogo: ouve as partidas e as estatísticas do Treinador e refaz o
/// resumo a cada mudança ou troca de ritmo.
class YourGameCubit extends Cubit<YourGameState> {
  YourGameCubit({
    required this._repository,
    required this._filter,
    required this._now,
  }) : super(const YourGameState());

  final CoachRepository _repository;
  final YourGameFilterRepository _filter;
  final Now _now;
  final _subs = <StreamSubscription<Object?>>[];
  var _hasGames = false;

  /// Também é o "Tentar de novo": troca as assinaturas, sem somar outras.
  Future<void> load() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final timeControl = await _filter.timeControl();
    if (isClosed) return;
    emit(
      state.copyWith(
        timeControl: () => timeControl,
        status: state.status == YourGameStatus.error
            ? YourGameStatus.loading
            : null,
      ),
    );
    _subs
      ..add(
        _repository.account().listen(
          (c) => emit(state.copyWith(platform: () => c?.platform)),
          onError: (Object _) {},
        ),
      )
      ..add(
        _repository.stats().listen(
          (e) => _redo(stats: e),
          onError: (Object _) {},
        ),
      )
      ..add(
        _repository.games().listen(
          (p) {
            _hasGames = true;
            _redo(games: p);
          },
          onError: (Object _) =>
              emit(state.copyWith(status: YourGameStatus.error)),
        ),
      );
  }

  Future<void> pickTimeControl(TimeControl? timeControl) async {
    if (timeControl == state.timeControl) return;
    emit(state.copyWith(timeControl: () => timeControl));
    _redo();
    await _filter.setTimeControl(timeControl);
  }

  void _redo({List<CoachGame>? games, CoachStats? stats}) {
    if (isClosed) return;
    final p = games ?? state.games;
    final e = stats ?? state.stats;
    emit(
      state.copyWith(
        status: _hasGames ? YourGameStatus.ready : state.status,
        games: p,
        stats: e,
        summary: summarizeYourGame(
          games: p,
          stats: e,
          currentTime: _now(),
          timeControl: state.timeControl,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
