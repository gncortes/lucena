import 'package:dartchess/dartchess.dart';

import '../models/lesson_script.dart';
import 'script_moves.dart';

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
  const MoveTree(
    this.nodes, [
    this._anchors = const {},
    this._repeats = const {},
  ]);

  /// Na ordem da lista: a entrada, o lance certo, as variantes, a linha.
  final List<MoveNode> nodes;

  /// Onde cai cada passo de salto sem lance: o nó da posição dele (nulo: a
  /// posição de partida).
  final Map<ScriptStep, String?> _anchors;

  /// Os passos que repetem um lance já na lista (depois de um salto): os nós
  /// que eles jogam de novo.
  final Map<ScriptStep, List<String>> _repeats;

  /// O passo [step] é um salto que a árvore situou.
  bool anchors(ScriptStep step) => _anchors.containsKey(step);

  /// O nó em que o salto [step] cai (nulo: a posição de partida).
  String? anchorOf(ScriptStep step) => _anchors[step];

  MoveNode? node(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// Os nós que o passo [step] joga (um por lance do `seq`).
  List<MoveNode> of(ScriptStep step) {
    final own = [
      for (final node in nodes)
        if (identical(node.step, step)) node,
    ];
    final again = _repeats[step];
    if (again == null) return own;
    return [...again.map(node).nonNulls, ...own];
  }

  static int _fullmoves(String fen) =>
      int.tryParse(fen.split(' ').elementAtOrNull(5) ?? '') ?? 1;

  static Side _turn(String fen) =>
      fen.split(' ').elementAtOrNull(1) == 'b' ? Side.black : Side.white;

  /// O tabuleiro e a vez de [fen] (o que conta para achar a posição); na
  /// tarefa ([board]), só o tabuleiro: a vez da FEN do roteiro pode passar
  /// ou não.
  static String _key(String fen, {bool board = false}) =>
      fen.split(' ').take(board ? 1 : 2).join(' ');

  static MoveTree build(ScriptExample example) {
    final nodes = <MoveNode>[];
    var path = <String>[];
    final task = example.goal == ScriptGoal.tarefa;
    final anchors = Map<ScriptStep, String?>.identity();
    final repeats = Map<ScriptStep, List<String>>.identity();

    /// A posição depois de cada lance (pelo id; '' é a de partida), se ele é
    /// variante e o primeiro filho de cada lance (a linha principal).
    final fenOf = <String, String>{'': example.fen};
    final variantOf = <String, bool>{};
    final mainChild = <String, String>{};

    /// Um salto sem lance (T70, "volte um lance; imagine..."): cai num lance
    /// já jogado do caminho ou a um lance dele, que entra na lista. Devolve
    /// o caminho novo e o lance que entrou, se entrou.
    (List<String>, String?) land(List<String> trail, String fen) {
      final target = _key(fen, board: task);
      for (var n = trail.length; n >= 0; n--) {
        final prefix = trail.sublist(0, n);
        final at = fenOf[prefix.join('-')];
        if (at != null && _key(at, board: task) == target) {
          return (prefix, null);
        }
      }
      for (var n = trail.length; n >= 0; n--) {
        final prefix = trail.sublist(0, n);
        final at = fenOf[prefix.join('-')];
        if (at == null) continue;
        for (final MapEntry(key: from, value: tos) in ScriptMoves.dests(
          at,
        ).entries) {
          for (final to in tos) {
            final uci = NormalMove(from: from, to: to).uci;
            final played = ScriptMoves.play(at, uci, keepTurn: task);
            if (played != null && _key(played.fen, board: task) == target) {
              return (prefix, uci);
            }
          }
        }
      }
      return (trail, null);
    }

    /// Na tarefa: quantos lances do aluno há até cada lance (pelo id).
    final studentMoves = <String, int>{};
    final moverSides = <String, Side>{};

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
        var moves = step.moves;
        if (step.jump && !step.hasMove) {
          final (landed, implied) = land(trail, step.fen);
          trail = landed;
          current = fenOf[landed.join('-')] ?? current;
          if (implied == null) {
            anchors[step] = landed.isEmpty ? null : landed.join('-');
          } else {
            moves = [implied];
          }
        }
        if (moves.isNotEmpty) {
          var at = current;
          for (final uci in moves) {
            final played = ScriptMoves.play(at, uci, keepTurn: task);
            // Na tarefa, o lance das pretas fica com o número do lance das
            // brancas que veio antes (a captura de volta, ou a resposta ao
            // aluno de pretas).
            final mover = task ? ScriptMoves.moverOf(at, uci) : null;
            final parent = trail.join('-');
            final count = ScriptMoves.taskNumber(
              mover: mover ?? example.student,
              parentNumber: trail.isEmpty
                  ? null
                  : studentMoves[parent] ?? trail.length,
              parentSide: moverSides[parent],
            );
            final again = [...trail, uci].join('-');
            if (fenOf[again] case final seen?) {
              // O lance já está na lista (a linha voltou por um salto).
              (repeats[step] ??= []).add(again);
              trail = [...trail, uci];
              at = seen;
              continue;
            }
            // Outro lance onde a linha já seguiu (ou dentro de uma variante)
            // é variante: a lista abre o parêntese.
            final branch =
                variant ||
                (variantOf[parent] ?? false) ||
                (mainChild[parent] ?? uci) != uci;
            trail = [...trail, uci];
            studentMoves[trail.join('-')] = count;
            moverSides[trail.join('-')] = mover ?? example.student;
            into.add(
              MoveNode(
                id: trail.join('-'),
                uci: uci,
                san: played?.san ?? uci,
                // Na tarefa a vez não passa: os lances só se numeram.
                number: task ? count : _fullmoves(at),
                side: task ? (mover ?? example.student) : _turn(at),
                variant: branch,
                ref: ScriptRef(track, offset + i),
                step: step,
              ),
            );
            at = played?.fen ?? at;
            final id = trail.join('-');
            fenOf[id] = at;
            variantOf[id] = branch;
            if (!branch) mainChild[parent] ??= uci;
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
      return MoveTree(nodes, anchors, repeats);
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
    return MoveTree(nodes, anchors, repeats);
  }
}
