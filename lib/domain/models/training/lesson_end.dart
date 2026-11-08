// Dados das telas de fim de lição (T85-D1, H-LIC-50 a 53). Texto de capítulo
// e de data já chega pronto de quem monta o plano; aqui só há números e rótulos.

/// A meta do dia no fim da última lição do dia (canvas `PropV2LicaoFimMetaDia`).
final class DayGoalSummary {
  const DayGoalSummary({
    required this.week,
    required this.weekCount,
    required this.daysLeft,
    required this.currentChapter,
    required this.lessonsDone,
    required this.lessonsTotal,
    required this.testPending,
    required this.chapterProgress,
    required this.chaptersDone,
    this.nextChapter,
    this.nextChapterWhen,
  }) : assert(week >= 1),
       assert(weekCount >= week);

  final int week, weekCount, daysLeft, lessonsDone, lessonsTotal, chaptersDone;

  /// "Capítulo 8 · Recursos defensivos".
  final String currentChapter;
  final bool testPending;

  /// Uma fração (0 a 1) por semana do plano.
  final List<double> chapterProgress;

  /// O próximo capítulo do plano e quando ele começa; nulos na última semana.
  final String? nextChapter, nextChapterWhen;
}

/// Uma linha da revisão da semana: refaz o teste do capítulo.
final class WeekReviewItem {
  const WeekReviewItem({
    required this.chapter,
    required this.correct,
    required this.total,
    required this.path,
  });

  /// "Capítulo 8 · Recursos defensivos".
  final String chapter;
  final int correct, total;

  /// A rota do teste do capítulo.
  final String path;
}

/// Torneio do plano do aluno; sem ele, a semana 6 é só revisão.
final class TournamentInfo {
  const TournamentInfo({
    required this.name,
    required this.dateLabel,
    required this.daysLeft,
  });
  final String name, dateLabel;
  final int daysLeft;
}

/// Posição de aquecimento do dia do torneio.
final class TournamentWarmup {
  const TournamentWarmup({
    required this.fen,
    required this.chapter,
    required this.side,
    required this.path,
  });
  final String fen, chapter, side, path;
}

/// Revisão da semana (H-LIC-52). Com [tournament] no dia dele ([warmups] não
/// vazio), vira "Dia do torneio".
final class WeekReview {
  const WeekReview({
    required this.week,
    required this.weekCount,
    required this.periodLabel,
    required this.items,
    this.tournament,
    this.warmups = const [],
  });
  final int week, weekCount;
  final String periodLabel;
  final List<WeekReviewItem> items;
  final TournamentInfo? tournament;
  final List<TournamentWarmup> warmups;

  bool get isTournamentDay =>
      tournament != null && tournament!.daysLeft == 0 && warmups.isNotEmpty;
}

/// Curso concluído (H-LIC-53).
final class CourseCompletion {
  const CourseCompletion({
    required this.courseName,
    required this.chapters,
    required this.lessons,
    required this.studentName,
    required this.dateLabel,
    required this.teacherName,
  });
  final String courseName, studentName, dateLabel, teacherName;
  final int chapters, lessons;
}
