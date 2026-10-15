import 'package:dartchess/dartchess.dart';

import 'variation_tree.dart';

enum ExplanationKind {
  context,
  playedIncorrect,
  playedCorrect,
  mainSolution,
  otherSolutions,
  failedAlternatives;

  static ExplanationKind parse(String value) => switch (value) {
    'played_incorrect' => playedIncorrect,
    'played_correct' => playedCorrect,
    'main_solution' => mainSolution,
    'other_solutions' => otherSolutions,
    'failed_alternatives' => failedAlternatives,
    'context' => context,
    _ => throw FormatException('Unknown explanation kind: $value'),
  };
}

enum ExplanationState { intro, incorrect, correct, review }

enum VariationOutcome { accepted, losing, doesNotMeetGoal }

List<String> explanationTexts(Object? value) => switch (value) {
  String s => s.trim().isEmpty ? const [] : [s],
  List list => List.unmodifiable(
    list.whereType<String>().where((s) => s.trim().isNotEmpty),
  ),
  _ => const [],
};

/// Authored content, independent of display and of the exercise attempt.
class ExplanationVariation {
  ExplanationVariation({
    required this.id,
    required this.label,
    required this.outcome,
    this.outcomeText,
    this.contextId,
    this.parentId,
    this.parentPly,
    required List<String> texts,
    List<String> playedTexts = const [],
    required this.originFen,
    required List<String> movesUci,
    required List<String> movesSan,
    this.validated = false,
    Map<int, List<String>> explanationByPly = const {},
    this.result,
  }) : texts = List.unmodifiable(texts),
       playedTexts = List.unmodifiable(playedTexts),
       movesUci = List.unmodifiable(movesUci),
       movesSan = List.unmodifiable(movesSan),
       explanationByPly = Map.unmodifiable({
         for (final e in explanationByPly.entries)
           e.key: List<String>.unmodifiable(e.value),
       });
  final String id, label, originFen;
  final VariationOutcome outcome;
  final String? outcomeText;

  /// O resultado da variante quando muda em relação à principal (`"draw"`);
  /// sem ele, a faixa não mostra símbolo (T68).
  final VariationResult? result;

  /// Authored identity and divergence; labels never determine ancestry.
  final String? contextId, parentId;
  final int? parentPly;
  final List<String> texts, movesUci, movesSan;

  /// Optional wording for when the student actually played this failed move
  /// ("With 1.Ke3? you let the win slip…"); [texts] stays the hypothetical
  /// wording used under "These do not work either".
  final List<String> playedTexts;
  final Map<int, List<String>> explanationByPly;
  final bool validated;
  String? get firstUci => movesUci.firstOrNull;

  factory ExplanationVariation.fromJson(Map<String, dynamic> json) =>
      ExplanationVariation(
        id: json['id'] as String,
        label: json['label'] as String,
        outcome: switch (json['outcome']) {
          'accepted' => VariationOutcome.accepted,
          'losing' => VariationOutcome.losing,
          'does_not_meet_goal' => VariationOutcome.doesNotMeetGoal,
          _ => throw const FormatException('Missing variation outcome'),
        },
        texts: explanationTexts(json['texts']),
        playedTexts: explanationTexts(json['playedTexts']),
        outcomeText: json['outcomeText'] as String?,
        contextId: json['contextId'] as String?,
        parentId: json['parentId'] as String?,
        parentPly: json['parentPly'] as int?,
        originFen: json['originFen'] as String,
        movesUci: explanationTexts(json['movesUci']),
        movesSan: explanationTexts(json['movesSan']),
        validated: json['validated'] == true,
        result: VariationResult.parse(json['result']),
        explanationByPly: {
          for (final e in ((json['explanationByPly'] as Map?) ?? {}).entries)
            ?int.tryParse(e.key.toString()): explanationTexts(e.value),
        },
      );

  /// Verify the entire line before exposing even its first move. Legal replay
  /// is a safety check, never evidence that the line meets the objective.
  VariationCursor? open() {
    if (!validated || movesUci.isEmpty || movesUci.length != movesSan.length) {
      return null;
    }
    try {
      Position position = Chess.fromSetup(Setup.parseFen(originFen));
      final fens = <String>[position.fen];
      final moves = <Move>[];
      for (final uci in movesUci) {
        final move = Move.parse(uci);
        if (move == null || !position.isLegal(move)) {
          return null;
        }
        moves.add(move);
        position = position.play(move);
        fens.add(position.fen);
      }
      return VariationCursor._(
        this,
        List.unmodifiable(fens),
        List.unmodifiable(moves),
        1,
      );
    } catch (_) {
      return null;
    }
  }
}

