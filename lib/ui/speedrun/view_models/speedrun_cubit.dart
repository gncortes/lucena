import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
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

    /// As tentativas de que o jogador desistiu, da mais recente para a mais
    /// antiga: o histórico mostra até onde cada uma foi.
    @Default(<SpeedrunRun>[]) List<SpeedrunRun> abandoned,
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

    /// O ritmo da lista: cada ritmo tem os seus speedruns e recordes.
    @Default(SpeedrunPaces.standard) TimeControl pace,

    /// As tentativas em andamento, em qualquer ritmo.
    @Default(<SpeedrunSummary>[]) List<SpeedrunSummary> inProgress,

    /// Os personagens, um por nível do Maia.
    @Default(<Character>[]) List<Character> characters,
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
    this._settings,
    this._characters,
  }) : super(const SpeedrunState());

  final CharacterRepository? _characters;

  final JourneyRepository _journey;

  // O último ritmo escolhido. Nulo: o ritmo padrão.
  final SettingsRepository? _settings;
  final SpeedrunRepository _speedruns;
  final OngoingGameRepository _games;
  final Now _now;

  /// Lê tudo. Com [speedrunId], abre esse speedrun; com [attemptId], também
  /// a tentativa.
  Future<void> load({String? speedrunId, int? attemptId}) async {
    final bases = await _journey.speedruns();
    final pace =
        (await _settings?.load())?.clock.speedrunTime ?? SpeedrunPaces.standard;
    final all = [
      for (final base in bases)
        await _summary(SpeedrunPaces.withTime(base, pace)),
    ];
    // As tentativas em andamento, em qualquer ritmo: a lista mostra todas no
    // alto, com "Continuar".
    // Só a lista precisa delas.
    final inProgress = <SpeedrunSummary>[
      if (speedrunId == null)
        for (final base in bases)
          for (final time in SpeedrunPaces.all)
            if (time == pace)
              ...all.where(
                (s) =>
                    s.speedrun.id == SpeedrunPaces.idFor(base.id, pace) &&
                    s.ongoing != null,
              )
            else if (await _summary(SpeedrunPaces.withTime(base, time))
                case final summary when summary.ongoing != null)
              summary,
    ];
    // O speedrun aberto pode ser de outro ritmo que o da lista.
    final opened = SpeedrunPaces.resolve(bases, speedrunId);
    final selected = opened == null
        ? null
        : all.where((s) => s.speedrun.id == opened.id).firstOrNull ??
              await _summary(opened);
    SpeedrunRun? run;
    if (selected != null && attemptId != null) {
      final attempt = await _speedruns.attempt(attemptId);
      if (attempt != null) run = SpeedrunScore.run(selected.speedrun, attempt);
    }
    final snapshot = await _games.load();
    final characters = await _characters?.characters() ?? const <Character>[];
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
        pace: pace,
        inProgress: inProgress,
        characters: characters,
      ),
    );
  }

  Future<SpeedrunSummary> _summary(Speedrun speedrun) async {
    final attempts = await _speedruns.attempts(speedrun.id);
    final runs = [
      for (final attempt in attempts) SpeedrunScore.run(speedrun, attempt),
    ];
    return SpeedrunSummary(
      speedrun: speedrun,
      records: SpeedrunScore.records(speedrun, attempts),
      ongoing: runs.where((run) => run.inProgress).lastOrNull,
      abandoned: runs.where((run) => run.abandoned).toList()
        ..sort(
          (a, b) => b.attempt.abandonedAt!.compareTo(a.attempt.abandonedAt!),
        ),
    );
  }

  /// Troca o ritmo da lista (e grava a escolha).
  Future<void> choosePace(TimeControl pace) async {
    final settings = _settings;
    if (settings != null) {
      final current = await settings.load();
      await settings.save(
        current.copyWith(clock: current.clock.copyWith(speedrunTime: pace)),
      );
    }
    await load(speedrunId: state.selected?.speedrun.id);
  }

  /// Começa uma tentativa do speedrun aberto no ritmo [pace] (gravado como
  /// o último escolhido). Devolve o id do speedrun nesse ritmo e o da
  /// tentativa.
  Future<(String, int)?> startWith(TimeControl pace) async {
    final selected = state.selected;
    if (selected == null) return null;
    final bases = await _journey.speedruns();
    final (baseId, _) = SpeedrunPaces.parse(selected.speedrun.id);
    final speedrun = SpeedrunPaces.resolve(
      bases,
      SpeedrunPaces.idFor(baseId, pace),
    );
    if (speedrun == null) return null;
    final settings = _settings;
    if (settings != null) {
      final current = await settings.load();
      await settings.save(
        current.copyWith(clock: current.clock.copyWith(speedrunTime: pace)),
      );
    }
    final attempt = await _speedruns.start(speedrun.id, _now());
    return (speedrun.id, attempt.id);
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
