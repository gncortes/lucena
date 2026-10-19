import '../models/assessment_attempt.dart';

/// Verified facts supplied by a private adapter. Missing facts mean not checked.
final class AssessmentSnapshotFacts {
  AssessmentSnapshotFacts({
    required this.ref,
    required this.visited,
    required this.complete,
    required this.studentKingSquare,
    required Map<AssessmentPiece, Set<String>> controls,
    required Map<AssessmentPiece, Set<String>> controlsAfterRelocation,
    required Map<AssessmentPiece, Set<String>> protections,
    Map<AssessmentPiece, Set<String>> checks = const {},
  }) : controls = _freeze(controls),
       controlsAfterRelocation = _freeze(controlsAfterRelocation),
       protections = _freeze(protections),
       checks = _freeze(checks);

  final String ref;
  final bool visited;
  final bool complete;
  final String studentKingSquare;
  final Map<AssessmentPiece, Set<String>> controls;
  final Map<AssessmentPiece, Set<String>> controlsAfterRelocation;
  final Map<AssessmentPiece, Set<String>> protections;
  final Map<AssessmentPiece, Set<String>> checks;
}

/// Restricted runtime evidence, never a response option or public UI state.
final class AssessmentFactsProvenance {
  AssessmentFactsProvenance({
    required this.providerVersion,
    required this.method,
    required this.rulesVersion,
    required this.descriptorVersion,
    required this.descriptorId,
    required Map<String, String> contentIdentity,
    required Map<String, String> sourceHashes,
    required this.attemptId,
    required this.revision,
    required this.historyIdentity,
    required this.initialFen,
    required this.gameFen,
    required this.student,
    required Map<String, ({int ply, String fen})> snapshots,
    required Map<String, String> domains,
  }) : contentIdentity = Map.unmodifiable(contentIdentity),
       sourceHashes = Map.unmodifiable(sourceHashes),
       snapshots = Map.unmodifiable(snapshots),
       domains = Map.unmodifiable(domains);

  final String providerVersion;
  final String method;
  final String rulesVersion;
  final String descriptorVersion;
  final String descriptorId;
  final Map<String, String> contentIdentity;
  final Map<String, String> sourceHashes;
  final String attemptId;
  final int revision;
  final String historyIdentity;
  final String initialFen;
  final String gameFen;
  final String student;
  final Map<String, ({int ply, String fen})> snapshots;
  final Map<String, String> domains;
  String get status => 'complete';
  String get reason => 'allVisitedFramesDerived';

  /// Stable address within the declared domain; not an assertion of truth.
  String factRef(
    String ref,
    AssessmentRelationKind kind,
    AssessmentPiece piece,
    String square,
  ) => '$ref/${kind.name}/${piece.name}/$square';
}

final class AssessmentFacts {
  AssessmentFacts({
    required this.initialSnapshotRef,
    required Map<String, AssessmentSnapshotFacts> snapshots,
    required Map<String, bool> bishopCompatibleCorners,
    required Iterable<String> supportedCorners,
    required Iterable<String> knownEscapeSquares,
    required Iterable<String> availableEscapes,
    required Iterable<String> blockedEscapes,
    required this.visitedHistoryFactsComplete,
    required this.protectionOpportunity,
    this.provenance,
  }) : snapshots = Map.unmodifiable(snapshots),
       bishopCompatibleCorners = Map.unmodifiable(bishopCompatibleCorners),
       supportedCorners = Set.unmodifiable(supportedCorners),
       knownEscapeSquares = Set.unmodifiable(knownEscapeSquares),
       availableEscapes = Set.unmodifiable(availableEscapes),
       blockedEscapes = Set.unmodifiable(blockedEscapes);

  final String initialSnapshotRef;
  final Map<String, AssessmentSnapshotFacts> snapshots;
  final Map<String, bool> bishopCompatibleCorners;
  final Set<String> supportedCorners;
  final Set<String> knownEscapeSquares;
  final Set<String> availableEscapes;
  final Set<String> blockedEscapes;
  final bool visitedHistoryFactsComplete;
  final bool protectionOpportunity;
  final AssessmentFactsProvenance? provenance;
}

final class AssessmentPairVerdict {
  const AssessmentPairVerdict({
    required this.relationId,
    required this.square,
    required this.piece,
    required this.component,
    required this.verdict,
    required this.reason,
    required this.contributes,
  });

  final String relationId;
  final String square;
  final AssessmentPiece piece;
  final AssessmentComponent component;
  final AssessmentVerdict verdict;
  final String reason;
  final bool contributes;
}

final class AssessmentConceptResult {
  AssessmentConceptResult({
    required Map<AssessmentComponent, AssessmentVerdict> components,
    required Map<AssessmentPiece, AssessmentVerdict> pieces,
    required Iterable<AssessmentPairVerdict> pairs,
    required Map<String, AssessmentVerdict> targetPredicates,
    required Iterable<String> reasons,
  }) : components = Map.unmodifiable(components),
       pieces = Map.unmodifiable(pieces),
       pairs = List.unmodifiable(pairs),
       targetPredicates = Map.unmodifiable(targetPredicates),
       reasons = List.unmodifiable(reasons);

