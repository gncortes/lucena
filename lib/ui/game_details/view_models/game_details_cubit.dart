import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/use_cases/game_rules.dart';

/// Um lance da partida, já em notação algébrica, com o tempo que levou e a
/// posição depois dele.
class LoggedMove {
  const LoggedMove({
    required this.san,
    required this.move,
    required this.position,
    this.time,
  });

  final String san;
  final Move move;
  final Position position;

  /// Quanto o lance levou. Nulo nas partidas de antes de isto ser gravado.
  final Duration? time;
}

class GameDetailsState {
  const GameDetailsState({
    this.ready = false,
    this.attempt,
    this.start,
    this.moves = const [],
    this.ratingChange,
    this.ratingAfter,
    this.characters = const [],
    this.selected,
  });

  final bool ready;

  /// A partida. Nula se não foi achada.
  final Attempt? attempt;

  /// A posição de início e os lances, refeitos a partir do que foi gravado.
  final Position? start;
  final List<LoggedMove> moves;

  /// Quanto a partida mudou o rating e como ele ficou. Nulos se não contou.
  final int? ratingChange;
  final int? ratingAfter;

  final List<Character> characters;

  /// O lance no tabuleiro (índice em [moves]). Nulo: o último; -1: o início.
  final int? selected;

  int get shownIndex => selected ?? moves.length - 1;

  /// A posição que o tabuleiro mostra e o lance em destaque nela.
  Position? get shownPosition =>
      shownIndex < 0 ? start : moves[shownIndex].position;
  Move? get shownMove => shownIndex < 0 ? null : moves[shownIndex].move;

  GameDetailsState copyWith({int? selected}) => GameDetailsState(
    ready: ready,
    attempt: attempt,
    start: start,
    moves: moves,
    ratingChange: ratingChange,
    ratingAfter: ratingAfter,
    characters: characters,
    selected: selected,
  );
}

/// Os detalhes de uma partida terminada: os dados dela e os lances, com o
/// tempo de cada um. Ainda sem análise.
class GameDetailsCubit extends Cubit<GameDetailsState> {
  GameDetailsCubit(
    this._gameId, {
    required this._progress,
    this._rating,
    this._characters,
  }) : super(const GameDetailsState());

  final int _gameId;
  final ProgressRepository _progress;
  final RatingRepository? _rating;
  final CharacterRepository? _characters;

  Future<void> load() async {
    final attempt = (await _progress.attemptsById([_gameId]))[_gameId];
    final characters = await _characters?.characters() ?? const <Character>[];
    // O que a partida fez no rating: o ponto dela e o anterior.
    int? change;
    int? after;
    final history = await _rating?.history() ?? const [];
    final index = history.indexWhere((entry) => entry.gameId == _gameId);
    if (index >= 0) {
      after = history[index].rating.rounded;
      if (index > 0) change = after - history[index - 1].rating.rounded;
    }
    final start = GameRules.fromFen(attempt?.startFen ?? '');
    final moves = <LoggedMove>[];
    if (attempt != null && start != null) {
      var position = start;
      for (final (index, uci) in attempt.moves.indexed) {
        final move = Move.parse(uci);
        final played = move == null ? null : GameRules.play(position, move);
        if (played == null) break;
        position = played.position;
        moves.add(
          LoggedMove(
            san: played.san,
            move: move!,
            position: position,
            time: index < attempt.moveTimes.length
                ? attempt.moveTimes[index]
                : null,
          ),
        );
      }
    }
    if (isClosed) return;
    emit(
      GameDetailsState(
        ready: true,
        attempt: attempt,
        start: start,
        moves: moves,
        ratingChange: change,
        ratingAfter: after,
        characters: characters,
      ),
    );
  }

  /// Mostra a posição depois do lance [index] (-1: a de início).
  void select(int index) {
    if (!state.ready) return;
    final target = index.clamp(-1, state.moves.length - 1);
    emit(state.copyWith(selected: target));
  }
}
