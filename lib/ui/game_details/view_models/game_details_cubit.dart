import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analysis/analysis_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/review/game_review_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
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
    this.live = const {},
    this.annotating = const {},
    this.engineDepths = const {},
    this.liveDepths = const {},
    this.viktor,
    this.stories = const [],
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

  /// Os lances já anotados antes da revisão completa: os que o jogador foi
  /// passando (a engine avalia na hora) e os que a revisão já cobriu.
  final Map<int, ReviewedMove> live;

  /// O professor e as histórias que ele conta enquanto a revisão roda.
  final Character? viktor;
  final List<String> stories;

  /// A profundidade de cada anotação na hora, por lance.
  final Map<int, int> liveDepths;

  /// A profundidade das linhas já mostradas, por posição.
  final Map<int, int> engineDepths;

  /// Os lances sendo avaliados agora.
  final Set<int> annotating;

  /// A anotação do lance [index]: a da revisão ou a feita na hora.
  ReviewedMove? reviewOf(int index) {
    final review = this.review;
    final live = this.live[index];
    if (review != null && index >= 0 && index < review.moves.length) {
      // Ficando no lance, a engine passa da profundidade da revisão.
      if (live != null && (liveDepths[index] ?? 0) > review.depth) return live;
      return review.moves[index];
    }
    return live;
  }

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
    if (live[shownIndex] case final move?) return move.after;
    if (shownIndex < 0 && live[0] != null) return live[0]!.before;
    return barScores[shownIndex];
  }

  int get shownIndex => selected ?? moves.length - 1;

  /// A posição que o tabuleiro mostra e o lance em destaque nela.
  Position? get shownPosition =>
      shownIndex < 0 ? start : moves[shownIndex].position;
  Move? get shownMove => shownIndex < 0 ? null : moves[shownIndex].move;

  /// A revisão do lance mostrado. Nula sem revisão ou no início.
  ReviewedMove? get shownReview => reviewOf(shownIndex);

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
    Map<int, ReviewedMove>? live,
    Set<int>? annotating,
    Map<int, int>? engineDepths,
    Map<int, int>? liveDepths,
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
    live: live ?? this.live,
    annotating: annotating ?? this.annotating,
    engineDepths: engineDepths ?? this.engineDepths,
    liveDepths: liveDepths ?? this.liveDepths,
    viktor: viktor,
    stories: stories,
  );
}

