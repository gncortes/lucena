import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/achievements/achievements_repository.dart';
import '../../../data/repositories/analysis/analysis_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/conclusion/conclusion_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/positions/positions_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/review/game_review_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/conclusion.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_review.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/player_rating.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/conclusion_rules.dart';
import '../../../domain/use_cases/game_feedback.dart';
import '../../../domain/use_cases/marathon.dart';
import '../../../domain/use_cases/mastery.dart';
import '../../../domain/use_cases/review_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/speedrun_score.dart';
import '../../../routing/routes.dart';
import '../../achievements/view_models/achievement_facts_loader.dart';

/// A conclusão de uma partida que não se grava, pronta, para a rota
/// [Routes.conclusionNow].
class ConclusionArgs {
  const ConclusionArgs({
    required this.conclusion,
    this.opponent,
    this.replay,
    this.setup,
  });

  final Conclusion conclusion;
  final Character? opponent;
  final String? replay;
  final String? setup;
}

/// O que a tela de conclusão mostra.
class ConclusionState {
  const ConclusionState({
    this.ready = false,
    this.missing = false,
    this.conclusion,
    this.opponent,
    this.characters = const [],
    this.feedback = const [],
    this.comment,
    this.emotion = Emotion.calm,
    this.replay,
    this.setup,
    this.speedrun,
    this.review,
    this.reviewing = false,
    this.reviewDone = 0,
    this.bestLine = const [],
    this.bestPly = -1,
  });

  final bool ready;

  /// A partida não existe mais (apagada ou id errado).
  final bool missing;
  final Conclusion? conclusion;

  /// O adversário como personagem. Nulo no tabuleiro livre de dois.
  final Character? opponent;
  final List<Character> characters;

  /// "Primeira vitória contra o Tito", recordes, conquistas.
  final List<GameFeedback> feedback;

  /// O que o adversário diz do resultado.
  final String? comment;
  final Emotion emotion;

  /// A rota da mesma partida, de novo ("Jogar de novo").
  final String? replay;

  /// A rota da configuração do mesmo final ("Nova partida").
  final String? setup;

  /// O speedrun ou a Maratona da partida (para "Tentar de novo").
  final Speedrun? speedrun;

  /// O resumo da revisão (melhores, imprecisões, erros), quando pronto.
  final GameReview? review;

  /// A revisão está sendo calculada (o esqueleto aparece no lugar).
  final bool reviewing;

  /// Quantos lances a análise rápida já avaliou.
  final int reviewDone;

  /// A melhor linha desde a posição de início (UCI) e o lance mostrado
  /// dela (-1: a posição de início).
  final List<String> bestLine;
  final int bestPly;

  ConclusionState copyWith({
    GameReview? review,
    bool? reviewing,
    int? reviewDone,
    List<String>? bestLine,
    int? bestPly,
  }) => ConclusionState(
    ready: ready,
    missing: missing,
    conclusion: conclusion,
    opponent: opponent,
    characters: characters,
    feedback: feedback,
    comment: comment,
    emotion: emotion,
    replay: replay,
    setup: setup,
    speedrun: speedrun,
    review: review ?? this.review,
    reviewing: reviewing ?? this.reviewing,
    reviewDone: reviewDone ?? this.reviewDone,
    bestLine: bestLine ?? this.bestLine,
    bestPly: bestPly ?? this.bestPly,
  );
}

/// A tela de conclusão de uma partida (T51, frente B): tudo vem do que está
/// gravado (a partida, o rating, as conquistas, o speedrun), então fechar o
/// app e voltar mostra a mesma tela, sem contar nada de novo.
class ConclusionCubit extends Cubit<ConclusionState> {
  ConclusionCubit({
    required this._progress,
    required this._rating,
    required this._achievements,
    required this._journey,
    required this._speedruns,
    required this._positions,
    required this._characters,
    required this._now,
    this._onboarding,
    this._pending,
    this._analysis,
    this._reviews,
  }) : super(const ConclusionState());

  final ProgressRepository _progress;
  final RatingRepository _rating;
  final AchievementsRepository _achievements;
  final JourneyRepository _journey;
  final SpeedrunRepository _speedruns;
  final PositionsRepository _positions;
  final CharacterRepository _characters;
  final Now _now;
  final OnboardingRepository? _onboarding;

  // A conclusão aberta, para o app reabrir nela.
  final ConclusionRepository? _pending;

  // O Stockfish do aparelho: o resumo da revisão e a melhor linha.
  final AnalysisRepository? _analysis;
  final GameReviewRepository? _reviews;

