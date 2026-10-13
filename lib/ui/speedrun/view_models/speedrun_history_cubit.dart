import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/speedrun_score.dart';
import 'speedrun_bonus_payer.dart';

part 'speedrun_history_cubit.freezed.dart';

/// Como uma tentativa terminou.
enum SpeedrunRunEnd { completed, lost, drawn, abandoned }

/// Uma linha do histórico: uma tentativa terminada.
@freezed
abstract class SpeedrunHistoryRun with _$SpeedrunHistoryRun {
  const factory SpeedrunHistoryRun({
    required SpeedrunRun run,
    required SpeedrunRunEnd end,

    /// A última partida (concluída) ou a desistência.
    required DateTime endedAt,

    /// A tentativa do recorde.
    @Default(false) bool record,

    /// O rating que a conclusão deu: só na primeira, a que gerou o bônus.
    int? bonus,
  }) = _SpeedrunHistoryRun;

  const SpeedrunHistoryRun._();

  /// A etapa em que parou (de 1 a N), fora das concluídas.
  int get stage => run.currentStage + 1;
}

@freezed
abstract class SpeedrunHistoryState with _$SpeedrunHistoryState {
  const factory SpeedrunHistoryState({
    /// O speedrun, já no ritmo. Nulo enquanto é lido ou se o id não existe.
    Speedrun? speedrun,

    /// O melhor tempo e quando foi feito. Nulos sem conclusão.
    Duration? best,
    DateTime? bestAt,

    /// As tentativas terminadas, da mais recente para a mais antiga. A em
    /// andamento fica só no detalhe.
    @Default(<SpeedrunHistoryRun>[]) List<SpeedrunHistoryRun> runs,

    /// Os personagens, para a foto e o nome do speedrun.
    @Default(<Character>[]) List<Character> characters,
    @Default(false) bool loaded,

    /// O ano de hoje: a data do recorde só mostra o ano fora dele.
    int? year,
  }) = _SpeedrunHistoryState;

  const SpeedrunHistoryState._();

  int get finished =>
      runs.where((run) => run.end == SpeedrunRunEnd.completed).length;
}

/// O histórico de um speedrun (um final num ritmo): o recorde, as contagens
/// e as tentativas terminadas, com o "+N" da conclusão que deu o bônus.
class SpeedrunHistoryCubit extends Cubit<SpeedrunHistoryState> {
  SpeedrunHistoryCubit({
    required this._journey,
    required this._speedruns,
    required this._rating,
    required this._now,
    this._characters,
  }) : super(const SpeedrunHistoryState());

  final JourneyRepository _journey;
  final SpeedrunRepository _speedruns;
  final RatingRepository _rating;
  final Now _now;
  final CharacterRepository? _characters;

  late final _bonus = SpeedrunBonusPayer(
    rating: _rating,
    speedruns: _speedruns,
    journey: _journey,
  );

  /// Lê o speedrun [speedrunId] (o id com o ritmo).
  Future<void> load(String speedrunId) async {
    final speedrun = SpeedrunPaces.resolve(
      await _journey.speedruns(),
      speedrunId,
    );
    if (speedrun == null) {
      if (!isClosed) emit(const SpeedrunHistoryState(loaded: true));
      return;
    }
    // A conclusão que fechou à força antes do bônus recebe agora, em
    // silêncio (P4).
    await _bonus.payPending();
    final bonuses = {
      for (final bonus in await _rating.speedrunBonuses())
        bonus.attemptId: bonus.points,
    };
    final runs = [
      for (final attempt in await _speedruns.attempts(speedrun.id))
        SpeedrunScore.run(speedrun, attempt),
    ].where((run) => !run.inProgress).toList();
    final records = SpeedrunScore.records(speedrun, [
      for (final run in runs) run.attempt,
    ]);
    // O recorde é da primeira tentativa que fez o melhor tempo.
    final record = records.completed.reversed
        .where((run) => run.total == records.best)
        .firstOrNull;
    final rows = [
      for (final run in runs)
        SpeedrunHistoryRun(
          run: run,
          end: _endOf(run),
          endedAt: run.finishedAt ?? run.attempt.abandonedAt!,
          record: run.attempt.id == record?.attempt.id,
          bonus: run.completed ? bonuses[run.attempt.id] : null,
        ),
    ]..sort((a, b) => b.endedAt.compareTo(a.endedAt));
    final characters = await _characters?.characters() ?? const <Character>[];
    if (isClosed) return;
    emit(
      SpeedrunHistoryState(
        speedrun: speedrun,
        best: records.best,
        bestAt: record?.finishedAt,
        runs: rows,
        characters: characters,
        loaded: true,
        year: _now().toLocal().year,
      ),
    );
  }

  // Perder ou empatar a etapa encerra a tentativa (P1); sem partida perdida
  // no fim, foi o jogador que desistiu.
  static SpeedrunRunEnd _endOf(SpeedrunRun run) {
    if (run.completed) return SpeedrunRunEnd.completed;
    final last = run.attempt.games.lastOrNull;
    if (last == null || last.fulfilled) return SpeedrunRunEnd.abandoned;
    return switch (last.outcome) {
      AttemptOutcome.draw => SpeedrunRunEnd.drawn,
      AttemptOutcome.loss => SpeedrunRunEnd.lost,
      _ => SpeedrunRunEnd.abandoned,
    };
  }
}
