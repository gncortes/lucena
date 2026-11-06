import 'study_plan.dart';
import 'tournament_record.dart';
import 'training_diagnostic.dart';
import 'training_objective.dart';

/// O que o "Desfazer" do aviso devolve.
enum UndoKind {
  objectiveRemoved,
  objectiveChanged,
  tournamentEdited,
  tournamentDeleted,
}

/// Cópia do estado de antes da última troca de objetivo ou mexida num registro.
/// Vale até a próxima ação de objetivo ou registro e sobrevive a fechar o app.
final class GoalUndoSlot {
  GoalUndoSlot({
    required this.kind,
    this.objective,
    Iterable<TrainingObjective> objectiveHistory = const [],
    this.studyPlan,
    this.previousStudyPlan,
    this.diagnostic,
    this.tournamentPushFor,
    Iterable<TournamentRecord> tournaments = const [],
  }) : objectiveHistory = List.unmodifiable(objectiveHistory),
       tournaments = List.unmodifiable(tournaments);

  final UndoKind kind;
  final TrainingObjective? objective;
  final List<TrainingObjective> objectiveHistory;
  final StudyPlan? studyPlan, previousStudyPlan;
  final TrainingDiagnostic? diagnostic;
  final String? tournamentPushFor;
  final List<TournamentRecord> tournaments;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    if (objective != null) 'objective': objective!.toJson(),
    'objectiveHistory': objectiveHistory.map((o) => o.toJson()).toList(),
    if (studyPlan != null) 'studyPlan': studyPlan!.toJson(),
    if (previousStudyPlan != null)
      'previousStudyPlan': previousStudyPlan!.toJson(),
    if (diagnostic != null) 'diagnostic': diagnostic!.toJson(),
    if (tournamentPushFor != null) 'tournamentPushFor': tournamentPushFor,
    'tournaments': tournaments.map((t) => t.toJson()).toList(),
  };

  /// Cópia ilegível vira nula: só some o "Desfazer".
  static GoalUndoSlot? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      return GoalUndoSlot(
        kind: UndoKind.values.byName(raw['kind'] as String),
        objective: TrainingObjective.tryFromJson(raw['objective']),
        objectiveHistory: [
          for (final o in raw['objectiveHistory'] as List? ?? const [])
            ?TrainingObjective.tryFromJson(o),
        ],
        studyPlan: StudyPlan.tryFromJson(raw['studyPlan']),
        previousStudyPlan: StudyPlan.tryFromJson(raw['previousStudyPlan']),
        diagnostic: TrainingDiagnostic.tryFromJson(raw['diagnostic']),
        tournamentPushFor: raw['tournamentPushFor'] as String?,
        tournaments: [
          for (final t in raw['tournaments'] as List? ?? const [])
            ?TournamentRecord.tryFromJson(t),
        ],
      );
    } on Object {
      return null;
    }
  }
}

/// Escolha de "Seu objetivo" ainda não salva (sobrevive a fechar o app).
final class ObjectiveDraft {
  const ObjectiveDraft({this.kind, this.date, this.name = ''});

  final ObjectiveKind? kind;
  final String? date;
  final String name;

  Map<String, Object?> toJson() => {
    'kind': kind?.name,
    'date': date,
    'name': name,
  };

  static ObjectiveDraft? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final kind = raw['kind'] as String?;
      return ObjectiveDraft(
        kind: kind == null ? null : ObjectiveKind.values.byName(kind),
        date: raw['date'] as String?,
        name: raw['name'] as String? ?? '',
      );
    } on Object {
      return null;
    }
  }
}

/// Edição de um registro em andamento; separada do rascunho do registro novo.
final class TournamentEdit {
  const TournamentEdit({required this.id, required this.draft});

  final String id;
  final TournamentDraft draft;

  Map<String, Object?> toJson() => {'id': id, 'draft': draft.toJson()};

  static TournamentEdit? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final draft = TournamentDraft.tryFromJson(raw['draft']);
    if (id is! String || draft == null) return null;
    return TournamentEdit(id: id, draft: draft);
  }
}
