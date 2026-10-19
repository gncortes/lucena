/// U1 response data only. Verified facts and solutions never belong in snapshots.
enum AssessmentPhase { initial, execution, protection, closed }

enum AssessmentVerdict {
  unanswered,
  incomplete,
  supported,
  incorrect,
  unsupported,
}

enum AssessmentComponent { target, pieces, protection, execution }

enum AssessmentPiece { king, bishop, knight }

enum AssessmentRelationKind { control, protection, check }

enum AssessmentMoment { initial, visited, plannedOrUnrepresented }

enum AssessmentCloseReason {
  submitted,
  cancelled,
  timeLimit,
  clockIntegrity,
  identityIntegrity,
  historyIntegrity,
  assistance,
}

final class AssessmentRelation {
  AssessmentRelation({
    required this.id,
    required this.snapshotRef,
    required this.piece,
    required this.kind,
    required Iterable<String> targetSquares,
    required Iterable<AssessmentComponent> useFor,
    this.moment = AssessmentMoment.initial,
  }) : targetSquares = Set.unmodifiable(targetSquares),
       useFor = Set.unmodifiable(useFor) {
    if (id.isEmpty || targetSquares.isEmpty) {
      throw ArgumentError('A relation needs an id and targets');
    }
  }

  final String id;
  final String? snapshotRef;
  final AssessmentPiece piece;
  final AssessmentRelationKind kind;
  final Set<String> targetSquares;
  final Set<AssessmentComponent> useFor;
  final AssessmentMoment moment;

  Map<String, Object?> toJson() => {
    'id': id,
    'snapshotRef': snapshotRef,
    'piece': piece.name,
    'kind': kind.name,
    'targetSquares': targetSquares.toList(),
    'useFor': useFor.map((e) => e.name).toList(),
    'moment': moment.name,
  };

  factory AssessmentRelation.fromJson(Map<String, Object?> json) =>
      AssessmentRelation(
        id: json['id'] as String,
        snapshotRef: json['snapshotRef'] as String?,
        piece: AssessmentPiece.values.byName(json['piece'] as String),
        kind: AssessmentRelationKind.values.byName(json['kind'] as String),
        targetSquares: (json['targetSquares'] as List).cast<String>(),
        useFor: (json['useFor'] as List).cast<String>().map(
          AssessmentComponent.values.byName,
        ),
        moment: AssessmentMoment.values.byName(json['moment'] as String),
      );
}

final class AssessmentTarget {
  AssessmentTarget({
    required this.corner,
    required this.colorPiece,
    required this.sameColor,
    required Iterable<String> accessSquares,
  }) : accessSquares = Set.unmodifiable(accessSquares);

  final String corner;
  final AssessmentPiece colorPiece;
  final bool sameColor;
  final Set<String> accessSquares;

  Map<String, Object?> toJson() => {
    'corner': corner,
    'colorPiece': colorPiece.name,
    'sameColor': sameColor,
    'accessSquares': accessSquares.toList(),
  };

  factory AssessmentTarget.fromJson(Map<String, Object?> json) =>
      AssessmentTarget(
        corner: json['corner'] as String,
        colorPiece: AssessmentPiece.values.byName(json['colorPiece'] as String),
        sameColor: json['sameColor'] as bool,
        accessSquares: (json['accessSquares'] as List).cast<String>(),
      );
}

/// Partial collector selections, retained for restoration and diagnosis only.
/// These values do not create a confirmed target, relation or component link.
final class AssessmentEditingState {
  AssessmentEditingState({
    this.corner,
    this.colorPiece,
    this.sameColor,
    Iterable<String> accessSquares = const [],
    this.relationId,
    this.relationPiece,
    this.relationKind,
    this.relationMoment,
    this.relationSnapshotRef,
    Iterable<String> relationTargets = const [],
    Iterable<AssessmentComponent> relationUseFor = const [],
  }) : accessSquares = Set.unmodifiable(accessSquares),
       relationTargets = Set.unmodifiable(relationTargets),
       relationUseFor = Set.unmodifiable(relationUseFor);

  final String? corner;
  final AssessmentPiece? colorPiece;
  final bool? sameColor;
  final Set<String> accessSquares;
  final String? relationId;
  final AssessmentPiece? relationPiece;
  final AssessmentRelationKind? relationKind;
  final AssessmentMoment? relationMoment;
  final String? relationSnapshotRef;
  final Set<String> relationTargets;
  final Set<AssessmentComponent> relationUseFor;

  Map<String, Object?> toJson() => {
    'corner': corner,
    'colorPiece': colorPiece?.name,
    'sameColor': sameColor,
    'accessSquares': accessSquares.toList(),
    'relationId': relationId,
    'relationPiece': relationPiece?.name,
    'relationKind': relationKind?.name,
    'relationMoment': relationMoment?.name,
    'relationSnapshotRef': relationSnapshotRef,
    'relationTargets': relationTargets.toList(),
    'relationUseFor': relationUseFor.map((e) => e.name).toList(),
  };

