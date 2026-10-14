import 'package:dartchess/dartchess.dart';

import '../models/endgame_lesson.dart';
import '../models/explanation.dart';
import '../models/variation_tree.dart';
import 'game_rules.dart';

/// Um lance da notação do exercício (linha principal ou variante), com a
/// posição de antes e de depois e o que o Viktor diz dele.
class ReviewNode {
  const ReviewNode({
    required this.id,
    required this.san,
    required this.uci,
    required this.number,
    required this.side,
    required this.depth,
    required this.fenBefore,
    required this.fenAfter,
    this.startsVariant = false,
    this.symbol,
    this.result,
    this.previousId,
    this.comments = const [],
  });

  final String id;
  final String san;
  final String uci;

  /// O número do lance completo e quem o joga.
  final int number;
  final Side side;

  /// 0 é a linha principal; cada parêntese soma um.
  final int depth;
  final String fenBefore;
  final String fenAfter;

  /// Abre uma variante logo depois de outra, no mesmo nível: `) (`.
  final bool startsVariant;

  /// `!`, `?` ou `??`, colado ao lance.
  final String? symbol;

  /// O resultado que fecha a linha (`1–0`, `0–1`, `½–½`).
  final String? result;

  /// O lance que o aluno precisa ter visto antes deste (o anterior na mesma
  /// linha; na 1ª jogada da variante, o lance da principal que ela troca é
  /// o anterior dele). Nulo no começo.
  final String? previousId;

  /// O que o Viktor diz deste lance; vazio: ele só diz a solução.
  final List<String> comments;

  ReviewNode copyWith({
    int? depth,
    bool? startsVariant,
    String? result,
    String? previousId,
    String? symbol,
    List<String>? comments,
  }) => ReviewNode(
    id: id,
    san: san,
    uci: uci,
    number: number,
    side: side,
    depth: depth ?? this.depth,
    fenBefore: fenBefore,
    fenAfter: fenAfter,
    startsVariant: startsVariant ?? this.startsVariant,
    symbol: symbol ?? this.symbol,
    result: result ?? this.result,
    previousId: previousId ?? this.previousId,
    comments: comments ?? this.comments,
  );
}

/// Um lance errado do aluno (a vez, de 0, e o lance em UCI), com a
/// explicação, se há.
typedef ReviewWrong = ({int turn, String uci, List<String> comments});

/// A notação de um exercício (T72): a linha jogada e, no fim, a linha toda
/// com as variantes previstas, o que o aluno errou e as outras soluções.
abstract final class ExerciseReview {
  static String _key(String fen) => fen.split(' ').take(3).join(' ');

  /// Número do lance seguido de um lance (`1.Rc6`, `1...Rb8`, `1.d3?`) ou um
  /// lance com a peça (`Rxb7`, `Cf3`): notação, que o balão nunca mostra.
  static final _notation = RegExp(
    r'\d+\s?(?:\.{1,3}|…)\s?(?:[KQRBNDTC]?x?[a-h][1-8]|O-O)|'
    r'(?<![\p{L}\d])[KQRBNDTC]x?[a-h][1-8](?![\p{L}\d])',
    unicode: true,
  );

  /// O texto traz notação de lances (que não vai ao balão).
  static bool hasNotation(String text) => _notation.hasMatch(text);

  /// Os textos sem notação: um comentário com lances escritos fica de fora e
  /// o balão usa a frase gerada do lance.
  static List<String> withoutNotation(List<String> texts) => [
    for (final text in texts)
      if (!hasNotation(text)) text,
  ];

  /// O texto sem os parágrafos com notação (e sem o título que ficou sem
  /// lista, como "Também não funcionam:"). Nulo se nada sobra.
  static String? plainParagraphs(String? text) {
    if (text == null) return null;
    final kept = [
      for (final paragraph in text.split(RegExp(r'\n\s*\n')))
        if (paragraph.trim().isNotEmpty && !hasNotation(paragraph))
          paragraph.trim(),
    ];
    while (kept.isNotEmpty && kept.last.endsWith(':')) {
      kept.removeLast();
    }
    return kept.isEmpty ? null : kept.join('\n\n');
  }

  /// Os lances da notação que o aluno errou (na ordem da lista): o do erro
  /// escrito por ele ou, se a aula já previa o lance, a variante igual.
  static List<String> wrongNodeIds(
    List<ReviewNode> review,
    List<ReviewWrong> wrongs,
  ) {
    final students = [
      for (final node in review)
        if (node.depth == 0 && node.symbol == '!') node,
    ];
    final ids = <String>{};
    for (final wrong in wrongs) {
      if (wrong.turn >= students.length) continue;
      final before = students[wrong.turn].fenBefore;
      for (final node in review) {
        if (node.depth > 0 &&
            node.uci == wrong.uci &&
            _key(node.fenBefore) == _key(before)) {
          ids.add(node.id);
          break;
        }
      }
    }
    return [
      for (final node in review)
        if (ids.contains(node.id)) node.id,
    ];
  }