  /// O orçamento por posição da análise rápida: o mesmo da revisão rápida
  /// (peso [reviewWeight]), para a tela da revisão já mostrá-la feita.
  static const reviewBudget = (depth: 14, time: Duration(milliseconds: 1500));
  static const reviewWeight = 1;

  /// O orçamento da melhor linha, desde a posição de início.
  static const bestLineBudget = (depth: 22, time: Duration(seconds: 3));

  /// Monta a conclusão da partida gravada [gameId].
  Future<void> load(int gameId, String language) async {
    final game = (await _progress.attemptsById([gameId]))[gameId];
    if (game == null) {
      if (!isClosed) emit(const ConclusionState(ready: true, missing: true));
      return;
    }
    await _pending?.open(gameId);
    final facts = await AchievementFactsLoader(
      journey: _journey,
      progress: _progress,
      speedruns: _speedruns,
      positions: _positions,
    ).load();
    final (before, after) = await _ratingOf(gameId);
    final all = {for (final a in await _achievements.all()) a.id: a};
    final unlocked = {
      for (final entry in (await _achievements.unlocked()).entries)
        if (entry.value.gameId == gameId) entry.key: entry.value,
    };
    final earned = [for (final id in unlocked.keys) ?all[id]];
    final challengeId = game.challengeId;
    final next = challengeId == null || !game.fulfilled
        ? null
        : Mastery.nextChallenge(
            facts.ladder,
            await _progress.fulfilledChallenges(),
            challengeId,
            startRung: (await _onboarding?.load())?.startRung,
          );
    final run = await _runOf(game, facts.speedruns);
    final speedrun = facts.speedruns[run?.speedrunId];
    final marathon = speedrun?.kind == SpeedrunKind.marathon;
    final lost = run != null && run.nextChallenge == null && !_finished(run);
    // O desafio especial às cegas do degrau.
    final blind = facts.ladder.any(
      (rung) => rung.challenges.any(
        (challenge) =>
            challenge.id == challengeId &&
            challenge.mode == ChallengeMode.blind,
      ),
    );
    final kind = ConclusionRules.kindOf(
      blind: blind,
      challengeId: challengeId,
      speedrun: run != null,
      marathon: marathon,
      lost: lost,
      finished: run != null && _finished(run),
    );
    final characters = await _characters.characters();
    final opponent = switch (game.opponent) {
      OpponentKind.stockfish => Character.stockfish,
      OpponentKind.maia => characters.forLevel(game.opponentLevel),
      OpponentKind.twoPlayers => null,
    };
    final result = ConclusionRules.resultOf(game.outcome);
    final conclusion = Conclusion(
      kind: kind,
      result: result,
      gameId: gameId,
      game: game,
      end: game.endReason == null
          ? null
          : GameEnd(game.endReason!, winner: _winner(game)),
      userSide: game.userSide,
      fulfilled: game.fulfilled,
      before: before,
      after: after,
      achievements: earned,
      unlocked: unlocked,
      next: next?.challenge,
      run: run,
      finalFen: _finalFen(game),
      blindMoves: blind
          ? ConclusionRules.userMoves(
              plies: game.moves.length,
              userSide: game.userSide ?? Side.white,
              startFen: game.startFen,
            )
          : null,
      actions: ConclusionRules.actionsFor(
        kind,
        recorded: true,
        rated: after != null,
        hasNext: next != null,
      ),
    );
    final position = await _positions.byId(game.positionId);
    final (comment, emotion) = await _comment(opponent, result, language);
    final feedback = await _feedbackOf(game, gameId, facts);
    if (isClosed) return;
    emit(
      ConclusionState(
        ready: true,
        conclusion: conclusion,
        opponent: opponent,
        characters: characters,
        feedback: [
          ...feedback,
          for (final achievement in earned)
            GameFeedback(
              FeedbackKind.achievement,
              achievementId: achievement.id,
            ),
        ],
        comment: comment,
        emotion: emotion,
        replay: _replayOf(game, position?.goal.code),
        speedrun: speedrun,
        setup: position == null || run != null
            ? null
            : Routes.setup(
                position.fen,
                goal: position.goal.code,
                position: position.id,
              ),
      ),
    );
    unawaited(_background(game, gameId));
  }