  factory AssessmentEditingState.fromJson(
    Map<String, Object?> json,
  ) => AssessmentEditingState(
    corner: json['corner'] as String?,
    colorPiece: json['colorPiece'] == null
        ? null
        : AssessmentPiece.values.byName(json['colorPiece'] as String),
    sameColor: json['sameColor'] as bool?,
    accessSquares: (json['accessSquares'] as List?)?.cast<String>() ?? [],
    relationId: json['relationId'] as String?,
    relationPiece: json['relationPiece'] == null
        ? null
        : AssessmentPiece.values.byName(json['relationPiece'] as String),
    relationKind: json['relationKind'] == null
        ? null
        : AssessmentRelationKind.values.byName(json['relationKind'] as String),
    relationMoment: json['relationMoment'] == null
        ? null
        : AssessmentMoment.values.byName(json['relationMoment'] as String),
    relationSnapshotRef: json['relationSnapshotRef'] as String?,
    relationTargets: (json['relationTargets'] as List?)?.cast<String>() ?? [],
    relationUseFor:
        (json['relationUseFor'] as List?)?.cast<String>().map(
          AssessmentComponent.values.byName,
        ) ??
        [],
  );
}

final class AssessmentDraft {
  AssessmentDraft({
    this.target,
    Iterable<AssessmentRelation> relations = const [],
    AssessmentEditingState? editing,
  }) : relations = List.unmodifiable(relations),
       editing = editing ?? AssessmentEditingState() {
    if (this.relations.map((e) => e.id).toSet().length !=
        this.relations.length) {
      throw ArgumentError('Duplicate relation id');
    }
  }

  final AssessmentTarget? target;
  final List<AssessmentRelation> relations;
  final AssessmentEditingState editing;

  Map<String, Object?> toJson() => {
    'target': target?.toJson(),
    'relations': relations.map((e) => e.toJson()).toList(),
    'editing': editing.toJson(),
  };

  factory AssessmentDraft.fromJson(Map<String, Object?> json) =>
      AssessmentDraft(
        target: json['target'] == null
            ? null
            : AssessmentTarget.fromJson(_map(json['target'])),
        relations: (json['relations'] as List).map(
          (e) => AssessmentRelation.fromJson(_map(e)),
        ),
        editing: json['editing'] == null
            ? null
            : AssessmentEditingState.fromJson(_map(json['editing'])),
      );
}

final class AssessmentSubmission {
  const AssessmentSubmission({
    required this.phase,
    required this.atUtc,
    required this.response,
  });

  final AssessmentPhase phase;
  final DateTime atUtc;
  final AssessmentDraft response;

  Map<String, Object?> toJson() => {
    'phase': phase.name,
    'atUtc': atUtc.toUtc().toIso8601String(),
    'response': response.toJson(),
  };

  factory AssessmentSubmission.fromJson(Map<String, Object?> json) =>
      AssessmentSubmission(
        phase: AssessmentPhase.values.byName(json['phase'] as String),
        atUtc: DateTime.parse(json['atUtc'] as String).toUtc(),
        response: AssessmentDraft.fromJson(_map(json['response'])),
      );
}

/// A verified replay endpoint, supplied by the existing strict history adapter.
/// The adapter, not this model, proves legality, terminal status and winner.
final class AssessmentExecution {
  AssessmentExecution({
    required this.gameFen,
    required Iterable<String> played,
    required Map<String, String> visitedSnapshots,
    required this.historyIdentity,
    required this.historyVerified,
    required this.studentMate,
    required this.terminal,
    required this.studentTurn,
    this.pending = false,
  }) : played = List.unmodifiable(played),
       visitedSnapshots = Map.unmodifiable(visitedSnapshots);

  final String gameFen;
  final List<String> played;
  final Map<String, String> visitedSnapshots;
  final String historyIdentity;
  final bool historyVerified;
  final bool studentMate;
  final bool terminal;
  final bool studentTurn;
  final bool pending;

  Map<String, Object?> toJson() => {
    'gameFen': gameFen,
    'played': played,
    'visitedSnapshots': visitedSnapshots,
    'historyIdentity': historyIdentity,
    'historyVerified': historyVerified,
    'studentMate': studentMate,
    'terminal': terminal,
    'studentTurn': studentTurn,
    'pending': pending,
  };

  factory AssessmentExecution.fromJson(Map<String, Object?> json) =>
      AssessmentExecution(
        gameFen: json['gameFen'] as String,
        played: (json['played'] as List).cast<String>(),
        visitedSnapshots: _map(json['visitedSnapshots']).cast<String, String>(),
        historyIdentity: json['historyIdentity'] as String,
        historyVerified: json['historyVerified'] as bool,
        studentMate: json['studentMate'] as bool,
        terminal: json['terminal'] as bool,
        studentTurn: json['studentTurn'] as bool,
        pending: json['pending'] as bool,
      );
}

final class AssessmentHelp {
  AssessmentHelp({
    required this.atUtc,
    required this.source,
    required this.received,
    required Iterable<AssessmentComponent> components,
  }) : components = Set.unmodifiable(components);

