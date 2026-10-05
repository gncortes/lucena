import 'package:freezed_annotation/freezed_annotation.dart';

import 'clock.dart';
import 'endgame_position.dart';
import 'game_setup.dart';

part 'journey.freezed.dart';

/// Contra quem se joga um desafio: o Maia num nível ou o Stockfish.
@freezed
abstract class OpponentRef with _$OpponentRef {
  const factory OpponentRef({required OpponentKind kind, int? level}) =
      _OpponentRef;

  const OpponentRef._();

  /// Lê `maia:1200` ou `stockfish`. Nulo se o texto não for nenhum dos dois.
  static OpponentRef? tryParse(String? code) {
    if (code == 'stockfish') {
      return const OpponentRef(kind: OpponentKind.stockfish);
    }
    final match = RegExp(r'^maia:(\d+)$').firstMatch(code ?? '');
    if (match == null) return null;
    return OpponentRef(
      kind: OpponentKind.maia,
      level: int.parse(match.group(1)!),
    );
  }

  String get code =>
      kind == OpponentKind.maia ? 'maia:$level' : OpponentKind.stockfish.code;
}

/// Um desafio: uma posição do catálogo contra um adversário, com o objetivo
/// da posição. Também é a forma de uma etapa de speedrun.
@freezed
abstract class Challenge with _$Challenge {
  const factory Challenge({
    /// Estável entre versões: o histórico e o domínio são gravados por ele.
    required String id,
    required EndgamePosition position,
    required OpponentRef opponent,

    /// O tempo de cada lado. Nulo: sem relógio.
    TimeControl? time,
  }) = _Challenge;

  const Challenge._();

  PositionGoal get goal => position.goal;
}

/// Um degrau da Jornada: os desafios contra um adversário (o Maia de um nível
/// ou, no último, o Stockfish).
@freezed
abstract class Rung with _$Rung {
  const factory Rung({
    /// `1000`, `1200`... e `stockfish`.
    required String id,
    required OpponentRef opponent,
    required List<Challenge> challenges,
  }) = _Rung;
}

/// A situação de um degrau para o jogador.
enum RungStatus {
  /// O degrau anterior ainda não foi concluído.
  locked,

  /// Liberado, com desafios por concluir.
  open,

  /// Todos os desafios concluídos.
  completed,
}

/// Um degrau com o que o jogador já fez nele.
@freezed
abstract class RungProgress with _$RungProgress {
  const factory RungProgress({
    required Rung rung,
    required RungStatus status,

    /// Os desafios concluídos deste degrau.
    required Set<String> completed,
  }) = _RungProgress;

  const RungProgress._();

  int get remaining => rung.challenges.length - completed.length;
}

/// A Jornada inteira com o progresso do jogador.
@freezed
abstract class JourneyProgress with _$JourneyProgress {
  const factory JourneyProgress({
    required List<RungProgress> rungs,

    /// O degrau por onde o jogador começou (o escolhido no tour).
    @Default(0) int start,
  }) = _JourneyProgress;

  const JourneyProgress._();

  /// Onde o jogador está: o primeiro degrau liberado e não concluído, a
  /// partir do degrau de início. Nulo quando a Jornada inteira foi concluída.
  RungProgress? get current {
    for (final rung in [...rungs.skip(start), ...rungs.take(start)]) {
      if (rung.status == RungStatus.open) return rung;
    }
    return null;
  }

  /// O degrau depois de [current]. Nulo se não há.
  RungProgress? get next {
    final current = this.current;
    if (current == null) return null;
    final index = rungs.indexOf(current);
    return index + 1 < rungs.length ? rungs[index + 1] : null;
  }

  RungProgress? rung(String id) {
    for (final rung in rungs) {
      if (rung.rung.id == id) return rung;
    }
    return null;
  }

  /// O degrau antes de [id]: é ele que precisa ser concluído para liberar.
  RungProgress? before(String id) {
    final index = rungs.indexWhere((rung) => rung.rung.id == id);
    return index > 0 ? rungs[index - 1] : null;
  }
}