class VariationCursor {
  const VariationCursor._(this.variation, this.fens, this.moves, this.ply);
  final ExplanationVariation variation;
  final List<String> fens;
  final List<Move> moves;
  final int ply;
  String get fen => fens[ply];
  Move? get lastMove => ply == 0 ? null : moves[ply - 1];
  bool get canPrevious => ply > 0;
  bool get canNext => ply < moves.length;
  List<String> get texts => variation.explanationByPly[ply] ?? variation.texts;
  VariationCursor at(int value) =>
      VariationCursor._(variation, fens, moves, value.clamp(0, moves.length));
  VariationCursor previous() => at(ply - 1);
  VariationCursor next() => at(ply + 1);
}

class ExplanationBlock {
  ExplanationBlock({
    required this.id,
    required this.kind,
    this.title = '',
    List<String> texts = const [],
    List<ExplanationVariation> variations = const [],
  }) : texts = List.unmodifiable(texts),
       variations = List.unmodifiable(variations);
  final String id, title;
  final ExplanationKind kind;
  final List<String> texts;
  final List<ExplanationVariation> variations;
  bool get isEmpty => texts.isEmpty && variations.isEmpty;
  ExplanationBlock withVariations(List<ExplanationVariation> value) =>
      ExplanationBlock(
        id: id,
        kind: kind,
        title: title,
        texts: texts,
        variations: value,
      );
  factory ExplanationBlock.fromJson(Map<String, dynamic> json) =>
      ExplanationBlock(
        id: json['id'] as String,
        kind: ExplanationKind.parse(json['kind'] as String),
        title: json['title'] as String? ?? '',
        texts: explanationTexts(json['texts']),
        variations: [
          for (final v in (json['variations'] as List? ?? []))
            ExplanationVariation.fromJson(Map<String, dynamic>.from(v as Map)),
        ],
      );
}

class ExplanationPayload {
  ExplanationPayload({
    required this.positionId,
    this.reviewStepId,
    required this.state,
    required List<ExplanationBlock> explanations,
  }) : explanations = List.unmodifiable(explanations.where((b) => !b.isEmpty));
  final String positionId;
  final String? reviewStepId;
  final ExplanationState state;
  final List<ExplanationBlock> explanations;
  Iterable<ExplanationVariation> get variations =>
      explanations.expand((block) => block.variations);

  /// Replay all ancestors. Transpositions are separate identities, never edges
  /// inferred from matching boards; clocks and side to move must also match.
  VariationCursor? openVariation(ExplanationVariation variation) {
    final byId = <String, ExplanationVariation>{};
    final duplicates = <String>{};
    for (final node in variations) {
      if (byId.containsKey(node.id)) duplicates.add(node.id);
      byId[node.id] = node;
    }
    final visiting = <String>{};
    VariationCursor? visit(ExplanationVariation node) {
      if (!identical(byId[node.id], node) ||
          duplicates.contains(node.id) ||
          !visiting.add(node.id)) {
        return null;
      }
      final cursor = node.open();
      if (cursor == null) return null;
      if (node.parentId == null) {
        return node.parentPly == null ? cursor : null;
      }
      final parent = byId[node.parentId];
      final ply = node.parentPly;
      if (parent == null ||
          ply == null ||
          (parent.contextId ?? positionId) != (node.contextId ?? positionId)) {
        return null;
      }
      final ancestor = visit(parent);
      if (ancestor == null ||
          ply < 0 ||
          ply >= ancestor.fens.length ||
          ancestor.fens[ply] != node.originFen) {
        return null;
      }
      return cursor;
    }

    return visit(variation);
  }

  List<ExplanationVariation> childrenOf(ExplanationVariation parent) => [
    for (final node in variations)
      if (node.parentId == parent.id && openVariation(node) != null) node,
  ];

  VariationCursor? parentCursor(ExplanationVariation child) {
    if (openVariation(child) == null || child.parentId == null) return null;
    final parent = variations.singleWhere((node) => node.id == child.parentId);
    return openVariation(parent)?.at(child.parentPly!);
  }

