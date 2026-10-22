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
    this.offers = false,
    RaceRun? ongoing,
    RaceTheme? theme,
  }) : _now = now,
       _problems = problems ?? raceTestProblems,
       _record = record,
       _ongoing = ongoing,
       _theme = theme;

  final Now _now;
  final List<RaceProblem> _problems;
  RaceRecord _record;
  RaceRun? _ongoing;
  RaceTheme? _theme;
  bool offers;
  final _history = <RaceResult>[];

  @override
  Future<List<RaceProblem>> problems() async => _problems;

  @override
  Future<RaceRecord> record() async => _record;

  @override
  Future<void> restoreRecord(RaceRecord record) async => _record = RaceRecord(
    corrects: max(_record.corrects, record.corrects),
    hardest: max(_record.hardest, record.hardest),
  );

  @override
  Future<List<RaceResult>> history() async => List.of(_history);

  @override
  Future<RaceRun?> ongoing() async => _ongoing;

  @override
  Future<void> saveOngoing(RaceRun run) async => _ongoing = run;

  @override
  Future<RaceOutcome> finish(RaceRun run, RaceEnd end) async {
    final outcome = RaceRules.finish(run, end, _record, _now());
    _record = RaceRules.merge(_record, run);
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

/// Quatro problemas de teste (posições reais do banco: ver o asset), do mais
/// fácil ao mais difícil.
const raceTestProblems = [
  RaceProblem(
    id: 'race.001',
    fen: '8/8/K7/8/8/5p2/6k1/Q7 w - - 0 1',
    solution: 'a1g7',
    theme: RaceTheme.queen,
    level: 900,
  ),
  RaceProblem(
    id: 'race.002',
    fen: '8/2k5/8/3K4/2P5/8/8/8 w - - 0 1',
    solution: 'd5c5',
    theme: RaceTheme.pawns,
    level: 1060,
  ),
  RaceProblem(
    id: 'race.003',
    fen: '8/1R6/6P1/8/6r1/7k/8/7K w - - 0 1',
    solution: 'g6g7',
    theme: RaceTheme.rook,
    level: 1140,
  ),
  RaceProblem(
    id: 'race.004',
    fen: '8/8/P3k3/4r3/8/8/8/1K5R w - - 0 1',
    solution: 'a6a7',
    theme: RaceTheme.rook,
    level: 1220,
  ),
];
