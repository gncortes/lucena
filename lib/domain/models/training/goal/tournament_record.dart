enum TournamentPace { classical, rapid, blitz }

enum TournamentEntity { fide, cbx, online, other }

/// Torneio jogado (H-TRE-15). Pontos e rodadas são décimos de ponto inteiros:
/// 4,5 pontos = 45 (evita ponto flutuante).
final class TournamentRecord {
  const TournamentRecord({
    required this.id,
    required this.name,
    required this.date,
    required this.tenthsPoints,
    required this.rounds,
    this.ratingBefore,
    this.ratingAfter,
    this.pace,
    this.entity,
    this.feeling,
    this.notes = '',
  });

  final String id, name, date, notes;
  final int tenthsPoints, rounds;
  final int? ratingBefore, ratingAfter;
  final TournamentPace? pace;
  final TournamentEntity? entity;

  /// 1 (muito ruim) a 5 (excelente).
  final int? feeling;

  int? get ratingDelta => ratingBefore == null || ratingAfter == null
      ? null
      : ratingAfter! - ratingBefore!;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'date': date,
    'points': tenthsPoints,
    'rounds': rounds,
    'ratingBefore': ratingBefore,
    'ratingAfter': ratingAfter,
    'pace': pace?.name,
    'entity': entity?.name,
    'feeling': feeling,
    'notes': notes,
  };

  static TournamentRecord? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final pace = raw['pace'] as String?;
      final entity = raw['entity'] as String?;
      return TournamentRecord(
        id: raw['id'] as String,
        name: raw['name'] as String,
        date: raw['date'] as String,
        tenthsPoints: raw['points'] as int,
        rounds: raw['rounds'] as int,
        ratingBefore: raw['ratingBefore'] as int?,
        ratingAfter: raw['ratingAfter'] as int?,
        pace: pace == null ? null : TournamentPace.values.byName(pace),
        entity: entity == null ? null : TournamentEntity.values.byName(entity),
        feeling: raw['feeling'] as int?,
        notes: raw['notes'] as String? ?? '',
      );
    } on Object {
      return null;
    }
  }
}

/// Rascunho do registro: tudo texto, como o aluno digitou (G20).
final class TournamentDraft {
  const TournamentDraft({
    this.name = '',
    this.date = '',
    this.points = '',
    this.rounds = '',
    this.ratingBefore = '',
    this.ratingAfter = '',
    this.pace,
    this.entity,
    this.feeling,
    this.notes = '',
  });

  final String name, date, points, rounds, ratingBefore, ratingAfter, notes;
  final TournamentPace? pace;
  final TournamentEntity? entity;
  final int? feeling;

  TournamentDraft copyWith({
    String? name,
    String? date,
    String? points,
    String? rounds,
    String? ratingBefore,
    String? ratingAfter,
    String? notes,
    TournamentPace? pace,
    TournamentEntity? entity,
    int? feeling,
  }) => TournamentDraft(
    name: name ?? this.name,
    date: date ?? this.date,
    points: points ?? this.points,
    rounds: rounds ?? this.rounds,
    ratingBefore: ratingBefore ?? this.ratingBefore,
    ratingAfter: ratingAfter ?? this.ratingAfter,
    notes: notes ?? this.notes,
    pace: pace ?? this.pace,
    entity: entity ?? this.entity,
    feeling: feeling ?? this.feeling,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'date': date,
    'points': points,
    'rounds': rounds,
    'ratingBefore': ratingBefore,
    'ratingAfter': ratingAfter,
    'pace': pace?.name,
    'entity': entity?.name,
    'feeling': feeling,
    'notes': notes,
  };

  static TournamentDraft? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final pace = raw['pace'] as String?;
      final entity = raw['entity'] as String?;
      return TournamentDraft(
        name: raw['name'] as String? ?? '',
        date: raw['date'] as String? ?? '',
        points: raw['points'] as String? ?? '',
        rounds: raw['rounds'] as String? ?? '',
        ratingBefore: raw['ratingBefore'] as String? ?? '',
        ratingAfter: raw['ratingAfter'] as String? ?? '',
        pace: pace == null ? null : TournamentPace.values.byName(pace),
        entity: entity == null ? null : TournamentEntity.values.byName(entity),
        feeling: raw['feeling'] as int?,
        notes: raw['notes'] as String? ?? '',
      );
    } on Object {
      return null;
    }
  }
}