/// A revisão rápida, média ou profunda (a profundidade da engine).
enum ReviewSpeed { quick, medium, deep }

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
    this._lessons,
  }) : super(const GameDetailsState());

  /// A profundidade da engine na revisão: rápida, média (a de fábrica) ou
  /// profunda.
  static const reviewDepths = {
    ReviewSpeed.quick: 10,
    ReviewSpeed.medium: 14,
    ReviewSpeed.deep: 18,
  };
  static const engineDepth = 18;
  static const barDepth = 12;

  /// A anotação na hora, ao passar os lances: sai rasa, na primeira
  /// profundidade, e vai aprofundando enquanto o jogador fica no lance (pode
  /// mudar de qualidade, como no Lichess). A revisão completa usa a
  /// [reviewDepths].
  static const liveDepths = [8, 12, 16, 20];
  static const liveDepth = 8;

  /// As linhas da engine ligada: na hora e depois cada vez mais fundas.
  static const engineDepths = [8, 14, 18];

  /// Quantas linhas a engine mostra ligada.
  static const engineLineCount = 3;

  final int _gameId;
  final ProgressRepository _progress;
  final RatingRepository? _rating;
  final CharacterRepository? _characters;
  final AnalysisRepository? _analysis;
  final GameReviewRepository? _reviews;
  final LessonRepository? _lessons;

  Future<void> load({String language = 'en'}) async {
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
    final texts = await _lessons?.texts(language);
    final viktor = characters.where((c) => c.id == 'master').firstOrNull;
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
        viktor: viktor,
        stories: texts?.all('review.stories') ?? const [],
      ),
    );
    // Sem revisão, o lance na tela já é avaliado.
    unawaited(_annotate(state.shownIndex));
  }

  /// Mostra a posição depois do lance [index] (-1: a de início).
  void select(int index) {
    if (!state.ready) return;
    final target = index.clamp(-1, state.moves.length - 1);
    emit(state.copyWith(selected: target));
    if (state.engine) unawaited(_analyseShown());
    unawaited(_annotate(target));
  }

  void first() => select(-1);
  void previous() => select(state.shownIndex - 1);
  void next() => select(state.shownIndex + 1);
  void last() => select(state.moves.length - 1);

  /// Revisa a partida inteira com a engine: cada posição (a de início e a
  /// depois de cada lance), com o progresso na tela e cada lance anotado assim
  /// que a posição depois dele é avaliada. A revisão fica gravada.
  Future<void> review({ReviewSpeed speed = ReviewSpeed.medium}) async {
    final reviewDepth = reviewDepths[speed]!;
    final start = state.start;
    if (_analysis == null || start == null || state.reviewing) return;
    if (state.moves.isEmpty) return;
    emit(state.copyWith(reviewing: true, reviewProgress: 0));
    final total = state.moves.length + 1;
    for (var k = 0; k < total; k++) {
      await _linesAt(k, reviewDepth);
      if (isClosed) return;
      // O lance que acabou de ficar com as duas posições avaliadas; uma
      // anotação mais funda (o jogador ficou nele) não é trocada.
      final index = k - 1;
      final deeper = (state.liveDepths[index] ?? 0) > reviewDepth;
      emit(
        state.copyWith(
          reviewProgress: (k + 1) / total,
          live: k == 0 || deeper
              ? state.live
              : {...state.live, index: _moveReview(index, reviewDepth)},
          liveDepths: k == 0 || deeper
              ? state.liveDepths
              : {...state.liveDepths, index: reviewDepth},
        ),
      );
    }
    final review = ReviewRules.review(
      start: start,
      moves: [for (final move in state.moves) move.move],
      analyses: [for (var k = 0; k < total; k++) _lines[(k, reviewDepth)]],
      depth: reviewDepth,
    );
    await _reviews?.save(_gameId, review);
    if (isClosed) return;
    emit(state.copyWith(review: review, reviewing: false, reviewProgress: 1));
  }

  /// As linhas da engine em cada posição da partida (0: a de início; k: a
  /// depois do lance k − 1), já pedidas. Nulo: a partida acabou ali ou a
  /// engine não respondeu.
  /// As linhas da engine por posição e profundidade. Um lance só é julgado
  /// com as duas posições (antes e depois dele) na mesma profundidade: uma
  /// rasa e outra funda dariam avaliações que não se comparam (a funda vê o
  /// mate que a rasa ainda não vê).
  final _lines = <(int, int), List<EngineLine>?>{};
  final _pending = <(int, int), Future<void>>{};

  Position _positionAt(int k) =>
      k == 0 ? state.start! : state.moves[k - 1].position;

  Future<void> _linesAt(int k, int depth, {bool urgent = false}) {
    final key = (k, depth);
    if (_lines.containsKey(key)) return Future.value();
    return _pending[key] ??= () async {
      final position = _positionAt(k);
      final lines = position.isGameOver
          ? null
          : await _analysis!.analyse(
              position,
              depth: depth,
              lines: 2,
              urgent: urgent,
            );
      _lines[key] = lines == null || lines.isEmpty ? null : lines;
      _pending.remove(key);
    }();
  }

  /// A anotação do lance [index], com as posições antes e depois dele já
  /// avaliadas.
  ReviewedMove _moveReview(int index, int depth) => ReviewRules.review(
    start: _positionAt(index),
    moves: [state.moves[index].move],
    analyses: [_lines[(index, depth)], _lines[(index + 1, depth)]],
    depth: depth,
  ).moves.single;

  /// Anota na hora o lance [index] que o jogador está vendo: primeiro raso
  /// (instantâneo) e, enquanto ele fica no lance, cada vez mais fundo. Com a
  /// revisão feita, só aprofunda além da profundidade dela.
  Future<void> _annotate(int index) async {
    if (_analysis == null || index < 0 || index >= state.moves.length) return;
    if (!_annotating.add(index)) return;
    try {
      for (final depth in liveDepths) {
        final known = state.review?.depth ?? 0;
        if (depth <= known || depth <= (state.liveDepths[index] ?? 0)) {
          continue;
        }
        // O jogador saiu do lance: o resto fica para quando ele voltar.
        if (state.shownIndex != index && state.live.containsKey(index)) return;
        if (!state.live.containsKey(index)) {
          emit(state.copyWith(annotating: {...state.annotating, index}));
        }
        await Future.wait([
          _linesAt(index, depth, urgent: true),
          _linesAt(index + 1, depth, urgent: true),
        ]);
        if (isClosed) return;
        // A revisão (ou outra passada) já anotou mais fundo no meio tempo.
        if ((state.liveDepths[index] ?? 0) >= depth) continue;
        emit(
          state.copyWith(
            live: {...state.live, index: _moveReview(index, depth)},
            liveDepths: {...state.liveDepths, index: depth},
            annotating: {...state.annotating}..remove(index),
          ),
        );
      }
    } finally {
      _annotating.remove(index);
    }
  }

  final _annotating = <int>{};

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

  /// As linhas da engine na posição mostrada: primeiro rasas, na hora, e
  /// depois as fundas no lugar delas.
  Future<void> _analyseShown() async {
    final analysis = _analysis;
    final index = state.shownIndex;
    final position = state.shownPosition;
    if (analysis == null || position == null) return;
    if ((state.engineDepths[index] ?? 0) >= engineDepth) return;
    if (_engineRunning.contains(index)) return;
    _engineRunning.add(index);
    try {
      if (position.isGameOver) {
        emit(
          state.copyWith(
            engineLines: {...state.engineLines, index: const []},
            engineDepths: {...state.engineDepths, index: engineDepth},
          ),
        );
        return;
      }
      for (final depth in engineDepths) {
        if ((state.engineDepths[index] ?? 0) >= depth) continue;
        final lines = await analysis.analyse(
          position,
          depth: depth,
          lines: engineLineCount,
          urgent: true,
        );
        if (isClosed) return;
        emit(
          state.copyWith(
            engineLines: {...state.engineLines, index: lines},
            engineDepths: {...state.engineDepths, index: depth},
          ),
        );
        // O jogador já foi para outra posição: a funda fica para depois.
        if (!state.engine || state.shownIndex != index) return;
      }
    } finally {
      _engineRunning.remove(index);
    }
  }

  final _engineRunning = <int>{};
}
