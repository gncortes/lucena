import 'package:dartchess/dartchess.dart';

import 'game_review.dart';

/// Em que pé está a análise a fundo de uma partida.
enum DeepAnalysisStatus { running, done, failed }

/// O pedido de análise a fundo de uma partida: de onde ela começa, os lances
/// e o quanto a engine trabalha em cada posição.
class DeepAnalysisRequest {
  const DeepAnalysisRequest({
    required this.gameId,
    required this.start,
    required this.moves,
    required this.weight,
    required this.depth,
    required this.time,
  });

  final int gameId;
  final Position start;
  final List<Move> moves;

  /// O peso da revisão (ver [ReviewedMove.weight]).
  final int weight;
  final int depth;
  final Duration time;
}

/// Um retrato do trabalho de análise a fundo de uma partida. Só existe na
/// memória: fechar o app à força o descarta, e a análise recomeça do zero
/// quando o usuário pedir de novo.
class DeepAnalysisJob {
  const DeepAnalysisJob({
    required this.gameId,
    required this.weight,
    required this.status,
    required this.progress,
    required this.startedAt,
    this.finishedAt,
    this.review,
  });

  final int gameId;
  final int weight;
  final DeepAnalysisStatus status;

  /// De 0 a 1.
  final double progress;
  final DateTime startedAt;
  final DateTime? finishedAt;

  /// A revisão pronta (só com [DeepAnalysisStatus.done]).
  final GameReview? review;

  bool get running => status == DeepAnalysisStatus.running;

  DeepAnalysisJob copyWith({
    DeepAnalysisStatus? status,
    double? progress,
    DateTime? finishedAt,
    GameReview? review,
  }) => DeepAnalysisJob(
    gameId: gameId,
    weight: weight,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    startedAt: startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    review: review ?? this.review,
  );
}