  // Em segundo plano, sem travar as ações: a melhor linha e o resumo da
  // revisão (gravado, para a revisão da partida abrir já revisada). Se a
  // engine falhar, os blocos somem sem aviso.
  Future<void> _background(Attempt game, int gameId) async {
    final analysis = _analysis;
    final start = game.startFen == null ? null : _parse(game.startFen!);
    if (analysis == null || start == null) return;
    try {
      final lines = await analysis.analyse(
        start,
        depth: bestLineBudget.depth,
        time: bestLineBudget.time,
      );
      if (isClosed) return;
      final best = lines.firstOrNull?.moves ?? const <String>[];
      emit(state.copyWith(bestLine: best));
    } on Object {
      // Sem a melhor linha.
    }
    // Uma análise já feita (a rápida daqui ou a da revisão) aparece pronta.
    final saved = await _reviews?.load(gameId);
    if (isClosed || saved == null) return;
    emit(state.copyWith(review: saved));
  }

  /// "Análise rápida": o Stockfish avalia cada lance da partida e o resumo
  /// (precisão e qualidade dos lances) aparece na tela e fica gravado, para
  /// a revisão abrir pronta.
  Future<void> quickReview() async {
    final analysis = _analysis;
    final game = state.conclusion?.game;
    final gameId = state.conclusion?.gameId;
    final start = game?.startFen == null ? null : _parse(game!.startFen!);
    if (analysis == null || game == null || gameId == null || start == null) {
      return;
    }
    if (state.reviewing || state.review != null) return;
    final moves = [for (final uci in game.moves) ?Move.parse(uci)];
    if (moves.isEmpty) return;
    emit(state.copyWith(reviewing: true, reviewDone: 0));
    try {
      final analyses = <List<EngineLine>?>[];
      var position = start;
      for (var k = 0; k <= moves.length; k++) {
        if (k > 0) position = position.play(moves[k - 1]);
        analyses.add(
          position.isGameOver
              ? null
              : await analysis.analyse(
                  position,
                  depth: reviewBudget.depth,
                  time: reviewBudget.time,
                  lines: 2,
                ),
        );
        if (isClosed) return;
        if (k > 0) emit(state.copyWith(reviewDone: k));
      }
      final review = ReviewRules.review(
        start: start,
        moves: moves,
        analyses: analyses,
        depth: reviewWeight,
      );
      await _reviews?.save(gameId, review);
      if (isClosed) return;
      emit(state.copyWith(review: review, reviewing: false));
    } on Object {
      // A engine falhou: o botão volta, sem aviso.
      if (!isClosed) emit(state.copyWith(reviewing: false));
    }
  }

  Position? _parse(String fen) {
    try {
      return Chess.fromSetup(Setup.parseFen(fen));
    } on Exception {
      return null;
    }
  }

  /// A melhor linha, um lance para a frente ou para trás.
  void bestForward() {
    if (state.bestPly + 1 < state.bestLine.length) {
      emit(state.copyWith(bestPly: state.bestPly + 1));
    }
  }

  void bestBack() {
    if (state.bestPly >= 0) emit(state.copyWith(bestPly: state.bestPly - 1));
  }

  /// Uma partida que não se grava (tabuleiro livre, às cegas sem desafio):
  /// a tela recebe a conclusão pronta.
  Future<void> show(
    Conclusion conclusion, {
    Character? opponent,
    String? replay,
    String? setup,
    String? language,
  }) async {
    final (comment, emotion) = language == null
        ? (null, Emotion.calm)
        : await _comment(opponent, conclusion.result, language);
    if (isClosed) return;
    emit(
      ConclusionState(
        ready: true,
        conclusion: conclusion,
        opponent: opponent,
        comment: comment,
        emotion: emotion,
        replay: replay,
        setup: setup,
      ),
    );
  }

  // Saiu da conclusão (fechar, voltar ou uma ação): o app não reabre nela.
  @override
  Future<void> close() async {
    await _pending?.clear();
    return super.close();
  }

  /// "Tentar de novo" no speedrun: uma tentativa nova, desde a primeira
  /// etapa. Devolve a rota dela.
  Future<String?> retry() async {
    final speedrun = state.speedrun;
    if (speedrun == null) return null;
    final attempt = await _speedruns.start(speedrun.id, _now());
    return Routes.challengeGame(
      speedrun.stages.first,
      speedrunId: speedrun.id,
      attemptId: attempt.id,
      stage: 0,
    );
  }

  // O rating antes e depois da partida, pelo histórico gravado.
  Future<(PlayerRating?, PlayerRating?)> _ratingOf(int gameId) async {
    final history = await _rating.history();
    final index = history.indexWhere((entry) => entry.gameId == gameId);
    if (index < 0) return (null, null);
    final after = history[index].rating;
    final before = index > 0
        ? history[index - 1].rating
        : await _rating.start();
    return (before, after);
  }

