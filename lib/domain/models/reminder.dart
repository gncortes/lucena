import 'week_summary.dart';

/// Os lembretes locais (E1.23), cada um no seu canal do Android.
enum ReminderKind {
  /// "Sua sequência de {n} dias acaba hoje" (canal Lembretes).
  streak,

  /// "Continue a lição" (canal Lembretes).
  lesson,

  /// O resumo de domingo (canal Resumo da semana).
  week,
}

/// A aula de final começada e não concluída, para "Continue a lição".
class PausedLesson {
  const PausedLesson({
    required this.lessonId,
    required this.title,
    required this.chapter,
    required this.total,
    this.partId,
    this.stage = 0,
  });

  final String lessonId;
  final String title;

  /// O capítulo em que parou (a partir de 1) e quantos a aula tem.
  final int chapter;
  final int total;

  /// A parte e o passo salvos, para o toque abrir onde parou.
  final String? partId;
  final int stage;

  @override
  bool operator ==(Object other) =>
      other is PausedLesson &&
      other.lessonId == lessonId &&
      other.title == title &&
      other.chapter == chapter &&
      other.total == total &&
      other.partId == partId &&
      other.stage == stage;

  @override
  int get hashCode =>
      Object.hash(lessonId, title, chapter, total, partId, stage);
}

/// Um lembrete a agendar no aparelho: o tipo, a hora e o que ele diz.
class PlannedReminder {
  const PlannedReminder({
    required this.kind,
    required this.at,
    this.streakDays = 0,
    this.lesson,
    this.week,
  });

  final ReminderKind kind;

  /// Quando sai, na hora local.
  final DateTime at;

  /// A sequência que acaba no dia ([ReminderKind.streak]).
  final int streakDays;

  /// A aula em que parou ([ReminderKind.lesson]).
  final PausedLesson? lesson;

  /// A semana ([ReminderKind.week]).
  final WeekSummary? week;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.kind == kind &&
      other.at == at &&
      other.streakDays == streakDays &&
      other.lesson == lesson &&
      identical(other.week, week);

  @override
  int get hashCode => Object.hash(kind, at, streakDays, lesson);

  @override
  String toString() => 'PlannedReminder($kind, $at, $streakDays)';
}
