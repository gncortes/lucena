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
    this.reviewWeight = 0,
    this.engine = false,
    this.engineLines = const {},
    this.barScores = const {},
    this.live = const {},
    this.annotating = const {},
    this.engineDepths = const {},
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

  /// A revisão da partida inteira: existe quando todos os lances têm
  /// anotação (da revisão ou de ter passado por eles), com a precisão de cada
  /// lado.
  final GameReview? review;

  /// A revisão está rodando, quanto dela já foi (0 a 1) e o peso dela.
  final bool reviewing;
  final double reviewProgress;
  final int reviewWeight;

  /// A engine ligada: as melhores linhas da posição no tabuleiro.
  final bool engine;

  /// As linhas da engine já calculadas, por posição (índice como
  /// [shownIndex]).
  final Map<int, List<EngineLine>> engineLines;

  /// A avaliação de cada posição para a barra (índice como [shownIndex]): a
  /// mais pesada que a engine já fez dela, assim que sai (na revisão, na
  /// passagem pelo lance ou só para a barra).
  final Map<int, EngineScore> barScores;

  /// A anotação de cada lance, a mais pesada que já saiu (da revisão, de ter
  /// passado pelo lance ou de ter ficado nele).
  final Map<int, ReviewedMove> live;

  /// O professor e as histórias que ele conta enquanto a revisão roda.
  final Character? viktor;
  final List<String> stories;

  /// A profundidade das linhas já mostradas, por posição.
  final Map<int, int> engineDepths;

  /// Os lances sendo avaliados agora.
  final Set<int> annotating;

  /// A anotação do lance [index]. Nula enquanto a engine não avaliou.
  ReviewedMove? reviewOf(int index) => live[index];

  /// A avaliação da posição mostrada: a da engine ligada, a da anotação ou a
  /// rápida da barra. Nula enquanto nenhuma existe.
  EngineScore? get shownScore {
    final lines = engineLines[shownIndex];
    if (engine && lines != null && lines.isNotEmpty) return lines.first.score;
    // A avaliação mais pesada que a engine já fez desta posição.
    if (barScores[shownIndex] case final score?) return score;
    if (live[shownIndex] case final move?) return move.after;
    if (live[shownIndex + 1] case final move?) return move.before;
    if (lines != null && lines.isNotEmpty) return lines.first.score;
    return null;
  }

  /// A análise abre na posição de início, antes do primeiro lance.
  int get shownIndex => selected ?? -1;

  /// A posição que o tabuleiro mostra e o lance em destaque nela.
  Position? get shownPosition =>
      shownIndex < 0 ? start : moves[shownIndex].position;
  Move? get shownMove => shownIndex < 0 ? null : moves[shownIndex].move;

  /// A anotação do lance mostrado. Nula sem anotação ou no início.
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
    int? reviewWeight,
    bool? engine,
    Map<int, List<EngineLine>>? engineLines,
    Map<int, EngineScore>? barScores,
    Map<int, ReviewedMove>? live,
    Set<int>? annotating,
    Map<int, int>? engineDepths,
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
    reviewWeight: reviewWeight ?? this.reviewWeight,
    engine: engine ?? this.engine,
    engineLines: engineLines ?? this.engineLines,
    barScores: barScores ?? this.barScores,
    live: live ?? this.live,
    annotating: annotating ?? this.annotating,
    engineDepths: engineDepths ?? this.engineDepths,
    viktor: viktor,
    stories: stories,
  );
}

/// A revisão rápida, média ou profunda.
enum ReviewSpeed { quick, medium, deep }

/// Quanto a engine trabalha numa posição: para na profundidade ou no tempo,
/// o que vier antes.
typedef AnalysisBudget = ({int depth, Duration time});