  final Map<AssessmentComponent, AssessmentVerdict> components;
  final Map<AssessmentPiece, AssessmentVerdict> pieces;
  final List<AssessmentPairVerdict> pairs;
  final Map<String, AssessmentVerdict> targetPredicates;
  final List<String> reasons;

  /// A bounded result, never a lesson grade or a claim about learning.
  bool integral({required bool timeAndHistoryIntact}) =>
      timeAndHistoryIntact &&
      AssessmentComponent.values.every(
        (e) => components[e] == AssessmentVerdict.supported,
      );
}

/// Pure U1 predicates. No engine, replay, answer key or automatic response links.
final class AssessmentRelations {
  static final _canonicalSquare = RegExp(r'^[a-h][1-8]$');
  const AssessmentRelations();

  AssessmentConceptResult evaluate({
    required AssessmentDraft initial,
    required AssessmentDraft protection,
    required AssessmentFacts facts,
    required bool initialSubmitted,
    required bool protectionSubmitted,
    required bool executionComplete,
  }) {
    final pairs = <AssessmentPairVerdict>[];
    void inspect(
      AssessmentDraft response,
      AssessmentComponent component,
      AssessmentPhase phase,
    ) {
      for (final relation in response.relations) {
        if (!relation.useFor.contains(component)) continue;
        for (final square in relation.targetSquares) {
          pairs.add(_pair(relation, square, component, phase, facts));
        }
      }
    }

    inspect(initial, AssessmentComponent.target, AssessmentPhase.initial);
    inspect(initial, AssessmentComponent.pieces, AssessmentPhase.initial);
    inspect(
      protection,
      AssessmentComponent.protection,
      AssessmentPhase.protection,
    );

    final pieceResults = <AssessmentPiece, AssessmentVerdict>{};
    for (final piece in AssessmentPiece.values) {
      final linked = pairs.where(
        (p) => p.component == AssessmentComponent.pieces && p.piece == piece,
      );
      pieceResults[piece] = _coverage(
        linked,
        complete: linked.any((p) => p.contributes),
        submitted: initialSubmitted,
      );
    }

    final targetPairs = pairs.where(
      (p) => p.component == AssessmentComponent.target,
    );
    final covered = targetPairs
        .where((p) => p.contributes)
        .map((p) => p.square)
        .toSet();
    final target = initial.target;
    final empty = _empty(initialSubmitted);
    final predicates = <String, AssessmentVerdict>{
      'color': target == null ? empty : _color(target, facts),
      'access': target == null
          ? empty
          : _access(target, facts, initialSubmitted),
      'support': _coverage(
        targetPairs,
        complete: covered.containsAll(facts.blockedEscapes),
        submitted: initialSubmitted,
      ),
    };
    final reasons = <String>[];
    AssessmentVerdict protectionResult;
    if (!facts.visitedHistoryFactsComplete) {
      protectionResult = AssessmentVerdict.unsupported;
      reasons.add('visitedHistoryFactsIncomplete');
    } else if (!facts.protectionOpportunity) {
      protectionResult = AssessmentVerdict.unsupported;
      reasons.add('technicalNoProtectionOpportunity');
    } else {
      final linked = pairs.where(
        (p) => p.component == AssessmentComponent.protection,
      );
      protectionResult = _coverage(
        linked,
        complete: linked.any((p) => p.contributes),
        submitted: protectionSubmitted,
      );
    }
    return AssessmentConceptResult(
      components: {
        AssessmentComponent.target: _all(predicates.values, initialSubmitted),
        AssessmentComponent.pieces: _all(pieceResults.values, initialSubmitted),
        AssessmentComponent.protection: protectionResult,
        AssessmentComponent.execution: executionComplete
            ? AssessmentVerdict.supported
            : AssessmentVerdict.incomplete,
      },
      pieces: pieceResults,
      pairs: pairs,
      targetPredicates: predicates,
      reasons: reasons,
    );
  }