  List<ExplanationVariation> _tree(ExplanationVariation root) {
    // Do not turn an ambiguous authored identity into a valid tree by deduping.
    if (variations.where((node) => node.id == root.id).length != 1) return [];
    return [root, for (final child in childrenOf(root)) ..._tree(child)];
  }

  String _dedupKey(ExplanationVariation node) =>
      node.contextId != null ||
          node.parentId != null ||
          variations.any((child) => child.parentId == node.id)
      ? 'id:${node.id}'
      : '${node.originFen}|${node.firstUci}';
  factory ExplanationPayload.context(
    List<String> texts, {
    String positionId = '',
  }) => ExplanationPayload(
    positionId: positionId,
    state: ExplanationState.intro,
    explanations: [
      ExplanationBlock(
        id: 'context',
        kind: ExplanationKind.context,
        texts: texts,
      ),
    ],
  );
  factory ExplanationPayload.fromJson(Map<String, dynamic> json) =>
      ExplanationPayload(
        positionId: json['positionId'] as String? ?? '',
        reviewStepId: json['reviewStepId'] as String?,
        state: ExplanationState.values.byName(
          json['state'] as String? ?? 'review',
        ),
        explanations: [
          for (final b in (json['explanations'] as List? ?? []))
            ExplanationBlock.fromJson(Map<String, dynamic>.from(b as Map)),
        ],
      );

  /// A notation link follows the same verified origin as its explicit chip.
  VariationCursor? cursorForNotation(
    String notation, {
    ExplanationVariation? preferred,
    bool strictPreferred = false,
  }) {
    String normalize(String value) => value.replaceAll(RegExp(r'[?!\s]'), '');
    final wanted = normalize(notation);
    final numbered = RegExp(r'^\d+\.').hasMatch(wanted);
    for (final variation in [
      ?preferred,
      if (!strictPreferred) ...explanations.expand((b) => b.variations),
    ]) {
      final cursor = openVariation(variation);
      if (cursor == null) {
        continue;
      }
      for (final (index, san) in variation.movesSan.indexed) {
        var candidate = normalize(san);
        if (!numbered) {
          candidate = candidate.replaceFirst(RegExp(r'^\d+\.(?:\.\.)?'), '');
        }
        if (candidate == wanted) {
          return cursor.at(index + 1);
        }
      }
    }
    return null;
  }

