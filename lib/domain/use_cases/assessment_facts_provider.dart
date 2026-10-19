import 'package:dartchess/dartchess.dart';

import '../models/assessment_attempt.dart';
import 'assessment_execution_adapter.dart';
import 'assessment_relations.dart';
import 'exercise_judge.dart';

/// Trusted integration input, never supplied by the learner's response.
/// Hashes identify the selected sources; they do not authenticate their origin.
final class AssessmentFactsDescriptor {
  AssessmentFactsDescriptor({
    required this.descriptorId,
    required this.factualVersion,
    required this.assessmentVersion,
    required this.lessonId,
    required this.exerciseId,
    required this.initialFen,
    required this.student,
    required this.orientation,
    required this.supportedCorner,
    required Map<String, String> contentIdentity,
    required Map<String, String> sourceHashes,
  }) : contentIdentity = Map.unmodifiable(contentIdentity),
       sourceHashes = Map.unmodifiable(sourceHashes);

  final String descriptorId;
  final String factualVersion;
  final String assessmentVersion;
  final String lessonId;
  final String exerciseId;
  final String initialFen;
  final Side student;
  final Side orientation;
  final String supportedCorner;
  final Map<String, String> contentIdentity;
  final Map<String, String> sourceHashes;
}

final class AssessmentFactsProviderException implements Exception {
  const AssessmentFactsProviderException(this.reason);
  final String reason;
  @override
  String toString() => 'AssessmentFactsProviderException: $reason';
}

/// Pure bounded geometry over every actually visited frame, without engine,
/// route whitelist, response completion or inference of strategic success.
final class AssessmentRuntimeFactsProvider {
  const AssessmentRuntimeFactsProvider(this.descriptor);
  final AssessmentFactsDescriptor descriptor;
  static const version = 'u1-runtime-geometry-v1';

  AssessmentFacts call(AssessmentAttempt attempt) {
    try {
      return _derive(attempt);
    } on AssessmentFactsProviderException {
      rethrow;
    } on AssessmentExecutionAdapterException {
      throw const AssessmentFactsProviderException('invalidReplay');
    } on Object {
      throw const AssessmentFactsProviderException('geometryDerivationFailed');
    }
  }

