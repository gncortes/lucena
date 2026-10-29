import '../models/race.dart';
import 'visible_lessons.dart';

/// Os acertos num tipo de final (o nome do final, como "Mate de torre") no
/// histórico de Corridas, com a categoria do catálogo dele.
class RaceFinalScore {
  const RaceFinalScore({
    required this.category,
    required this.subcategory,
    required this.corrects,
    required this.total,
  });

  final String category;
  final String subcategory;
  final int corrects;
  final int total;

  double get accuracy => total == 0 ? 0 : corrects / total;
}

/// O desempenho por final nas últimas Corridas (canvas V2 · Ligações, L6b):
/// o que o jogador já domina e onde pode melhorar.
class RaceDiagnosis {
  const RaceDiagnosis({
    required this.runs,
    this.mastered = const [],
    this.toImprove = const [],
  });

  /// O diagnóstico do [history] (a mais recente primeiro). [problems] dá a
  /// categoria de cada tipo de final.
  factory RaceDiagnosis.of(
    List<RaceResult> history,
    List<RaceProblem> problems,
  ) {
    final categoryOf = {
      for (final problem in problems) problem.subcategory: problem.category,
    };
    final recent = history.take(lastRuns).toList();
    final corrects = <String, int>{};
    final totals = <String, int>{};
    for (final result in recent) {
      for (final answer in result.run.answers) {
        final subcategory = answer.subcategory;
        if (subcategory == null || !categoryOf.containsKey(subcategory)) {
          continue;
        }
        totals[subcategory] = (totals[subcategory] ?? 0) + 1;
        if (answer.correct) {
          corrects[subcategory] = (corrects[subcategory] ?? 0) + 1;
        }
      }
    }
    final scores = [
      for (final MapEntry(key: subcategory, value: total) in totals.entries)
        if (total >= minProblems)
          RaceFinalScore(
            category: categoryOf[subcategory]!,
            subcategory: subcategory,
            corrects: corrects[subcategory] ?? 0,
            total: total,
          ),
    ]..sort(_worstFirst);
    return RaceDiagnosis(
      runs: recent.length,
      mastered: [
        for (final score in scores.reversed)
          if (score.accuracy >= masteredAccuracy) score,
      ],
      toImprove: [
        for (final score in scores)
          if (score.accuracy < masteredAccuracy) score,
      ],
    );
  }

  /// Quantas Corridas (as mais recentes) entram na conta.
  static const lastRuns = 10;

  /// Com quantas Corridas o diagnóstico aparece.
  static const neededRuns = 3;

  /// Quantos problemas um final precisa para entrar.
  static const minProblems = 4;

  /// A partir de que taxa de acerto o jogador domina o final.
  static const masteredAccuracy = 0.7;

  /// Quantas Corridas entraram na conta (no máximo [lastRuns]).
  final int runs;

  /// Os finais que o jogador domina, do melhor para o pior.
  final List<RaceFinalScore> mastered;

  /// Os que ele pode melhorar, do pior para o melhor.
  final List<RaceFinalScore> toImprove;

  /// Já há Corridas e problemas suficientes para mostrar o desempenho.
  bool get ready =>
      runs >= neededRuns && (mastered.isNotEmpty || toImprove.isNotEmpty);

  /// O final mais fraco, se houver.
  RaceFinalScore? get weakest => toImprove.firstOrNull;

  // Menor acerto primeiro; empate, o que tem mais problemas.
  static int _worstFirst(RaceFinalScore a, RaceFinalScore b) {
    final byAccuracy = a.accuracy.compareTo(b.accuracy);
    return byAccuracy != 0 ? byAccuracy : b.total.compareTo(a.total);
  }
}

/// A aula de um tipo de final: da Escola ([school]) ou das aulas de finais.
class RaceFinalLesson {
  const RaceFinalLesson({
    required this.subcategory,
    required this.lessonId,
    required this.school,
  });

  final String subcategory;
  final String lessonId;
  final bool school;

  /// A aula que o app tem para cada tipo de final da Corrida.
  static const all = [
    RaceFinalLesson(
      subcategory: 'queen',
      lessonId: 'mates.queen',
      school: true,
    ),
    RaceFinalLesson(
      subcategory: 'rook',
      lessonId: 'technique.rookMate',
      school: true,
    ),
    RaceFinalLesson(
      subcategory: 'pawnVsKing',
      lessonId: 'pawns.keySquares',
      school: false,
    ),
    RaceFinalLesson(
      subcategory: 'knightBishopVsKing',
      lessonId: 'mates.bishopKnight.deletang',
      school: false,
    ),
    RaceFinalLesson(
      subcategory: 'queenVsRook',
      lessonId: 'queen.vsRook.philidor',
      school: false,
    ),
    RaceFinalLesson(
      subcategory: 'rookPawnVsRook',
      lessonId: 'rook.lucena',
      school: false,
    ),
  ];

  /// A aula liberada ([VisibleLessons]) de cada final de [scores], na mesma
  /// ordem; o final sem aula liberada fica de fora.
  static List<RaceFinalLesson> forScores(List<RaceFinalScore> scores) => [
    for (final score in scores)
      for (final lesson in all)
        if (lesson.subcategory == score.subcategory && lesson.visible) lesson,
  ];

  bool get visible => school
      ? VisibleLessons.schoolLessonIds.contains(lessonId)
      : VisibleLessons.endgameLessonIds.contains(lessonId);
}
