import 'featured.dart';

enum FindMovePhase { asking, wrong, solved, revealed }

/// Progresso local válido somente para esta posição e estas soluções.
class FindMoveCheckpoint {
  const FindMoveCheckpoint({
    required this.fen,
    required this.solutions,
    this.phase = FindMovePhase.asking,
    this.hint = false,
    this.attempts = 0,
  });

  final String fen;
  final List<String> solutions;
  final FindMovePhase phase;
  final bool hint;
  final int attempts;

  bool matches(FeaturedEndgame endgame) =>
      fen == endgame.fen &&
      solutions.length == endgame.solutions.length &&
      Iterable<int>.generate(solutions.length)
          .every((index) => solutions[index] == endgame.solutions[index]);

  Map<String, Object> toJson() => {
    'version': 1,
    'fen': fen,
    'solutions': solutions,
    'phase': phase.name,
    'hint': hint,
    'attempts': attempts,
  };

  factory FindMoveCheckpoint.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('Checkpoint version');
    final attempts = json['attempts'] as int;
    if (attempts < 0) throw const FormatException('Checkpoint attempts');
    return FindMoveCheckpoint(
      fen: json['fen'] as String,
      solutions: List<String>.from(json['solutions'] as List),
      phase: FindMovePhase.values.byName(json['phase'] as String),
      hint: json['hint'] as bool,
      attempts: attempts,
    );
  }
}