  /// Resultado de uma posição que acabou, em notação de livro.
  static String? resultOf(Position position) {
    final end = GameRules.endOf(position);
    if (end == null) return null;
    return switch (end.winner) {
      Side.white => '1–0',
      Side.black => '0–1',
      null => '½–½',
    };
  }

  /// Os lances do exercício na ordem em que são jogados: cada vez do aluno e,
  /// se há, a resposta. Só o que cabe em [played].
  static List<({String uci, int turn, bool student})> _walk(
    Exercise exercise,
    List<String> played,
  ) {
    final steps = <({String uci, int turn, bool student})>[];
    var index = 0;
    for (final (turn, each) in exercise.line.indexed) {
      if (index >= played.length) break;
      steps.add((uci: played[index++], turn: turn, student: true));
      if (each.reply != null) {
        if (index >= played.length) break;
        steps.add((uci: played[index++], turn: turn, student: false));
      }
    }
    return steps;
  }

  /// A linha jogada, sem variantes: os lances do aluno com "!" e a resposta
  /// do outro lado, como na lista durante o exercício.
  static List<ReviewNode> mainLine(
    Exercise exercise,
    List<String> played, {
    ExplanationPayload? payload,
  }) {
    var position = GameRules.fromFen(exercise.fen);
    if (position == null) return const [];
    final nodes = <ReviewNode>[];
    for (final step in _walk(exercise, played)) {
      final move = Move.parse(step.uci);
      final result = move == null ? null : GameRules.play(position!, move);
      if (result == null) break;
      final before = position!;
      position = result.position;
      nodes.add(
        ReviewNode(
          id: 'm${nodes.length}',
          san: result.san,
          uci: step.uci,
          number: before.fullmoves,
          side: before.turn,
          depth: 0,
          fenBefore: before.fen,
          fenAfter: position.fen,
          symbol: step.student ? '!' : null,
          previousId: nodes.isEmpty ? null : nodes.last.id,
          comments: commentFor(payload, before.fen, step.uci),
        ),
      );
    }
    if (nodes.isNotEmpty) {
      final last = nodes.last;
      nodes[nodes.length - 1] = last.copyWith(result: resultOf(position!));
    }
    return nodes;
  }

  /// O comentário de um lance, achado nas variantes escritas na aula: a
  /// explicação daquele lance, ou a da variante.
  static List<String> commentFor(
    ExplanationPayload? payload,
    String fenBefore,
    String uci,
  ) {
    if (payload == null) return const [];
    for (final variation in payload.variations) {
      Position? position = GameRules.fromFen(variation.originFen);
      if (position == null) continue;
      for (final (index, each) in variation.movesUci.indexed) {
        final move = Move.parse(each);
        if (move == null || !position!.isLegal(move)) break;
        if (_key(position.fen) == _key(fenBefore) && each == uci) {
          final texts = withoutNotation(
            variation.explanationByPly[index + 1] ?? const [],
          );
          if (texts.isNotEmpty) return texts;
          final own = withoutNotation(variation.texts);
          if (own.isNotEmpty) return own;
        }
        position = position.play(move);
      }
    }
    return const [];
  }

  /// Os lances que faltam para terminar o exercício, em UCI, a partir do
  /// que já foi jogado: o aceito primeiro de cada vez e a resposta.
  static List<String> remaining(Exercise exercise, List<String> played) {
    final steps = _walk(exercise, played);
    final out = <String>[];
    var turn = 0;
    if (steps.isNotEmpty) {
      final last = steps.last;
      turn = last.turn + 1;
      final reply = exercise.line[last.turn].reply;
      if (last.student && reply != null) out.add(reply);
    }
    for (var t = turn; t < exercise.line.length; t++) {
      final each = exercise.line[t];
      out.add(each.accept.first);
      if (each.reply != null) out.add(each.reply!);
    }
    return out;
  }