  AssessmentPairVerdict _pair(
    AssessmentRelation relation,
    String square,
    AssessmentComponent component,
    AssessmentPhase phase,
    AssessmentFacts facts,
  ) {
    AssessmentPairVerdict result(
      AssessmentVerdict verdict,
      String reason, [
      bool contributes = false,
    ]) => AssessmentPairVerdict(
      relationId: relation.id,
      square: square,
      piece: relation.piece,
      component: component,
      verdict: verdict,
      reason: reason,
      contributes: contributes,
    );
    if (component == AssessmentComponent.protection &&
        (!facts.visitedHistoryFactsComplete || !facts.protectionOpportunity)) {
      return result(AssessmentVerdict.unsupported, 'opportunityOutsideSupport');
    }
    final snapshot = facts.snapshots[relation.snapshotRef];
    if (relation.moment == AssessmentMoment.plannedOrUnrepresented ||
        snapshot == null ||
        !snapshot.visited ||
        (phase == AssessmentPhase.initial &&
            (relation.moment != AssessmentMoment.initial ||
                relation.snapshotRef != facts.initialSnapshotRef)) ||
        (phase == AssessmentPhase.protection &&
            relation.moment != AssessmentMoment.visited)) {
      return result(AssessmentVerdict.unsupported, 'momentOutsideSupport');
    }
    if (square.length != 2 || !_canonicalSquare.hasMatch(square)) {
      return result(AssessmentVerdict.unsupported, 'geometryOutsideSupport');
    }
    if (relation.kind == AssessmentRelationKind.protection &&
        square == snapshot.studentKingSquare) {
      return result(
        AssessmentVerdict.unsupported,
        'kingProtectionOutsideSupport',
      );
    }
    final evidence = switch (relation.kind) {
      AssessmentRelationKind.control => snapshot.controls,
      AssessmentRelationKind.protection => snapshot.protections,
      AssessmentRelationKind.check => snapshot.checks,
    };
    if (phase == AssessmentPhase.initial &&
        !facts.knownEscapeSquares.contains(square)) {
      return result(AssessmentVerdict.unsupported, 'geometryOutsideSupport');
    }
    final truePair = evidence[relation.piece]?.contains(square) ?? false;
    if (!truePair) {
      if (!snapshot.complete) {
        return result(AssessmentVerdict.unsupported, 'factsIncomplete');
      }
      return result(AssessmentVerdict.incorrect, 'verifiedContradiction');
    }
    final contributes = switch (component) {
      AssessmentComponent.protection =>
        relation.kind == AssessmentRelationKind.protection,
      AssessmentComponent.pieces =>
        relation.kind == AssessmentRelationKind.control &&
            facts.knownEscapeSquares.contains(square),
      AssessmentComponent.target =>
        relation.kind == AssessmentRelationKind.control &&
            facts.blockedEscapes.contains(square) &&
            (snapshot.controlsAfterRelocation[relation.piece]?.contains(
                  square,
                ) ??
                false),
      AssessmentComponent.execution => false,
    };
    return result(AssessmentVerdict.supported, 'verifiedPair', contributes);
  }

  AssessmentVerdict _color(AssessmentTarget target, AssessmentFacts facts) {
    if (target.colorPiece != AssessmentPiece.bishop) {
      return AssessmentVerdict.unsupported;
    }
    final compatible = facts.bishopCompatibleCorners[target.corner];
    if (compatible == null) return AssessmentVerdict.unsupported;
    return compatible && target.sameColor
        ? AssessmentVerdict.supported
        : AssessmentVerdict.incorrect;
  }

  AssessmentVerdict _access(
    AssessmentTarget target,
    AssessmentFacts facts,
    bool submitted,
  ) {
    if (target.accessSquares.any(
      (s) =>
          facts.knownEscapeSquares.contains(s) &&
          !facts.availableEscapes.contains(s),
    )) {
      return AssessmentVerdict.incorrect;
    }
    if (!facts.supportedCorners.contains(target.corner) ||
        target.accessSquares.any(
          (s) => !facts.knownEscapeSquares.contains(s),
        )) {
      return AssessmentVerdict.unsupported;
    }
    return target.accessSquares.containsAll(facts.availableEscapes) &&
            target.accessSquares.contains(target.corner)
        ? AssessmentVerdict.supported
        : _empty(submitted);
  }
}

AssessmentVerdict _coverage(
  Iterable<AssessmentPairVerdict> pairs, {
  required bool complete,
  required bool submitted,
}) {
  if (pairs.any((p) => p.verdict == AssessmentVerdict.incorrect)) {
    return AssessmentVerdict.incorrect;
  }
  if (complete) return AssessmentVerdict.supported;
  if (pairs.any((p) => p.verdict == AssessmentVerdict.unsupported)) {
    return AssessmentVerdict.unsupported;
  }
  return _empty(submitted);
}

AssessmentVerdict _all(Iterable<AssessmentVerdict> values, bool submitted) {
  if (values.contains(AssessmentVerdict.incorrect)) {
    return AssessmentVerdict.incorrect;
  }
  if (values.every((v) => v == AssessmentVerdict.supported)) {
    return AssessmentVerdict.supported;
  }
  if (values.contains(AssessmentVerdict.unsupported)) {
    return AssessmentVerdict.unsupported;
  }
  return _empty(submitted);
}

AssessmentVerdict _empty(bool submitted) =>
    submitted ? AssessmentVerdict.incomplete : AssessmentVerdict.unanswered;

Map<AssessmentPiece, Set<String>> _freeze(
  Map<AssessmentPiece, Set<String>> source,
) => Map.unmodifiable(
  source.map((k, v) => MapEntry(k, Set<String>.unmodifiable(v))),
);
