import 'training_course.dart';
import 'training_plan.dart';

final class TrainingGoal {
  TrainingGoal({
    required this.kind,
    required this.ref,
    this.itemId,
    this.stars = 0,
    this.done = false,
    this.mock = false,
    Map<String, String> items = const {},
  }) : items = Map.unmodifiable(items);
  final GoalKind kind;
  final String ref;
  final String? itemId;
  final int stars;
  final bool done, mock;

  /// Opening lesson -> today's segment, frozen along with the other goals.
  final Map<String, String> items;
  String get key => '${kind.name}:$ref:${itemId ?? ''}';
  TrainingGoal complete() => TrainingGoal(
    kind: kind,
    ref: ref,
    itemId: itemId,
    stars: stars,
    done: true,
    mock: mock,
    items: items,
  );
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'ref': ref,
    'itemId': itemId,
    'stars': stars,
    'done': done,
    'mock': mock,
    'items': items,
  };
  factory TrainingGoal.fromJson(Map<String, dynamic> j) => TrainingGoal(
    kind: GoalKind.values.byName(j['kind'] as String),
    ref: j['ref'] as String,
    itemId: j['itemId'] as String?,
    stars: j['stars'] as int,
    done: j['done'] as bool,
    mock: j['mock'] as bool,
    items: (j['items'] as Map).cast<String, String>(),
  );
}

final class DayGoals {
  DayGoals({
    required this.date,
    required this.studyDay,
    Iterable<TrainingGoal> goals = const [],
    this.doubled = false,
    this.plan = const TrainingPlan(),
  }) : goals = List.unmodifiable(goals);
  final String date;
  final TrainingPlan plan;
  final bool studyDay, doubled;
  final List<TrainingGoal> goals;
  int get remaining => goals.where((g) => !g.done).length;
  bool get allDone => studyDay && remaining == 0;
  TrainingGoal? get next => goals.where((g) => !g.done).firstOrNull;
  DayGoals copyWith({Iterable<TrainingGoal>? goals, bool? doubled}) => DayGoals(
    date: date,
    plan: plan,
    studyDay: studyDay,
    goals: goals ?? this.goals,
    doubled: doubled ?? this.doubled,
  );
  Map<String, Object?> toJson() => {
    'date': date,
    'plan': plan.toJson(),
    'studyDay': studyDay,
    'doubled': doubled,
    'goals': goals.map((g) => g.toJson()).toList(),
  };
  factory DayGoals.fromJson(Map<String, dynamic> j) => DayGoals(
    date: j['date'] as String,
    plan: TrainingPlan.fromJson(Map<String, dynamic>.from(j['plan'] as Map)),
    studyDay: j['studyDay'] as bool,
    doubled: j['doubled'] as bool,
    goals: (j['goals'] as List).map(
      (g) => TrainingGoal.fromJson(Map<String, dynamic>.from(g as Map)),
    ),
  );
}