  /// Selection changes presentation only; the authored objective is retained.
  ExplanationPayload forState(
    ExplanationState requested, {
    String? playedUci,
    ExplanationPayload? rejected,
  }) {
    final all = explanations;
    final blocks = <ExplanationBlock>[];
    final selected = <ExplanationVariation>[
      for (final b in all)
        if (b.kind == ExplanationKind.mainSolution ||
            b.kind == ExplanationKind.otherSolutions)
          for (final v in b.variations)
            if (v.parentId == null &&
                v.firstUci == playedUci &&
                v.outcome == VariationOutcome.accepted)
              v,
    ];
    final selectedSeen = <String>{};
    selected.removeWhere(
      (node) => _tree(node).isEmpty || !selectedSeen.add(_dedupKey(node)),
    );
    if (requested == ExplanationState.incorrect && rejected == null) {
      final authored = [
        for (final b in all)
          if (b.kind == ExplanationKind.failedAlternatives)
            for (final v in b.variations)
              if (v.parentId == null && v.firstUci == playedUci) v,
      ];
      final authoredSeen = <String>{};
      authored.removeWhere(
        (node) => _tree(node).isEmpty || !authoredSeen.add(_dedupKey(node)),
      );
      if (authored.isNotEmpty) {
        final v = authored.first;
        // Com fala própria do lance jogado, a hipótese ("Se as brancas
        // jogassem…") é a mesma ideia: a linha fica só com a fala do lance.
        ExplanationVariation played(ExplanationVariation node) =>
            node.playedTexts.isEmpty
            ? node
            : ExplanationVariation(
                id: node.id,
                label: node.label,
                outcome: node.outcome,
                outcomeText: node.outcomeText,
                contextId: node.contextId,
                parentId: node.parentId,
                parentPly: node.parentPly,
                texts: node.playedTexts,
                playedTexts: node.playedTexts,
                originFen: node.originFen,
                movesUci: node.movesUci,
                movesSan: node.movesSan,
                validated: node.validated,
                explanationByPly: node.explanationByPly,
                result: node.result,
              );
        rejected = ExplanationPayload(
          positionId: positionId,
          reviewStepId: reviewStepId,
          state: requested,
          explanations: [
            ExplanationBlock(
              id: 'played',
              kind: ExplanationKind.playedIncorrect,
              texts: v.playedTexts.isNotEmpty ? v.playedTexts : v.texts,
              variations: [
                for (final root in authored)
                  for (final node in _tree(root))
                    node == root ? played(node) : node,
              ],
            ),
          ],
        );
      }
    }
    if (requested == ExplanationState.incorrect && rejected != null) {
      blocks.addAll(
        rejected.explanations.map(
          (b) => ExplanationBlock(
            id: b.id,
            kind: ExplanationKind.playedIncorrect,
            title: b.title,
            texts: b.texts,
            variations: b.variations,
          ),
        ),
      );
    }
    if (requested == ExplanationState.correct && selected.isNotEmpty) {
      final v = selected.first;
      blocks.add(
        ExplanationBlock(
          id: 'played',
          kind: ExplanationKind.playedCorrect,
          texts: v.texts,
          variations: [for (final root in selected) ..._tree(root)],
        ),
      );
    }
    if (requested == ExplanationState.correct && selected.isNotEmpty) {
      final alternatives = <ExplanationVariation>[];
      final acceptedSeen = <String>{};
      for (final block in all) {
        if (block.kind != ExplanationKind.mainSolution &&
            block.kind != ExplanationKind.otherSolutions) {
          continue;
        }
        for (final variation in block.variations) {
          if (variation.parentId != null ||
              variation.firstUci == playedUci ||
              variation.outcome != VariationOutcome.accepted) {
            continue;
          }
          if (acceptedSeen.add(_dedupKey(variation))) {
            alternatives.addAll(_tree(variation));
          }
        }
      }
      if (alternatives.isNotEmpty) {
        blocks.add(
          ExplanationBlock(
            id: 'other-accepted',
            kind: ExplanationKind.otherSolutions,
            variations: alternatives,
          ),
        );
      }
    }
    final seen = <String>{};
    for (final b in all) {
      if (requested == ExplanationState.intro &&
          b.kind != ExplanationKind.context) {
        continue;
      }
      if (requested == ExplanationState.correct &&
          (b.kind == ExplanationKind.mainSolution ||
              b.kind == ExplanationKind.otherSolutions) &&
          selected.isNotEmpty) {
        continue;
      }
      if (b.kind == ExplanationKind.playedCorrect ||
          b.kind == ExplanationKind.playedIncorrect) {
        continue;
      }
      final variations = <ExplanationVariation>[];
      for (final v in b.variations) {
        if (v.parentId != null) continue;
        final key = _dedupKey(v);
        if ((b.kind == ExplanationKind.otherSolutions ||
                b.kind == ExplanationKind.failedAlternatives) &&
            v.firstUci == playedUci) {
          continue;
        }
        if (!seen.add(key)) {
          continue;
        }
        variations.addAll(_tree(v));
      }
      blocks.add(b.withVariations(variations));
    }
    final order = switch (requested) {
      ExplanationState.incorrect => [
        ExplanationKind.playedIncorrect,
        ExplanationKind.mainSolution,
        ExplanationKind.otherSolutions,
        ExplanationKind.failedAlternatives,
        ExplanationKind.context,
      ],
      ExplanationState.correct => [
        ExplanationKind.playedCorrect,
        ExplanationKind.mainSolution,
        ExplanationKind.otherSolutions,
        ExplanationKind.failedAlternatives,
        ExplanationKind.context,
      ],
      _ => [
        ExplanationKind.context,
        ExplanationKind.mainSolution,
        ExplanationKind.otherSolutions,
        ExplanationKind.failedAlternatives,
      ],
    };
    blocks.sort(
      (a, b) => order.indexOf(a.kind).compareTo(order.indexOf(b.kind)),
    );
    return ExplanationPayload(
      positionId: positionId,
      reviewStepId: reviewStepId ?? rejected?.reviewStepId,
      state: requested,
      explanations: blocks,
    );
  }
}