  // Os tempos do speedrun até esta etapa e o que vem depois.
  Future<ConclusionRun?> _runOf(
    Attempt game,
    Map<String, Speedrun> speedruns,
  ) async {
    final attemptId = game.speedrunAttemptId;
    if (attemptId == null) return null;
    final attempt = await _speedruns.attempt(attemptId);
    final speedrun = speedruns[attempt?.speedrunId];
    if (attempt == null || speedrun == null) return null;
    final run = SpeedrunScore.run(speedrun, attempt);
    final records = SpeedrunScore.records(
      speedrun,
      await _speedruns.attempts(speedrun.id),
    );
    final marathon = speedrun.kind == SpeedrunKind.marathon;
    final bank = marathon ? Marathon.bank(run, speedrun.time) : null;
    final lost =
        !game.fulfilled ||
        (marathon && !run.completed && bank! <= Duration.zero);
    final stage = run.currentStage;
    final going = !lost && !run.completed;
    return ConclusionRun(
      speedrunId: speedrun.id,
      attemptId: attemptId,
      stage: game.speedrunStage ?? 0,
      stageCount: speedrun.stages.length,
      stages: run.stages,
      spent: [
        for (var index = 0; index < speedrun.stages.length; index++)
          attempt.games
              .where((other) => other.speedrunStage == index)
              .fold(
                Duration.zero,
                (sum, other) => sum + (other.userClock ?? Duration.zero),
              ),
      ],
      total: run.completed ? run.total : null,
      best: records.best,
      previousBest: run.completed
          ? SpeedrunScore.previousBest(records, run)
          : records.best,
      bankLeft: bank,
      nextStage: going ? stage : null,
      nextChallenge: going ? speedrun.stages[stage] : null,
      nextTime: going && marathon
          ? Marathon.stageTime(speedrun.time, bank!)
          : null,
    );
  }

  bool _finished(ConclusionRun run) =>
      run.nextChallenge == null &&
      run.stages.isNotEmpty &&
      run.stages.every((stage) => stage.done);

  // As mensagens da partida (primeira vitória, degrau, recordes), como se a
  // partida tivesse acabado agora: só contam as partidas de antes dela.
  Future<List<GameFeedback>> _feedbackOf(
    Attempt game,
    int gameId,
    AchievementFacts facts,
  ) async {
    // As partidas gravadas antes desta, pelo id (duas partidas iguais, na
    // mesma hora, não se confundem).
    final all = await _progress.allAttemptsById();
    return GameFeedbackRules.afterGame(
      game: game,
      before: [
        for (final MapEntry(:key, :value) in all.entries)
          if (key < gameId) value,
      ],
      ladder: facts.ladder,
    );
  }

  Side? _winner(Attempt game) {
    final user = game.userSide;
    if (user == null) return null;
    return switch (game.outcome) {
      AttemptOutcome.win => user,
      AttemptOutcome.loss => user.opposite,
      AttemptOutcome.draw => null,
    };
  }

  // A posição depois do último lance.
  String? _finalFen(Attempt game) {
    final start = game.startFen;
    if (start == null) return null;
    try {
      Position position = Chess.fromSetup(Setup.parseFen(start));
      for (final uci in game.moves) {
        final move = Move.parse(uci);
        if (move == null) break;
        position = position.play(move);
      }
      return position.fen;
    } on Exception {
      return start;
    }
  }

  // A mesma partida: mesma posição, lado, adversário, ritmo e objetivo.
  String? _replayOf(Attempt game, String? goal) {
    final fen = game.startFen;
    final user = game.userSide;
    if (fen == null || user == null) return null;
    final side = user == Side.white ? 'white' : 'black';
    final mine = game.userTime?.code;
    final theirs = game.opponentTime?.code;
    return Routes.freeBoardAt(
      fen,
      view: side,
      white: user == Side.white ? mine : theirs,
      black: user == Side.white ? theirs : mine,
      opponent: game.opponent.code,
      level: game.opponentLevel?.toString(),
      user: side,
      goal: goal,
      position: game.positionId,
      challenge: game.challengeId,
    );
  }

  // A fala de fim do adversário: a do resultado, sempre a mesma para a
  // mesma partida.
  Future<(String?, Emotion)> _comment(
    Character? opponent,
    ConclusionResult result,
    String language,
  ) async {
    if (opponent == null) return (null, Emotion.calm);
    final category = switch (result) {
      // Do ponto de vista do adversário.
      ConclusionResult.won => LineCategory.loss,
      ConclusionResult.lost => LineCategory.win,
      ConclusionResult.draw => LineCategory.draw,
    };
    final lines = [
      for (final line in await _characters.lines(opponent.id, language))
        if (line.category == category) line,
    ];
    if (lines.isEmpty) return (null, Emotion.calm);
    final line = lines.first;
    return (line.text, line.emotion);
  }
}
