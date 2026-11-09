import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/coach/coach_preferences.dart';
import '../../../data/repositories/coach/coach_repository.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/coach/coach_rules.dart';

enum ExerciseStep {
  loading,

  /// A partida não existe, não está pronta ou não tem exercícios.
  unavailable,

  /// Sem rede (ou o servidor demorou): dá para tentar de novo.
  offline,
  playing,
  solved,
  missed,
  solution,

  /// Os exercícios acabaram: a tela de pontuação.
  end,
}

/// Os exercícios de uma partida analisada, um por vez.
final class CoachExerciseState {
  const CoachExerciseState({
    this.phase = ExerciseStep.loading,
    this.game,
    this.progress = GameProgress.empty,
    this.index = 0,
    this.attempts = 1,
    this.hints = 0,
    this.fen,
    this.lastMoveOfGame,
    this.saving = false,
  });

  final ExerciseStep phase;
  final CoachGame? game;
  final GameProgress progress;

  /// 0 a N-1.
  final int index;
  final int attempts;

  /// As dicas pedidas no exercício aberto: 1 marca a peça que joga, 2 mostra
  /// o lance.
  final int hints;

  /// A posição no tabuleiro agora (depois do lance jogado, se houver).
  final String? fen;
  final String? lastMoveOfGame;
  final bool saving;

  List<CoachExercise> get exercises => game?.exercises ?? const [];
  int get total => exercises.length;
  CoachExercise? get exercise => index < total ? exercises[index] : null;
  bool get lastOne => index >= total - 1;

  /// Quanto o exercício vale agora (tentativas e dicas).
  int get counts =>
      CoachRules.points(attempts: attempts, sawSolution: false, hints: hints);

  /// Ainda dá para pedir dica: jogando e sem o lance já mostrado.
  bool get canHint =>
      phase == ExerciseStep.playing && hints < CoachRules.maxHints;

  CoachExerciseState copyWith({
    ExerciseStep? phase,
    CoachGame? game,
    GameProgress? progress,
    int? index,
    int? attempts,
    int? hints,
    String? fen,
    String? Function()? lastMoveOfGame,
    bool? saving,
  }) => CoachExerciseState(
    phase: phase ?? this.phase,
    game: game ?? this.game,
    progress: progress ?? this.progress,
    index: index ?? this.index,
    attempts: attempts ?? this.attempts,
    hints: hints ?? this.hints,
    fen: fen ?? this.fen,
    lastMoveOfGame: lastMoveOfGame == null
        ? this.lastMoveOfGame
        : lastMoveOfGame(),
    saving: saving ?? this.saving,
  );
}

final class CoachExerciseCubit extends Cubit<CoachExerciseState> {
  CoachExerciseCubit({
    required this.id,
    required this.repository,
    required this.preferences,
    this.redo = false,
  }) : super(const CoachExerciseState());

  final String id;
  final CoachRepository repository;
  final CoachPreferences preferences;

  /// "Refazer os exercícios": começa do 1 e zera a rodada (o que foi de
  /// primeira e a análise vista ficam).
  final bool redo;

  /// "Tentar de novo" da tela sem conexão.
  Future<void> reload() {
    _emit(state.copyWith(phase: ExerciseStep.loading));
    return load();
  }

  /// Quanto esperar a partida. O repositório não expõe falha de leitura (sem
  /// rede e sem cópia o fluxo só não emite), então o limite é o que vale: com
  /// cópia a leitura é imediata, e 8 s cobrem uma rede lenta sem deixar o
  /// esqueleto parado.
  static const _readingWait = Duration(seconds: 8);

  Future<void> load() async {
    try {
      final CoachGame? game;
      try {
        game = await repository
            .game(id)
            .firstWhere((p) => p == null || p.ready)
            .timeout(_readingWait);
      } on StateError {
        // O fluxo terminou sem partida: ela não existe.
        return _emit(state.copyWith(phase: ExerciseStep.unavailable));
      }
      if (game == null || game.exercises.isEmpty) {
        return _emit(state.copyWith(phase: ExerciseStep.unavailable));
      }
      var progress = await repository.progress(id);
      // Refazer só grava com o primeiro resultado: sair antes deixa a
      // partida no resumo, como estava.
      if (redo) progress = progress.restartExercises();
      final total = game.exercises.length;
      final next = progress.next(total);
      if (next == null) {
        return _emit(
          state.copyWith(
            game: game,
            progress: progress,
            index: total - 1,
            phase: ExerciseStep.end,
          ),
        );
      }
      final n = game.exercises[next - 1].n;
      final attempts = await preferences.attempts(id, n);
      final hints = await preferences.hints(id, n);
      _emit(
        _open(
          state.copyWith(game: game, progress: progress),
          next - 1,
          attempts: attempts,
          hints: hints,
        ),
      );
    } on Object {
      // Timeout ou falha de leitura: sem conexão, não "não encontrada".
      _emit(state.copyWith(phase: ExerciseStep.offline));
    }
  }