  final DateTime atUtc;
  final String source;
  final bool received;
  final Set<AssessmentComponent> components;

  Map<String, Object?> toJson() => {
    'atUtc': atUtc.toUtc().toIso8601String(),
    'source': source,
    'received': received,
    'components': components.map((e) => e.name).toList(),
  };

  factory AssessmentHelp.fromJson(Map<String, Object?> json) => AssessmentHelp(
    atUtc: DateTime.parse(json['atUtc'] as String).toUtc(),
    source: json['source'] as String,
    received: json['received'] as bool,
    components: (json['components'] as List).cast<String>().map(
      AssessmentComponent.values.byName,
    ),
  );
}

/// One durable U1 attempt; no correctness is stored or exposed during collection.
final class AssessmentAttempt {
  AssessmentAttempt({
    required this.attemptId,
    required this.lessonId,
    required this.exerciseId,
    required Map<String, String> contentIdentity,
    required this.startedAtUtc,
    required this.lastObservedUtc,
    required this.execution,
    required this.draft,
    this.parentAttemptId,
    this.phase = AssessmentPhase.initial,
    this.revision = 0,
    this.callbackEpoch = 0,
    this.assisted = false,
    this.exposed = false,
    this.viewSnapshotRef,
    Iterable<AssessmentSubmission> submissions = const [],
    Iterable<AssessmentHelp> help = const [],
    this.executionFinishedAtUtc,
    this.closedAtUtc,
    this.closeReason,
  }) : contentIdentity = Map.unmodifiable(contentIdentity),
       submissions = List.unmodifiable(submissions),
       help = List.unmodifiable(help);

  final String attemptId;
  final String? parentAttemptId;
  final String lessonId;
  final String exerciseId;
  final Map<String, String> contentIdentity;
  final DateTime startedAtUtc;
  DateTime get deadlineUtc => startedAtUtc.add(const Duration(seconds: 600));
  final DateTime lastObservedUtc;
  final AssessmentPhase phase;
  final int revision;
  final int callbackEpoch;
  final bool assisted;
  final bool exposed;
  final AssessmentDraft draft;
  final List<AssessmentSubmission> submissions;
  final List<AssessmentHelp> help;
  final AssessmentExecution execution;
  final String? viewSnapshotRef;
  final DateTime? executionFinishedAtUtc;
  final DateTime? closedAtUtc;
  final AssessmentCloseReason? closeReason;
  bool get feedbackVisible => phase == AssessmentPhase.closed;

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'attemptId': attemptId,
    'parentAttemptId': parentAttemptId,
    'lessonId': lessonId,
    'exerciseId': exerciseId,
    'contentIdentity': contentIdentity,
    'startedAtUtc': startedAtUtc.toUtc().toIso8601String(),
    'lastObservedUtc': lastObservedUtc.toUtc().toIso8601String(),
    'phase': phase.name,
    'revision': revision,
    'callbackEpoch': callbackEpoch,
    'assisted': assisted,
    'exposed': exposed,
    'draft': draft.toJson(),
    'submissions': submissions.map((e) => e.toJson()).toList(),
    'help': help.map((e) => e.toJson()).toList(),
    'execution': execution.toJson(),
    'viewSnapshotRef': viewSnapshotRef,
    'executionFinishedAtUtc': executionFinishedAtUtc?.toUtc().toIso8601String(),
    'closedAtUtc': closedAtUtc?.toUtc().toIso8601String(),
    'closeReason': closeReason?.name,
  };

  factory AssessmentAttempt.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported assessment snapshot');
    }
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.parse(json[key] as String).toUtc();
    return AssessmentAttempt(
      attemptId: json['attemptId'] as String,
      parentAttemptId: json['parentAttemptId'] as String?,
      lessonId: json['lessonId'] as String,
      exerciseId: json['exerciseId'] as String,
      contentIdentity: _map(json['contentIdentity']).cast<String, String>(),
      startedAtUtc: date('startedAtUtc')!,
      lastObservedUtc: date('lastObservedUtc')!,
      phase: AssessmentPhase.values.byName(json['phase'] as String),
      revision: json['revision'] as int,
      callbackEpoch: json['callbackEpoch'] as int,
      assisted: json['assisted'] as bool,
      exposed: json['exposed'] as bool,
      draft: AssessmentDraft.fromJson(_map(json['draft'])),
      submissions: (json['submissions'] as List).map(
        (e) => AssessmentSubmission.fromJson(_map(e)),
      ),
      help: (json['help'] as List).map((e) => AssessmentHelp.fromJson(_map(e))),
      execution: AssessmentExecution.fromJson(_map(json['execution'])),
      viewSnapshotRef: json['viewSnapshotRef'] as String?,
      executionFinishedAtUtc: date('executionFinishedAtUtc'),
      closedAtUtc: date('closedAtUtc'),
      closeReason: json['closeReason'] == null
          ? null
          : AssessmentCloseReason.values.byName(json['closeReason'] as String),
    );
  }
}

Map<String, Object?> _map(Object? value) =>
    (value as Map).cast<String, Object?>();