  /// A linha toda: a jogada (com o que faltou), as variantes previstas, as
  /// outras soluções e os lances errados do aluno, como no canvas.
  static List<ReviewNode> full(
    Exercise exercise,
    List<String> played, {
    ExplanationPayload? payload,
    List<ReviewWrong> wrongs = const [],
  }) {
    final main = mainLine(exercise, played, payload: payload);
    final children = <String, List<List<ReviewNode>>>{};
    var serial = 0;

    List<ReviewNode> build({
      required ReviewNode anchor,
      required String originFen,
      required List<String> ucis,
      required String prefix,
      String? firstSymbol,
      bool draw = false,
      Map<int, List<String>> byPly = const {},
      List<String> texts = const [],
    }) {
      var position = GameRules.fromFen(originFen);
      if (position == null) return const [];
      final line = <ReviewNode>[];
      final id = '$prefix${serial++}';
      for (final (index, uci) in ucis.indexed) {
        final move = Move.parse(uci);
        final result = move == null ? null : GameRules.play(position!, move);
        if (result == null) return const [];
        final before = position!;
        position = result.position;
        line.add(
          ReviewNode(
            id: '$id.$index',
            san: result.san,
            uci: uci,
            number: before.fullmoves,
            side: before.turn,
            depth: anchor.depth + 1,
            fenBefore: before.fen,
            fenAfter: position.fen,
            symbol: index == 0 ? firstSymbol : null,
            previousId: index == 0 ? anchor.previousId : line.last.id,
            comments: withoutNotation(
              byPly[index + 1] ?? (index == 0 ? texts : const []),
            ),
          ),
        );
      }
      if (line.isEmpty) return const [];
      line[line.length - 1] = line.last.copyWith(
        result: draw ? '½–½' : resultOf(position!),
      );
      return line;
    }

    void attach(ReviewNode anchor, List<ReviewNode> line) {
      if (line.isEmpty) return;
      final siblings = children.putIfAbsent(anchor.id, () => []);
      if (siblings.any((other) => other.first.uci == line.first.uci)) return;
      if (anchor.uci == line.first.uci) return;
      siblings.add(line);
    }

    // As variantes escritas na aula.
    final lines = <String, List<ReviewNode>>{};
    if (payload != null) {
      for (final variation in payload.variations) {
        if (!variation.validated || variation.movesUci.isEmpty) continue;
        ReviewNode? anchor;
        if (variation.parentId == null) {
          for (final node in main) {
            if (_key(node.fenBefore) == _key(variation.originFen)) {
              anchor = node;
              break;
            }
          }
        } else {
          final parent = lines[variation.parentId];
          final ply = variation.parentPly;
          if (parent != null && ply != null && ply < parent.length) {
            anchor = parent[ply];
          }
        }
        if (anchor == null) continue;
        final line = build(
          anchor: anchor,
          originFen: variation.originFen,
          ucis: variation.movesUci,
          prefix: 'v',
          firstSymbol: switch (variation.outcome) {
            VariationOutcome.accepted => '!',
            VariationOutcome.losing => '??',
            VariationOutcome.doesNotMeetGoal => '?',
          },
          draw: variation.result == VariationResult.draw,
          byPly: variation.explanationByPly,
          texts: variation.texts,
        );
        if (line.isEmpty) continue;
        lines[variation.id] = line;
        attach(anchor, line);
      }
    }

    // As outras soluções aceitas na mesma vez.
    var index = 0;
    for (final step in _walk(exercise, played)) {
      if (step.student) {
        final anchor = main[index];
        for (final uci in exercise.line[step.turn].accept) {
          if (uci == step.uci) continue;
          final line = build(
            anchor: anchor,
            originFen: anchor.fenBefore,
            ucis: [uci],
            prefix: 'a',
            firstSymbol: '!',
            texts: commentFor(payload, anchor.fenBefore, uci),
          );
          attach(anchor, line);
        }
        // Os erros do aluno nesta vez.
        for (final wrong in wrongs) {
          if (wrong.turn != step.turn) continue;
          final line = build(
            anchor: anchor,
            originFen: anchor.fenBefore,
            ucis: [wrong.uci],
            prefix: 'w',
            firstSymbol: '?',
            texts: withoutNotation(wrong.comments).isNotEmpty
                ? withoutNotation(wrong.comments)
                : commentFor(payload, anchor.fenBefore, wrong.uci),
          );
          attach(anchor, line);
        }
      }
      index++;
    }

    final out = <ReviewNode>[];
    void emitChildren(ReviewNode node) {
      for (final (index, branch) in (children[node.id] ?? const []).indexed) {
        for (final (i, each) in branch.indexed) {
          out.add(
            i == 0 && index > 0 ? each.copyWith(startsVariant: true) : each,
          );
          emitChildren(each);
        }
      }
    }

    for (final node in main) {
      out.add(node);
      emitChildren(node);
    }
    return out;
  }
}
