import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/speedrun_score.dart';

part 'speedrun_cubit.freezed.dart';

/// Um speedrun com os recordes dele.
@freezed
abstract class SpeedrunSummary with _$SpeedrunSummary {
  const factory SpeedrunSummary({
    required Speedrun speedrun,
    required SpeedrunRecords records,

    /// A tentativa em andamento, se há.
    SpeedrunRun? ongoing,
  }) = _SpeedrunSummary;
}

@freezed
abstract class SpeedrunState with _$SpeedrunState {
  const factory SpeedrunState({
    /// Todos os speedruns. Nulo enquanto são lidos.
    List<SpeedrunSummary>? all,

    /// O speedrun aberto (tela dele ou de uma tentativa).
    SpeedrunSummary? selected,

    /// A tentativa aberta, já contada.
    SpeedrunRun? run,

    /// O recorde de antes de [run] terminar. Nulo se não havia.
    Duration? previousBest,

    /// A partida em andamento é uma etapa de [run]: jogar continua ela.
    @Default(false) bool gameOngoing,
  }) = _SpeedrunState;
}

/// Os speedruns: lista, recordes, tentativas e histórico. As partidas de cada
/// etapa são gravadas pela partida; aqui só se começa e se abandona uma
/// tentativa.
class SpeedrunCubit extends Cubit<SpeedrunState> {
  SpeedrunCubit({
    required this._journey,
    required this._speedruns,
    required this._games,
    required this._now,
  }) : super(const SpeedrunState());

  final JourneyRepository _journey;
  final SpeedrunRepository _speedruns;
  final OngoingGameRepository _games;
  final Now _now;

  /// Lê tudo. Com [speedrunId], abre esse speedrun; com [attemptId], também
  /// a tentativa.
  Future<void> load({String? speedrunId, int? attemptId}) async {
    final all = <SpeedrunSummary>[];
    for (final speedrun in await _journey.speedruns()) {
      final attempts = await _speedruns.attempts(speedrun.id);
      final runs = [
        for (final attempt in attempts) SpeedrunScore.run(speedrun, attempt),
      ];
      final ongoing = runs.where((run) => run.inProgress).lastOrNull;
      all.add(
        SpeedrunSummary(
          speedrun: speedrun,
          records: SpeedrunScore.records(speedrun, attempts),
          ongoing: ongoing,
        ),
      );
    }
    final selected = all
        .where((summary) => summary.speedrun.id == speedrunId)
        .firstOrNull;
    SpeedrunRun? run;
    if (selected != null && attemptId != null) {
      final attempt = await _speedruns.attempt(attemptId);
      if (attempt != null) run = SpeedrunScore.run(selected.speedrun, attempt);
    }
    final snapshot = await _games.load();
    if (isClosed) return;
    emit(
      SpeedrunState(
        all: all,
        selected: selected,
        run: run,
        previousBest: selected == null || run == null
            ? null
            : SpeedrunScore.previousBest(selected.records, run),
        gameOngoing:
            run != null &&
            snapshot != null &&
            snapshot.mode.speedrunAttemptId == run.attempt.id,
      ),
    );
  }

  /// Começa uma tentativa do speedrun aberto. Devolve o id dela.
  Future<int?> start() async {
    final selected = state.selected;
    if (selected == null) return null;
    final attempt = await _speedruns.start(selected.speedrun.id, _now());
    return attempt.id;
  }

  /// Desiste da tentativa aberta: ela fica no histórico, sem recorde.
  Future<void> abandon() async {
    final run = state.run;
    final selected = state.selected;
    if (run == null || selected == null || !run.inProgress) return;
    await _speedruns.abandon(run.attempt.id, _now());
    // A etapa que estava no tabuleiro também sai.
    if (state.gameOngoing) await _games.clear();
    await load(speedrunId: selected.speedrun.id, attemptId: run.attempt.id);
  }
}
