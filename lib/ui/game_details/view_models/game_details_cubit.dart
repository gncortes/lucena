import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analysis/analysis_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/review/game_review_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_review.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/review_rules.dart';

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
    this.review,
    this.reviewing = false,
    this.reviewProgress = 0,
    this.engine = false,
    this.engineLines = const {},
    this.barScores = const {},
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

  /// A revisão da partida pela engine. Nula até ser feita.
  final GameReview? review;

  /// A revisão está sendo feita, e quanto dela já foi (0 a 1).
  final bool reviewing;
  final double reviewProgress;

  /// A engine ligada: as melhores linhas da posição no tabuleiro.
  final bool engine;

  /// As linhas da engine já calculadas, por posição (índice como
  /// [shownIndex]).
  final Map<int, List<EngineLine>> engineLines;

  /// Avaliações rápidas para a barra, por posição, quando ainda não há
  /// revisão nem a engine ligada.
  final Map<int, EngineScore> barScores;

  /// A avaliação da posição mostrada: a da engine ligada, a da revisão ou a
  /// rápida da barra. Nula enquanto nenhuma existe.
  EngineScore? get shownScore {
    final lines = engineLines[shownIndex];
    if (engine && lines != null && lines.isNotEmpty) return lines.first.score;
    final review = this.review;
    if (review != null && review.moves.isNotEmpty) {
      return shownIndex < 0
          ? review.moves.first.before
          : review.moves[shownIndex].after;
    }
    if (lines != null && lines.isNotEmpty) return lines.first.score;
    return barScores[shownIndex];
  }

  int get shownIndex => selected ?? moves.length - 1;

  /// A posição que o tabuleiro mostra e o lance em destaque nela.
  Position? get shownPosition =>
      shownIndex < 0 ? start : moves[shownIndex].position;
  Move? get shownMove => shownIndex < 0 ? null : moves[shownIndex].move;

  /// A revisão do lance mostrado. Nula sem revisão ou no início.
  ReviewedMove? get shownReview {
    final review = this.review;
    if (review == null || shownIndex < 0) return null;
    return shownIndex < review.moves.length ? review.moves[shownIndex] : null;
  }

  /// As linhas da engine na posição mostrada. Nulas enquanto calculam.
  List<EngineLine>? get shownLines => engineLines[shownIndex];

  bool get atStart => shownIndex < 0;
  bool get atEnd => shownIndex >= moves.length - 1;

  GameDetailsState copyWith({
    int? selected,
    GameReview? review,
    bool? reviewing,
    double? reviewProgress,
    bool? engine,
    Map<int, List<EngineLine>>? engineLines,
    Map<int, EngineScore>? barScores,
  }) => GameDetailsState(
    ready: ready,
    attempt: attempt,
    start: start,
    moves: moves,
    ratingChange: ratingChange,
    ratingAfter: ratingAfter,
    characters: characters,
    selected: selected ?? this.selected,
    review: review ?? this.review,
    reviewing: reviewing ?? this.reviewing,
    reviewProgress: reviewProgress ?? this.reviewProgress,
    engine: engine ?? this.engine,
    engineLines: engineLines ?? this.engineLines,
    barScores: barScores ?? this.barScores,
  );
}

/// Os detalhes de uma partida terminada: os dados dela, os lances com o
/// tempo de cada um e a revisão pela engine (qualidade de cada lance e
/// precisão de cada lado), que fica guardada; e a engine, que se liga para
/// ver as melhores linhas da posição no tabuleiro.
class GameDetailsCubit extends Cubit<GameDetailsState> {
  GameDetailsCubit(
    this._gameId, {
    required this._progress,
    this._rating,
    this._characters,
    this._analysis,
    this._reviews,
  }) : super(const GameDetailsState());

  /// A profundidade da engine na revisão e com ela ligada.
  static const reviewDepth = 14;
  static const engineDepth = 18;
  static const barDepth = 12;

  /// Quantas linhas a engine mostra ligada.
  static const engineLineCount = 3;

  final int _gameId;
  final ProgressRepository _progress;
  final RatingRepository? _rating;
  final CharacterRepository? _characters;
  final AnalysisRepository? _analysis;
  final GameReviewRepository? _reviews;

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
    final review = await _reviews?.load(_gameId);
    if (isClosed) return;
    emit(
      GameDetailsState(
        review: review != null && review.moves.length == moves.length
            ? review
            : null,
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
    if (state.engine) unawaited(_analyseShown());
  }

  void first() => select(-1);
  void previous() => select(state.shownIndex - 1);
  void next() => select(state.shownIndex + 1);
  void last() => select(state.moves.length - 1);

  /// Revisa a partida inteira com a engine: cada posição (a de início e a
  /// depois de cada lance), com o progresso na tela. A revisão fica gravada.
  Future<void> review() async {
    final analysis = _analysis;
    final start = state.start;
    if (analysis == null || start == null || state.reviewing) return;
    if (state.moves.isEmpty) return;
    emit(state.copyWith(reviewing: true, reviewProgress: 0));
    final positions = [start, for (final move in state.moves) move.position];
    final analyses = <List<EngineLine>?>[];
    for (final (index, position) in positions.indexed) {
      final over = position.isGameOver;
      final lines = over
          ? null
          : await analysis.analyse(position, depth: reviewDepth, lines: 2);
      if (isClosed) return;
      analyses.add(lines == null || lines.isEmpty ? null : lines);
      emit(state.copyWith(reviewProgress: (index + 1) / positions.length));
    }
    final review = ReviewRules.review(
      start: start,
      moves: [for (final move in state.moves) move.move],
      analyses: analyses,
      depth: reviewDepth,
    );
    await _reviews?.save(_gameId, review);
    if (isClosed) return;
    emit(state.copyWith(review: review, reviewing: false, reviewProgress: 1));
  }

  /// A avaliação rápida da posição mostrada, para a barra, se ainda não
  /// existe nenhuma.
  Future<void> scoreShown() async {
    final analysis = _analysis;
    final index = state.shownIndex;
    final position = state.shownPosition;
    if (analysis == null || position == null) return;
    if (state.shownScore != null || state.barScores.containsKey(index)) return;
    final score = position.isGameOver
        ? ReviewRules.scoreOf(position, null)
        : (await analysis.analyse(
            position,
            depth: barDepth,
          )).firstOrNull?.score;
    if (isClosed || score == null) return;
    emit(state.copyWith(barScores: {...state.barScores, index: score}));
  }

  /// Liga ou desliga a engine na posição do tabuleiro.
  Future<void> toggleEngine() async {
    emit(state.copyWith(engine: !state.engine));
    if (state.engine) await _analyseShown();
  }

  Future<void> _analyseShown() async {
    final analysis = _analysis;
    final index = state.shownIndex;
    final position = state.shownPosition;
    if (analysis == null || position == null) return;
    if (state.engineLines.containsKey(index)) return;
    final lines = position.isGameOver
        ? const <EngineLine>[]
        : await analysis.analyse(
            position,
            depth: engineDepth,
            lines: engineLineCount,
          );
    if (isClosed) return;
    emit(state.copyWith(engineLines: {...state.engineLines, index: lines}));
  }
}
