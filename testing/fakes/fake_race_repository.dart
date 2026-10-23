import 'dart:math';

import 'package:lucena/data/repositories/race/race_repository.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/domain/use_cases/race_rules.dart';

// ignore_for_file: prefer_initializing_formals

/// A Corrida só na memória. Sem argumentos, traz o banco pequeno de
/// [raceTestProblems] e não oferece o aquecimento (as telas que não são da
/// Corrida seguem sem a folha).
class FakeRaceRepository implements RaceRepository {
  FakeRaceRepository({
    required Now now,
    List<RaceProblem>? problems,
    RaceRecord record = const RaceRecord(),
    RaceRecord record5 = const RaceRecord(),
    RaceDuration duration = RaceDuration.threeMinutes,
    this.offers = false,
    RaceRun? ongoing,
    RaceTheme? theme,
  }) : _now = now,
       _problems = problems ?? raceTestProblems,
       _record = record,
       _record5 = record5,
       _duration = duration,
       _ongoing = ongoing,
       _theme = theme;

  final Now _now;
  final List<RaceProblem> _problems;
  RaceRecord _record;
  RaceRecord _record5;
  RaceDuration _duration;
  RaceRun? _ongoing;
  RaceTheme? _theme;
  bool offers;
  final _history = <RaceResult>[];

  @override
  Future<List<RaceProblem>> problems() async => _problems;

  @override
  Future<RaceRecord> record({
    RaceDuration duration = RaceDuration.threeMinutes,
  }) async => duration == RaceDuration.fiveMinutes ? _record5 : _record;

  @override
  Future<RaceDuration> duration() async => _duration;

  @override
  Future<void> setDuration(RaceDuration duration) async => _duration = duration;

  @override
  Future<void> restoreRecord(
    RaceRecord record, {
    RaceDuration duration = RaceDuration.threeMinutes,
  }) async {
    final before = await this.record(duration: duration);
    final merged = RaceRecord(
      corrects: max(before.corrects, record.corrects),
      hardest: max(before.hardest, record.hardest),
    );
    if (duration == RaceDuration.fiveMinutes) {
      _record5 = merged;
    } else {
      _record = merged;
    }
  }

  @override
  Future<List<RaceResult>> history() async => List.of(_history);

  @override
  Future<RaceRun?> ongoing() async => _ongoing;

  @override
  Future<void> saveOngoing(RaceRun run) async => _ongoing = run;

  @override
  Future<RaceOutcome> finish(RaceRun run, RaceEnd end) async {
    final five = run.duration == RaceDuration.fiveMinutes;
    final before = five ? _record5 : _record;
    final outcome = RaceRules.finish(run, end, before, _now());
    final merged = RaceRules.merge(before, run);
    if (five) {
      _record5 = merged;
    } else {
      _record = merged;
    }
    _history.insert(0, outcome.result);
    _ongoing = null;
    return outcome;
  }

  @override
  Future<void> discardOngoing() async => _ongoing = null;

  @override
  Future<RaceTheme?> theme() async => _theme;

  @override
  Future<void> setTheme(RaceTheme? theme) async => _theme = theme;

  @override
  Future<bool> offersWarmUp() async => offers;

  @override
  Future<void> setOffersWarmUp({required bool value}) async => offers = value;
}

/// Cinco problemas de teste, um por faixa de 300 a 500 (posições legais; os
/// lances ótimos de verdade estão no asset): mate em 1 de dama, mate em 2 de
/// torre (duas linhas), uma linha de peão, uma de bispo e cavalo e mate em 1
/// de torre.
const raceTestProblems = [
  RaceProblem(
    id: 'race.300.01',
    fen: '6k1/8/6K1/8/8/8/8/Q7 w - - 0 1',
    tree: RaceNode(
      distance: 1,
      moves: {'a1a8': RaceBranch(), 'a1g7': RaceBranch()},
      slower: {'a1a2'},
    ),
    theme: RaceTheme.queen,
    level: 300,
  ),
  RaceProblem(
    id: 'race.350.01',
    fen: '7k/8/5K2/8/8/8/8/R7 w - - 0 1',
    tree: RaceNode(
      distance: 3,
      moves: {
        'f6f7': RaceBranch(
          reply: 'h8h7',
          next: RaceNode(
            distance: 1,
            moves: {'a1h1': RaceBranch()},
            slower: {'a1a2'},
          ),
        ),
        'f6g6': RaceBranch(
          reply: 'h8g8',
          next: RaceNode(distance: 1, moves: {'a1a8': RaceBranch()}),
        ),
      },
      slower: {'a1a2'},
    ),
    theme: RaceTheme.rook,
    level: 350,
  ),
  RaceProblem(
    id: 'race.400.01',
    fen: '8/P7/8/8/8/k7/8/7K w - - 0 1',
    tree: RaceNode(distance: 5, moves: {'a7a8q': RaceBranch()}),
    theme: RaceTheme.pawns,
    level: 400,
  ),
  RaceProblem(
    id: 'race.450.01',
    fen: '8/8/8/3k4/8/8/1B6/K1N5 w - - 0 1',
    tree: RaceNode(distance: 7, moves: {'c1e2': RaceBranch()}),
    theme: RaceTheme.minor,
    level: 450,
  ),
  RaceProblem(
    id: 'race.500.01',
    fen: 'k7/2K5/8/8/8/8/8/1R6 w - - 0 1',
    tree: RaceNode(distance: 1, moves: {'b1a1': RaceBranch()}),
    theme: RaceTheme.rook,
    level: 500,
  ),
];
