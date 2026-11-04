/// O que o aluno quer alcançar com o treino: jogar um torneio numa data ou só melhorar.
enum ObjectiveKind { tournament, improve }

/// Objetivo do treino (H-TRE-02). As datas são civis, no formato `yyyy-MM-dd`.
final class TrainingObjective {
  const TrainingObjective({
    required this.kind,
    required this.setOn,
    this.tournamentDate,
    this.tournamentName = '',
  }) : assert(
         kind == ObjectiveKind.improve || tournamentDate != null,
         'Torneio exige data',
       );

  final ObjectiveKind kind;

  /// Dia em que o objetivo foi definido; o plano nasce nele.
  final String setOn;
  final String? tournamentDate;
  final String tournamentName;

  bool get hasTournament =>
      kind == ObjectiveKind.tournament && tournamentDate != null;

  TrainingObjective copyWith({
    ObjectiveKind? kind,
    String? setOn,
    String? tournamentDate,
    String? tournamentName,
  }) {
    final next = kind ?? this.kind;
    return TrainingObjective(
      kind: next,
      setOn: setOn ?? this.setOn,
      tournamentDate: next == ObjectiveKind.improve
          ? null
          : tournamentDate ?? this.tournamentDate,
      tournamentName: tournamentName ?? this.tournamentName,
    );
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'setOn': setOn,
    'tournamentDate': tournamentDate,
    'tournamentName': tournamentName,
  };

  /// Dado ilegível vira nulo: o aluno só precisa definir o objetivo de novo.
  static TrainingObjective? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final kind = ObjectiveKind.values.byName(raw['kind'] as String);
      final date = raw['tournamentDate'] as String?;
      if (kind == ObjectiveKind.tournament && date == null) return null;
      return TrainingObjective(
        kind: kind,
        setOn: raw['setOn'] as String,
        tournamentDate: date,
        tournamentName: raw['tournamentName'] as String? ?? '',
      );
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TrainingObjective &&
      other.kind == kind &&
      other.setOn == setOn &&
      other.tournamentDate == tournamentDate &&
      other.tournamentName == tournamentName;

  @override
  int get hashCode => Object.hash(kind, setOn, tournamentDate, tournamentName);
}
