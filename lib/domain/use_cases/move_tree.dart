import 'package:dartchess/dartchess.dart';

import '../models/lesson_script.dart';
import 'game_rules.dart';

/// De onde vêm os passos de um trecho do exemplo (T70).
abstract final class ScriptTracks {
  static const entry = 'entrada';
  static const main = 'main';
  static const reveal = 'reveal';
  static const altPrefix = 'alt:';

  static String alt(String uci) => '$altPrefix$uci';

  /// Os passos da trilha [key] do exemplo [example]:
  /// - `entrada`: a conversa antes da pergunta;
  /// - `main`: o lance certo e a linha (sem pergunta, só a linha);
  /// - `reveal`: "Ver resposta" e a linha;
  /// - `alt:<uci>`: a explicação do alternativo, o lance certo e a linha.
  static List<ScriptStep> steps(ScriptExample example, String key) {
    final question = example.question;
    if (key == entry) return example.entry;
    if (question == null) return example.line;
    if (key == reveal) return [question.reveal, ...example.line];
    if (key.startsWith(altPrefix)) {
      final uci = key.substring(altPrefix.length);
      return [
        ...question.alternatives[uci] ?? const [],
        question.rightStep,
        ...example.line,
      ];
    }
    return [question.rightStep, ...example.line];
  }
}

/// O passo que um lance da lista abre: trilha e índice nela.
class ScriptRef {
  const ScriptRef(this.track, this.index);

  final String track;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is ScriptRef && other.track == track && other.index == index;

  @override
  int get hashCode => Object.hash(track, index);

  @override
  String toString() => '$track#$index';
}

/// Um lance da lista de lances.
class MoveNode {
  const MoveNode({
    required this.id,
    required this.uci,
    required this.san,
    required this.number,
    required this.side,
    required this.variant,
    required this.ref,
    required this.step,
  });

  /// O caminho de UCIs desde o início, ligados por `-` (único no exemplo).
  final String id;
  final String uci;
  final String san;

  /// O número do lance completo (`1` em `1.e4`).
  final int number;

  /// Quem jogou.
  final Side side;

  /// Faz parte de uma variante (alternativo).
  final bool variant;

  /// O passo que a fala do lance mostra, na trilha natural dele.
  final ScriptRef ref;

  /// O passo (o mesmo objeto) que joga o lance: a trilha `reveal` mostra o
  /// lance do passo `certo` com outra fala.
  final ScriptStep step;
}

/// A árvore de lances de um exemplo (T70): só passos com `lance`/`seq`. O
/// alternativo vira variante; os erros e o jogo livre ficam de fora.
class MoveTree {
  const MoveTree(this.nodes);

  /// Na ordem da lista: a entrada, o lance certo, as variantes, a linha.
  final List<MoveNode> nodes;

  MoveNode? node(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// Os nós que o passo [step] joga (um por lance do `seq`).
  List<MoveNode> of(ScriptStep step) => [
    for (final node in nodes)
      if (identical(node.step, step)) node,
  ];

  static MoveTree build(ScriptExample example) {
    final nodes = <MoveNode>[];
    var path = <String>[];

    /// Anda por [steps] a partir de [fen]; devolve o caminho no fim.
    (List<String>, String) walk(
      List<ScriptStep> steps,
      String track,
      int offset,
      String fen,
      List<String> from,
      bool variant,
      List<MoveNode> into,
    ) {
      var current = fen;
      var trail = from;
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        if (variant && step.jump) break;
        if (step.hasMove) {
          var position = GameRules.fromFen(current);
          for (final uci in step.moves) {
            final move = Move.parse(uci);
            final played = position == null || move == null
                ? null
                : GameRules.play(position, move);
            trail = [...trail, uci];
            into.add(
              MoveNode(
                id: trail.join('-'),
                uci: uci,
                san: played?.san ?? uci,
                number: position?.fullmoves ?? 1,
                side: position?.turn ?? Side.white,
                variant: variant,
                ref: ScriptRef(track, offset + i),
                step: step,
              ),
            );
            position = played?.position;
          }
        }
        current = step.fen;
      }
      return (trail, current);
    }

    final (entryPath, entryFen) = walk(
      example.entry,
      ScriptTracks.entry,
      0,
      example.fen,
      path,
      false,
      nodes,
    );
    path = entryPath;
    final question = example.question;
    if (question == null) {
      walk(example.line, ScriptTracks.main, 0, entryFen, path, false, nodes);
      return MoveTree(nodes);
    }
    final main = <MoveNode>[];
    walk(
      ScriptTracks.steps(example, ScriptTracks.main),
      ScriptTracks.main,
      0,
      entryFen,
      path,
      false,
      main,
    );
    final variants = <MoveNode>[];
    for (final uci in question.alternatives.keys) {
      walk(
        question.alternatives[uci]!,
        ScriptTracks.alt(uci),
        0,
        entryFen,
        path,
        true,
        variants,
      );
    }
    final head = main.isEmpty ? <MoveNode>[] : [main.first];
    final rest = main.length > 1 ? main.sublist(1) : <MoveNode>[];
    nodes
      ..addAll(head)
      ..addAll(variants)
      ..addAll(rest);
    return MoveTree(nodes);
  }
}
