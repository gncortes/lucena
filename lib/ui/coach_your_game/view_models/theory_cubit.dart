import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/coach/coach_repository.dart';
import '../../../domain/models/coach/coach.dart';

enum TheoryStatus { loading, ready, noTheory, error }

final class TheoryState {
  const TheoryState({
    this.status = TheoryStatus.loading,
    this.game,
    this.chosen,
    this.step,
  });

  final TheoryStatus status;
  final CoachGame? game;

  /// O lance da teoria tocado (mostra a linha e o tabuleiro no fim dela).
  final String? chosen;

  /// Quantos lances da linha tocada estão no tabuleiro (nulo: todos).
  final int? step;

  /// Os lances da linha que aparecem no tabuleiro agora.
  int get currentStep => (step ?? line.length).clamp(0, line.length);

  GameTheory? get theory => game?.theory;

  /// O lance que ele jogou ali (SAN inglesa), se a partida tem os lances.
  String? get played {
    final p = game, t = theory;
    if (p == null || t == null || t.chessMove >= p.moves.length) return null;
    return p.moves[t.chessMove].san;
  }

  TheoryCandidate? get candidate =>
      theory?.candidates.where((c) => c.san == chosen).firstOrNull;

  /// A posição em que ele saiu da teoria (nula se o FEN não abre).
  Position? get _exit {
    final t = theory;
    if (t == null) return null;
    try {
      return Chess.fromSetup(Setup.parseFen(t.fen));
    } on Object {
      return null;
    }
  }

  /// A linha do lance tocado (começa nele), só até o primeiro lance ilegal:
  /// a lista e o tabuleiro mostram os mesmos lances.
  List<String> get line {
    final c = candidate;
    if (c == null) return const [];
    final sans = c.line.isEmpty ? [c.san] : c.line;
    final exit = _exit;
    if (exit == null) return sans;
    Position pos = exit;
    final legal = <String>[];
    for (final san in sans) {
      final move = pos.parseSan(san);
      if (move == null) break;
      pos = pos.play(move);
      legal.add(san);
    }
    return legal;
  }

  /// O meio-lance da partida marcado na lista: sem lance tocado, a jogada
  /// dele; com a linha tocada no começo (passo 0), o lance antes da saída.
  /// Nulo quando o marcado é um lance da linha.
  int? get markedInGame {
    final t = theory;
    if (t == null) return null;
    if (candidate != null && currentStep > 0) return null;
    final ply = candidate == null && _playedAtExit != null
        ? t.chessMove
        : t.chessMove - 1;
    return ply < 0 ? null : ply;
  }

  /// O lance da linha tocada marcado na lista (o último no tabuleiro).
  int? get markedInLine =>
      candidate != null && currentStep > 0 ? currentStep - 1 : null;

  /// A jogada dele, se é legal na posição da saída.
  Move? get _playedAtExit {
    final san = played;
    return san == null ? null : _exit?.parseSan(san);
  }

  /// O tabuleiro anda com o lance marcado na lista: sem toque, a posição
  /// depois da jogada dele; com a linha tocada, a linha até o passo atual
  /// (no passo 0, a posição da saída). O destaque é o lance marcado.
  ({String fen, Move? chessMove}) get board {
    final t = theory;
    if (t == null) return (fen: kInitialFEN, chessMove: null);
    final exit = _exit;
    if (exit == null) return (fen: t.fen, chessMove: null);
    if (candidate == null) {
      final his = _playedAtExit;
      if (his != null) return (fen: exit.play(his).fen, chessMove: his);
      return (fen: exit.fen, chessMove: _lastOfGame());
    }
    Position pos = exit;
    Move? lastOne = _lastOfGame();
    for (final san in line.take(currentStep)) {
      final move = pos.parseSan(san)!;
      pos = pos.play(move);
      lastOne = move;
    }
    return (fen: pos.fen, chessMove: lastOne);
  }

  /// O último lance da partida antes de ele sair da teoria (o destaque do
  /// tabuleiro na posição da saída).
  Move? _lastOfGame() {
    final p = game, t = theory;
    if (p == null ||
        t == null ||
        t.chessMove < 1 ||
        t.chessMove > p.moves.length) {
      return null;
    }
    try {
      final before = t.chessMove == 1
          ? kInitialFEN
          : p.moves[t.chessMove - 2].fen;
      return Chess.fromSetup(Setup.parseFen(before))
          .parseSan(p.moves[t.chessMove - 1].san);
    } on Object {
      return null;
    }
  }
}

/// A tela da teoria de uma partida: ouve a partida e guarda o lance tocado
/// (tocar de novo solta).
class TheoryCubit extends Cubit<TheoryState> {
  TheoryCubit({required this._repository, required this.gameId})
    : super(const TheoryState());

  final CoachRepository _repository;
  final String gameId;
  StreamSubscription<CoachGame?>? _sub;

  void load() {
    unawaited(_sub?.cancel());
    if (state.status == TheoryStatus.error) emit(const TheoryState());
    _sub = _repository.game(gameId).listen(
      (p) {
        final theory = p?.theory;
        if (p == null || theory == null || theory.candidates.isEmpty) {
          emit(TheoryState(status: TheoryStatus.noTheory, game: p));
          return;
        }
        final still = theory.candidates.any((c) => c.san == state.chosen);
        emit(
          TheoryState(
            status: TheoryStatus.ready,
            game: p,
            chosen: still ? state.chosen : null,
            step: still ? state.step : null,
          ),
        );
      },
      onError: (Object _) =>
          emit(const TheoryState(status: TheoryStatus.error)),
    );
  }

  void pick(String san) {
    if (state.status != TheoryStatus.ready) return;
    emit(
      TheoryState(
        status: state.status,
        game: state.game,
        chosen: san == state.chosen ? null : san,
      ),
    );
  }

  /// Mostra [step] lances da linha tocada (0 = a posição em que saiu).
  void goTo(int step) {
    if (state.status != TheoryStatus.ready || state.chosen == null) return;
    emit(
      TheoryState(
        status: state.status,
        game: state.game,
        chosen: state.chosen,
        step: step.clamp(0, state.line.length),
      ),
    );
  }

  void previous() => goTo(state.currentStep - 1);

  /// Sem lance tocado, avança para a linha do mais jogado.
  void next() {
    if (state.chosen == null) {
      final firstOne = state.theory?.candidates.firstOrNull;
      if (firstOne != null) pick(firstOne.san);
      return;
    }
    goTo(state.currentStep + 1);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