  AssessmentFacts _derive(AssessmentAttempt attempt) {
    final d = descriptor;
    const requiredSources = [
      'item',
      'teaching',
      'proofManifest',
      'contract',
      'runtimeContract',
      'spec',
    ];
    if (d.descriptorId.isEmpty ||
        d.factualVersion != version ||
        d.assessmentVersion != 'u1-relations-v3-runtime' ||
        d.lessonId != 'mates.bishopKnight.deletang' ||
        d.exerciseId != 'finalNetAssessment01' ||
        d.student != Side.white ||
        d.orientation != Side.white ||
        d.contentIdentity.isEmpty ||
        d.contentIdentity['assessmentVersion'] != d.assessmentVersion ||
        d.contentIdentity['factualVersion'] != d.factualVersion ||
        !requiredSources.every(d.sourceHashes.containsKey) ||
        d.sourceHashes.entries.any(
          (e) =>
              !RegExp(r'^[0-9a-f]{64}$').hasMatch(e.value) ||
              d.contentIdentity[e.key] != e.value,
        )) {
      throw const AssessmentFactsProviderException('invalidDescriptorIdentity');
    }
    if (attempt.attemptId.isEmpty ||
        attempt.revision < 0 ||
        attempt.lessonId != d.lessonId ||
        attempt.exerciseId != d.exerciseId ||
        !_same(attempt.contentIdentity, d.contentIdentity)) {
      throw const AssessmentFactsProviderException('attemptIdentityMismatch');
    }
    final root = ExerciseJudge.exactPosition(d.initialFen);
    if (root == null || root.turn != Side.white) {
      throw const AssessmentFactsProviderException('invalidRoot');
    }
    final rootPieces = _pieces(root, root: true);
    final bishop = rootPieces[AssessmentPiece.bishop]!;
    final corners = <String, bool>{
      for (final corner in const ['a1', 'a8', 'h1', 'h8'])
        corner: _color(corner) == _color(bishop.name),
    };
    if (corners[d.supportedCorner] != true) {
      throw const AssessmentFactsProviderException('invalidSupportedCorner');
    }
    final replay = const AssessmentExecutionAdapter().replay(
      initialFen: d.initialFen,
      student: d.student,
      played: attempt.execution.played,
      expectedFen: attempt.execution.gameFen,
      pending: attempt.execution.pending,
    );
    if (!_same(replay.toJson(), attempt.execution.toJson()) ||
        (attempt.viewSnapshotRef != null &&
            !replay.visitedSnapshots.containsKey(attempt.viewSnapshotRef))) {
      throw const AssessmentFactsProviderException('checkpointMismatch');
    }
    final enemy = d.student.opposite;
    final king = root.board.kingOf(enemy)!;
    final neighbors = kingAttacks(king).squares.toList();
    final known = neighbors.map((s) => s.name).toSet();
    final probe = root.copyWith(turn: enemy);
    final available = <String>{
      for (final target in neighbors)
        if (probe.isLegal(NormalMove(from: king, to: target))) target.name,
    };
    final blocked = known.difference(available);
    if (known.isEmpty || blocked.isEmpty) {
      throw const AssessmentFactsProviderException('emptyRootSupportDomain');
    }
    final relocatedControls = _emptyMaps();
    for (final target in neighbors) {
      final relocated = root.board
          .removePieceAt(king)
          .removePieceAt(target)
          .setPieceAt(target, Piece(color: enemy, role: Role.king));
      final attackers = relocated.attacksTo(target, d.student);
      for (final id in AssessmentPiece.values) {
        final origin = rootPieces[id];
        if (origin != null &&
            relocated.roleAt(origin) == _role(id) &&
            relocated.bySide(d.student).has(origin) &&
            attackers.has(origin)) {
          relocatedControls[id]!.add(target.name);
        }
      }
    }
    final frames = <String, AssessmentSnapshotFacts>{};
    final provenanceFrames = <String, ({int ply, String fen})>{};
    var opportunity = false;
    for (var ply = 0; ply <= replay.played.length; ply++) {
      final ref = 'ply:$ply';
      final fen = replay.visitedSnapshots[ref]!;
      final position = ExerciseJudge.exactPosition(fen)!;
      final pieces = _pieces(position, root: false);
      final controls = _emptyMaps();
      final protections = _emptyMaps();
      final checks = _emptyMaps();
      for (final square in _allSquares) {
        final attackers = position.board.attacksTo(square, d.student);
        for (final id in AssessmentPiece.values) {
          final origin = pieces[id];
          if (origin != null && attackers.has(origin)) {
            controls[id]!.add(square.name);
          }
        }
      }
      final enemyKing = position.board.kingOf(enemy)!;
      for (final id in AssessmentPiece.values) {
        for (final targetId in const [
          AssessmentPiece.bishop,
          AssessmentPiece.knight,
        ]) {
          final target = pieces[targetId];
          if (id != targetId &&
              target != null &&
              controls[id]!.contains(target.name)) {
            protections[id]!.add(target.name);
          }
        }
        if (controls[id]!.contains(enemyKing.name)) {
          checks[id]!.add(enemyKing.name);
        }
      }
      opportunity = opportunity || protections.values.any((s) => s.isNotEmpty);
      frames[ref] = AssessmentSnapshotFacts(
        ref: ref,
        visited: true,
        complete: true,
        studentKingSquare: pieces[AssessmentPiece.king]!.name,
        controls: controls,
        protections: protections,
        checks: checks,
        controlsAfterRelocation: ply == 0 ? relocatedControls : {},
      );
      provenanceFrames[ref] = (ply: ply, fen: fen);
    }
    return AssessmentFacts(
      initialSnapshotRef: 'ply:0',
      snapshots: frames,
      bishopCompatibleCorners: corners,
      supportedCorners: {d.supportedCorner},
      knownEscapeSquares: known,
      availableEscapes: available,
      blockedEscapes: blocked,
      visitedHistoryFactsComplete: true,
      protectionOpportunity: opportunity,
      provenance: AssessmentFactsProvenance(
        providerVersion: version,
        method: 'runtimeGeometry',
        rulesVersion: 'GameRules/dartchess0.14.0',
        descriptorVersion: d.assessmentVersion,
        descriptorId: d.descriptorId,
        contentIdentity: d.contentIdentity,
        sourceHashes: d.sourceHashes,
        attemptId: attempt.attemptId,
        revision: attempt.revision,
        historyIdentity: replay.historyIdentity,
        initialFen: d.initialFen,
        gameFen: replay.gameFen,
        student: d.student.name,
        snapshots: provenanceFrames,
        domains: const {
          'controls': 'king|bishop|knight x a1..h8; currentOccupancy',
          'protections':
              'king|bishop|knight x a1..h8; alliedBishopKnightTargetsOnly',
          'checks': 'king|bishop|knight x a1..h8; currentEnemyKingOnly',
          'controlsAfterRelocation': 'rootEscapesOnly; emptyOutsideRoot',
        },
      ),
    );
  }

  Map<AssessmentPiece, Square?> _pieces(
    Position position, {
    required bool root,
  }) {
    final studentSquares = position.board
        .bySide(descriptor.student)
        .squares
        .toList();
    final enemySquares = position.board
        .bySide(descriptor.student.opposite)
        .squares
        .toList();
    final result = <AssessmentPiece, Square?>{};
    for (final id in AssessmentPiece.values) {
      final matching = studentSquares
          .where((s) => position.board.roleAt(s) == _role(id))
          .toList();
      if (matching.length > 1 ||
          ((root || id == AssessmentPiece.king) && matching.length != 1)) {
        throw const AssessmentFactsProviderException('invalidMaterial');
      }
      result[id] = matching.isEmpty ? null : matching.single;
    }
    if (result.values.where((s) => s != null).length != studentSquares.length ||
        enemySquares.length != 1 ||
        position.board.roleAt(enemySquares.single) != Role.king) {
      throw const AssessmentFactsProviderException('invalidMaterial');
    }
    return result;
  }
}

Role _role(AssessmentPiece piece) => switch (piece) {
  AssessmentPiece.king => Role.king,
  AssessmentPiece.bishop => Role.bishop,
  AssessmentPiece.knight => Role.knight,
};

int _color(String square) =>
    ('abcdefgh'.indexOf(square[0]) + int.parse(square[1])) % 2;

final _allSquares = List<Square>.unmodifiable([
  for (final file in 'abcdefgh'.split(''))
    for (var rank = 1; rank <= 8; rank++) Square.parse('$file$rank')!,
]);

Map<AssessmentPiece, Set<String>> _emptyMaps() => {
  for (final id in AssessmentPiece.values) id: <String>{},
};

bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.entries.every(
          (e) => b.containsKey(e.key) && _same(e.value, b[e.key]),
        );
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        a.asMap().entries.every((e) => _same(e.value, b[e.key]));
  }
  return a == b;
}
