import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/daily/daily_final_repository.dart';
import '../../../data/repositories/tablebase/kpk_repository.dart';
import '../../../domain/models/daily_final.dart';
import '../../../domain/models/script_table.dart';
import '../../../domain/models/wdl.dart';
import '../../../domain/use_cases/daily_final_rules.dart';
import '../../../domain/use_cases/position_judge.dart';
import '../../free_board/view_models/free_board_state.dart';

/// A partida do final do dia, ao lado da do tabuleiro: a cor de cada lance da
/// pessoa e a primeira tentativa do dia, que é a que vale.
class DailyGameState {
  const DailyGameState({
    this.ready = false,
    this.daily,
    this.record,
    this.squares = const [],
  });

  final bool ready;
  final DailyFinal? daily;

  /// A primeira tentativa do dia, depois de gravada.
  final DailyRecord? record;

  /// As cores dos lances da partida na tela.
  final List<DailySquare> squares;

  DailyGameState copyWith({
    bool? ready,
    DailyFinal? daily,
    DailyRecord? record,
    List<DailySquare>? squares,
  }) => DailyGameState(
    ready: ready ?? this.ready,
    daily: daily ?? this.daily,
    record: record ?? this.record,
    squares: squares ?? this.squares,
  );
}

class DailyGameCubit extends Cubit<DailyGameState> {
  DailyGameCubit({
    required this.date,
    required this._daily,
    required this._activity,
    required this._kpk,
    this._engine,
  }) : super(const DailyGameState());

  /// O dia da partida (`aaaa-mm-dd`).
  final String date;
  final DailyFinalRepository _daily;
  final ActivityRepository _activity;
  final KpkRepository _kpk;
  final PositionJudge? _engine;

  PositionJudge? _judge;
  Future<void> _work = Future.value();

  // O resultado teórico de cada posição já julgada, para quem tem a vez.
  final _values = <String, Wdl?>{};

  // A cor de cada lance da pessoa, pelo índice do lance na partida.
  final _byPly = <int, DailySquare>{};
  bool _marked = false;

  DateTime get _day => DateTime.parse(date);

  Future<void> load() async {
    final daily = await _daily.of(_day);
    final record = await _daily.record(_day);
    _judge = LayeredJudge(await _kpk.oracle(), ScriptTable.empty, _engine);
    if (isClosed) return;
    emit(state.copyWith(ready: true, daily: daily, record: record));
  }

  /// A partida mudou: julga os lances novos e, no fim da primeira tentativa,
  /// grava o resultado. Em fila, na ordem em que chegam.
  void update(FreeBoardState game) {
    _work = _work.then((_) => _update(game));
  }

  /// Espera os julgamentos e a gravação pendentes.
  Future<void> settle() => _work;

  Future<void> _update(FreeBoardState game) async {
    final user = game.mode.userSide;
    final judge = _judge;
    if (user == null || judge == null || isClosed) return;
    _byPly.removeWhere((ply, _) => ply >= game.ucis.length);
    var position = game.start;
    for (var ply = 0; ply < game.ucis.length; ply++) {
      final move = Move.parse(game.ucis[ply]);
      if (move == null) return;
      final after = position.playUnchecked(move);
      if (position.turn == user && !_byPly.containsKey(ply)) {
        final before = await _value(judge, position);
        final theirs = await _value(judge, after);
        _byPly[ply] = DailyFinalRules.square(before, theirs?.flipped);
      }
      position = after;
    }
    if (_byPly.isNotEmpty && !_marked) {
      _marked = true;
      await _activity.markToday();
    }
    final squares = [
      for (final ply in _byPly.keys.toList()..sort()) _byPly[ply]!,
    ];
    if (isClosed) return;
    emit(state.copyWith(squares: squares));
    final end = game.end;
    final daily = state.daily;
    if (end == null || daily == null || state.record != null) return;
    final outcome = DailyOutcome.of(end, user);
    await _daily.saveFirst(
      DailyRecord(
        date: _day,
        positionId: daily.position.id,
        outcome: outcome,
        fulfilled: outcome.fulfills(daily.position.goal),
        squares: squares,
      ),
    );
    final record = await _daily.record(_day);
    if (isClosed) return;
    emit(state.copyWith(record: record));
  }

  Future<Wdl?> _value(PositionJudge judge, Position position) async {
    final key = ScriptTable.keyOf(position.fen);
    if (_values.containsKey(key)) return _values[key];
    return _values[key] = await judge.evaluate(position);
  }
}
