import 'package:dartchess/dartchess.dart';

import '../use_cases/game_rules.dart';

/// A legal source line, independent from lesson judgements and completion.
class LearningAnalysisLaunch {
  const LearningAnalysisLaunch({
    required this.fen,
    this.moves = const [],
    this.orientation = Side.white,
    this.selected,
  });
  final String fen;
  final List<String> moves;
  final Side orientation;

  /// O lance em que a análise abre (índice do nó: 1 é o primeiro lance). Nulo
  /// abre no último. Vale a cada abertura, por cima da sessão guardada.
  final int? selected;
  String get id => '$fen|${moves.join(',')}|${orientation.name}';
}

/// A marca de um lance na notação (Treinador, T87): o sufixo de erro ("?",
/// "??") em vermelho e o comentário logo depois do lance, como no Lichess.
class AnalysisAnnotation {
  const AnalysisAnnotation({this.suffix, this.comment});
  final String? suffix;
  final String? comment;
}

class LearningAnalysisSettings {
  const LearningAnalysisSettings({this.showEngine = true, this.lines = 2});
  final bool showEngine;
  final int lines;
  Map<String, Object> toJson() => {'showEngine': showEngine, 'lines': lines};
  static LearningAnalysisSettings fromJson(Map<String, dynamic> json) =>
      LearningAnalysisSettings(
        showEngine: json['showEngine'] as bool? ?? true,
        lines: (json['lines'] as int? ?? 2).clamp(1, 3),
      );
}

class LearningAnalysisNode {
  const LearningAnalysisNode({
    required this.fen,
    this.parent,
    this.uci,
    this.san,
  });
  final String fen;
  final int? parent;
  final String? uci;
  final String? san;
  Map<String, Object?> toJson() => {
    'fen': fen,
    'parent': parent,
    'uci': uci,
    'san': san,
  };
}

/// Parent indices form a tree. Existing continuations are never overwritten.
class LearningAnalysisSession {
  LearningAnalysisSession({
    required List<LearningAnalysisNode> nodes,
    required this.selected,
  }) : nodes = List.unmodifiable(nodes);
  factory LearningAnalysisSession.start(LearningAnalysisLaunch launch) {
    var position = GameRules.fromFen(launch.fen);
    if (position == null) throw ArgumentError.value(launch.fen, 'fen');
    final nodes = [LearningAnalysisNode(fen: position.fen)];
    for (final uci in launch.moves) {
      final move = Move.parse(uci);
      final played = move == null ? null : GameRules.play(position!, move);
      if (played == null) break;
      nodes.add(
        LearningAnalysisNode(
          fen: played.position.fen,
          parent: nodes.length - 1,
          uci: uci,
          san: played.san,
        ),
      );
      position = played.position;
    }
    final last = nodes.length - 1;
    final pick = launch.selected;
    return LearningAnalysisSession(
      nodes: nodes,
      selected: pick == null || pick < 0 || pick > last ? last : pick,
    );
  }
  final List<LearningAnalysisNode> nodes;
  final int selected;
  LearningAnalysisNode get current => nodes[selected];
  List<int> children(int parent) => [
    for (var i = 1; i < nodes.length; i++)
      if (nodes[i].parent == parent) i,
  ];
  LearningAnalysisSession select(int index) =>
      LearningAnalysisSession(nodes: nodes, selected: index);
  Map<String, Object> toJson() => {
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'selected': selected,
  };
  static LearningAnalysisSession fromJson(Map<String, dynamic> json) {
    final raw = json['nodes'] as List;
    final nodes = <LearningAnalysisNode>[];
    for (final value in raw) {
      final row = value as Map<String, dynamic>;
      final fen = row['fen'] as String;
      final parent = row['parent'] as int?;
      if (GameRules.fromFen(fen) == null ||
          (nodes.isEmpty
              ? parent != null
              : parent == null || parent < 0 || parent >= nodes.length)) {
        throw const FormatException('Invalid analysis tree');
      }
      if (parent != null) {
        final uci = row['uci'] as String;
        final move = Move.parse(uci);
        final played = move == null
            ? null
            : GameRules.play(GameRules.fromFen(nodes[parent].fen)!, move);
        if (played == null || played.position.fen != fen) {
          throw const FormatException('Illegal analysis move');
        }
        nodes.add(
          LearningAnalysisNode(
            fen: fen,
            parent: parent,
            uci: uci,
            san: played.san,
          ),
        );
      } else {
        nodes.add(LearningAnalysisNode(fen: fen));
      }
    }
    final selected = json['selected'] as int;
    if (selected < 0 || selected >= nodes.length) {
      throw const FormatException('Invalid cursor');
    }
    return LearningAnalysisSession(nodes: nodes, selected: selected);
  }
}