  CoachExerciseState _open(
    CoachExerciseState base,
    int index, {
    int attempts = 1,
    int hints = 0,
  }) => base.copyWith(
    index: index,
    attempts: attempts,
    hints: hints,
    fen: base.exercises[index].fen,
    lastMoveOfGame: () => null,
    phase: ExerciseStep.playing,
  );

  void _emit(CoachExerciseState s) {
    if (!isClosed) emit(s);
  }

  /// O lance do aluno no tabuleiro.
  Future<void> play(String uci) async {
    final exercise = state.exercise;
    if (state.phase != ExerciseStep.playing || exercise == null) return;
    final after = _later(exercise.fen, uci);
    if (after == null) return;
    if (exercise.accepts(uci)) {
      unawaited(preferences.forgetAttempts(id));
      _emit(
        state.copyWith(
          phase: ExerciseStep.solved,
          fen: after,
          lastMoveOfGame: () => uci,
        ),
      );
      await _save(
        ExerciseResult(
          n: exercise.n,
          solved: true,
          points: state.counts,
          attempts: state.attempts,
          hints: state.hints,
        ),
      );
    } else {
      // O erro já conta: fechar à força aqui reabre na tentativa seguinte.
      unawaited(
        preferences.saveAttempts(
          id,
          exercise.n,
          state.attempts + 1,
          hints: state.hints,
        ),
      );
      _emit(
        state.copyWith(
          phase: ExerciseStep.missed,
          fen: after,
          lastMoveOfGame: () => uci,
        ),
      );
    }
  }

  /// A dica: a primeira marca a peça que joga, a segunda mostra o lance.
  /// Cada uma desce um degrau dos pontos e fica guardada (fechar à força não
  /// devolve o ponto).
  void hint() {
    final exercise = state.exercise;
    if (!state.canHint || exercise == null) return;
    final hints = state.hints + 1;
    unawaited(
      preferences.saveAttempts(id, exercise.n, state.attempts, hints: hints),
    );
    _emit(state.copyWith(hints: hints));
  }

  /// "Tentar novamente": volta à posição e conta mais uma tentativa.
  void retry() {
    final exercise = state.exercise;
    if (state.phase != ExerciseStep.missed || exercise == null) return;
    _emit(
      state.copyWith(
        phase: ExerciseStep.playing,
        attempts: state.attempts + 1,
        fen: exercise.fen,
        lastMoveOfGame: () => null,
      ),
    );
  }

  /// "Ver a solução": mostra o lance certo e vale 0 ponto.
  Future<void> seeSolution() async {
    final exercise = state.exercise;
    if (exercise == null ||
        (state.phase != ExerciseStep.missed &&
            state.phase != ExerciseStep.playing)) {
      return;
    }
    unawaited(preferences.forgetAttempts(id));
    _emit(
      state.copyWith(
        phase: ExerciseStep.solution,
        fen: exercise.fen,
        lastMoveOfGame: () => null,
      ),
    );
    await _save(
      ExerciseResult(
        n: exercise.n,
        solved: false,
        points: 0,
        attempts: state.attempts,
        sawSolution: true,
        hints: state.hints,
      ),
    );
  }

  /// "Próximo exercício" ou "Ver a pontuação".
  void next() {
    if (state.phase != ExerciseStep.solved &&
        state.phase != ExerciseStep.solution) {
      return;
    }
    if (state.lastOne) {
      _emit(state.copyWith(phase: ExerciseStep.end));
    } else {
      _emit(_open(state, state.index + 1));
    }
  }

  Future<void> _save(ExerciseResult result) async {
    final progress = state.progress.withValue(result);
    _emit(state.copyWith(progress: progress, saving: true));
    try {
      await repository.saveProgress(id, progress);
    } on Object {
      // O repositório guarda no aparelho antes do servidor; a falha do
      // espelho remoto não volta o exercício.
    }
    _emit(state.copyWith(saving: false));
  }

  static String? _later(String fen, String uci) {
    final position = GameRules.fromFen(fen);
    final chessMove = Move.parse(uci);
    if (position == null || chessMove == null) return null;
    return GameRules.play(position, chessMove)?.position.fen;
  }
}