/// Os detalhes de uma partida terminada: os dados dela, os lances com o
/// tempo de cada um e a revisão pela engine (qualidade de cada lance e
/// precisão de cada lado), que fica guardada; e a engine, que se liga para
/// ver as melhores linhas da posição no tabuleiro.
///
/// Cada anotação tem um PESO (o índice em [budgets]): passar pelo lance
/// anota na hora (peso 0); a revisão anota lance a lance com o peso dela,
/// andando com o tabuleiro; ficar parado num lance sobe os pesos. Uma
/// anotação só troca outra de peso menor.
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

  /// Os orçamentos da engine por peso: 0 ao passar pelo lance; 1, 2 e 3 nas
  /// revisões rápida, média e profunda (o tempo é por posição, então por
  /// lance); 4 e 5 ficando parado no lance.
  static const budgets = <AnalysisBudget>[
    (depth: 10, time: Duration(milliseconds: 500)),
    (depth: 14, time: Duration(milliseconds: 1500)),
    (depth: 20, time: Duration(seconds: 5)),
    (depth: 26, time: Duration(seconds: 10)),
    (depth: 32, time: Duration(seconds: 20)),
    (depth: 40, time: Duration(seconds: 45)),
  ];

  /// O peso de cada revisão.
  static const reviewWeights = {
    ReviewSpeed.quick: 1,
    ReviewSpeed.medium: 2,
    ReviewSpeed.deep: 3,
  };

  static const barDepth = 12;

  /// As linhas da engine ligada: na hora e depois cada vez mais fundas.
  static const engineDepths = [8, 14, 18];
  static const engineDepth = 18;

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
    final saved = await _reviews?.load(_gameId);
    final review = saved != null && saved.moves.length == moves.length
        ? saved
        : null;
    final texts = await _lessons?.texts(language);
    final viktor = characters.where((c) => c.id == 'master').firstOrNull;
    if (isClosed) return;
    emit(
      GameDetailsState(
        review: review,
        live: {...?review?.moves.asMap()},
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
    // O lance na tela já é avaliado (e aprofunda enquanto fica nele).
    unawaited(_annotate(state.shownIndex));
  }

  /// Mostra a posição depois do lance [index] (-1: a de início). Durante a
  /// revisão, o tabuleiro deixa de acompanhar a revisão.
  void select(int index) {
    if (!state.ready) return;
    _following = false;
    final target = index.clamp(-1, state.moves.length - 1);
    emit(state.copyWith(selected: target));
    if (state.engine) unawaited(_analyseShown());
    unawaited(_annotate(target));
  }

  void first() => select(-1);
  void previous() => select(state.shownIndex - 1);
  void next() => select(state.shownIndex + 1);
  void last() => select(state.moves.length - 1);

  /// O tabuleiro acompanha a revisão (até o jogador mexer nele).
  bool _following = false;

  /// Revisa a partida inteira com a engine, lance a lance e com o tabuleiro
  /// andando junto: começa na posição de início já avaliada; a engine avalia
  /// a posição depois do próximo lance no orçamento da revisão e o tabuleiro
  /// vai para ele com a avaliação (barra) e a anotação juntas. Lances que já
  /// têm anotação de peso igual ou maior passam direto. A revisão fica
  /// gravada.
  Future<void> review({ReviewSpeed speed = ReviewSpeed.medium}) async {
    final weight = reviewWeights[speed]!;
    if (_analysis == null || state.start == null || state.reviewing) return;
    if (state.moves.isEmpty) return;
    _following = true;
    emit(
      state.copyWith(reviewing: true, reviewProgress: 0, reviewWeight: weight),
    );
    final total = state.moves.length;
    // A posição de início primeiro: a barra já abre com a avaliação dela.
    if (!await _reviewLines(0, weight)) return;
    if (_following) emit(state.copyWith(selected: -1));
    for (var index = 0; index < total; index++) {
      if ((state.live[index]?.weight ?? -1) < weight) {
        emit(state.copyWith(annotating: {...state.annotating, index}));
        // Enquanto a engine pensa, o tabuleiro fica na posição de antes (já
        // avaliada); o lance entra junto com a avaliação e a anotação dele.
        if (!await _reviewLines(index + 1, weight)) return;
        _setAnnotation(index, weight);
      }
      if (_following) {
        emit(state.copyWith(selected: index));
        if (state.engine) unawaited(_analyseShown());
      }
      emit(state.copyWith(reviewProgress: (index + 1) / total));
    }
    _following = false;
    emit(state.copyWith(reviewing: false, reviewProgress: 1));
    await _save();
    // Ficando no lance mostrado, a engine continua aprofundando.
    unawaited(_annotate(state.shownIndex));
  }

  /// As linhas da posição [k] no peso da revisão. Se o jogador pedir outra
  /// coisa no meio, a engine atende e a revisão pede de novo. Falso se a tela
  /// fechou.
  Future<bool> _reviewLines(int k, int weight) async {
    while (true) {
      try {
        await _linesAt(k, weight, preemptible: true);
        return !isClosed;
      } on AnalysisInterrupted {
        if (isClosed) return false;
      }
    }
  }

  /// As linhas da engine por posição (0: a de início; k: a depois do lance
  /// k − 1) e peso. Nulo: a partida acabou ali ou a engine não respondeu. Um
  /// lance só é julgado com as duas posições (antes e depois dele) no mesmo
  /// peso: uma rasa e outra funda dariam avaliações que não se comparam (a
  /// funda vê o mate que a rasa ainda não vê).
  final _lines = <(int, int), List<EngineLine>?>{};
  final _pending = <(int, int), Future<void>>{};

  Position _positionAt(int k) =>
      k == 0 ? state.start! : state.moves[k - 1].position;

  /// Pede as linhas da posição [k] no peso [weight]. Os pedidos
  /// [preemptible] (os longos) param no meio se chegar um mais importante
  /// ([AnalysisInterrupted]), e nada fica guardado.
  Future<void> _linesAt(
    int k,
    int weight, {
    bool urgent = false,
    bool preemptible = false,
  }) {
    final key = (k, weight);
    if (_lines.containsKey(key)) return Future.value();
    return _pending[key] ??= () async {
      try {
        final position = _positionAt(k);
        final budget = budgets[weight];
        final lines = position.isGameOver
            ? null
            : await _analysis!.analyse(
                position,
                depth: budget.depth,
                time: budget.time,
                lines: 2,
                urgent: urgent,
                preemptible: preemptible,
              );
        _lines[key] = lines == null || lines.isEmpty ? null : lines;
        _scoreBar(k - 1, ReviewRules.scoreOf(position, _lines[key]), weight);
      } finally {
        _pending.remove(key);
      }
    }();
  }

  /// Anota o lance [index] com as linhas do peso [weight], se for mais
  /// pesado que a anotação que ele já tem. Com todos os lances anotados, a
  /// revisão (e a precisão) sai deles.
  void _setAnnotation(int index, int weight) {
    final annotating = {...state.annotating}..remove(index);
    if ((state.live[index]?.weight ?? -1) >= weight) {
      emit(state.copyWith(annotating: annotating));
      return;
    }
    final live = {
      ...state.live,
      index: ReviewRules.review(
        start: _positionAt(index),
        moves: [state.moves[index].move],
        analyses: [_lines[(index, weight)], _lines[(index + 1, weight)]],
        depth: weight,
      ).moves.single,
    };
    final complete = live.length == state.moves.length;
    emit(
      state.copyWith(
        live: live,
        annotating: annotating,
        review: complete
            ? ReviewRules.compose([
                for (var i = 0; i < live.length; i++) live[i]!,
              ], whiteFirst: state.start!.turn == Side.white)
            : null,
      ),
    );
    if (complete && !state.reviewing) unawaited(_save());
  }

  Future<void> _save() async {
    final review = state.review;
    if (review != null) await _reviews?.save(_gameId, review);
  }

  /// Anota na hora o lance [index] que o jogador está vendo: primeiro no
  /// peso 0 (instantâneo) e, enquanto ele fica no lance, nos pesos seguintes
  /// (a anotação pode mudar, como no Lichess). Durante a revisão, só o peso
  /// 0: o resto da engine é dela.
  Future<void> _annotate(int index) async {
    if (_analysis == null || index < 0 || index >= state.moves.length) return;
    if (!_annotating.add(index)) return;
    try {
      for (var weight = 0; weight < budgets.length; weight++) {
        if ((state.live[index]?.weight ?? -1) >= weight) continue;
        // O jogador saiu do lance (ou a revisão tem a engine): o resto fica
        // para quando ele voltar.
        final known = state.live.containsKey(index);
        if (known && (state.shownIndex != index || state.reviewing)) return;
        if (!known) {
          emit(state.copyWith(annotating: {...state.annotating, index}));
        }
        if (weight == 0) {
          // Na hora: as duas posições juntas, na frente de tudo.
          await Future.wait([
            _linesAt(index, 0, urgent: true),
            _linesAt(index + 1, 0, urgent: true),
          ]);
        } else {
          // Ficando no lance: uma posição de cada vez, e para se o jogador
          // sair dele (o próximo lance passa na frente).
          for (final k in [index, index + 1]) {
            if (state.shownIndex != index || state.reviewing) return;
            await _linesAt(k, weight, urgent: true, preemptible: true);
          }
        }
        if (isClosed) return;
        _setAnnotation(index, weight);
      }
    } on AnalysisInterrupted {
      // Saiu do lance (ou a revisão começou) no meio da conta.
    } finally {
      _annotating.remove(index);
    }
  }

  final _annotating = <int>{};

  /// A avaliação rápida da posição mostrada, para a barra, se ainda não
  /// existe nenhuma.
  /// Durante a revisão, ela mesma avalia a posição (pedir à parte só a
  /// atrasaria).
  Future<void> scoreShown() async {
    final analysis = _analysis;
    final index = state.shownIndex;
    final position = state.shownPosition;
    if (analysis == null || position == null || state.reviewing) return;
    if (state.shownScore != null || !_barAsked.add(index)) return;
    final score = position.isGameOver
        ? ReviewRules.scoreOf(position, null)
        : (await analysis.analyse(
            position,
            depth: barDepth,
          )).firstOrNull?.score;
    _scoreBar(index, score, 0);
  }

  final _barAsked = <int>{};

  /// A avaliação da posição [index] para a barra, se for mais pesada que a
  /// que ela já tem.
  void _scoreBar(int index, EngineScore? score, int weight) {
    if (isClosed || score == null) return;
    if ((_barWeights[index] ?? -1) > weight) return;
    _barWeights[index] = weight;
    emit(state.copyWith(barScores: {...state.barScores, index: score}));
  }

  final _barWeights = <int, int>{};

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
