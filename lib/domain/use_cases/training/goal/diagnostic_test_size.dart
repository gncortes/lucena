import '../../../models/training/goal/training_diagnostic.dart';
import 'plan_chapters.dart';

const minDiagnosticPositions = 5;
const maxDiagnosticPositions = 20;

/// Tamanho do teste de nível (H-TRE-04): curva única de 5 a 20 posições.
/// Até 2 horas de capacidade valem 5; 30 horas ou mais valem 20; no meio, linear.
int diagnosticTestSize(int capacityMinutes) {
  final hours = capacityMinutes / 60;
  final size = minDiagnosticPositions + ((hours - 2) * 15 / 28).round();
  return size.clamp(minDiagnosticPositions, maxDiagnosticPositions);
}

/// Capítulos do teste: espaçados pelo curso, um por posição, sem passar do que existe.
List<PlanChapter> diagnosticChapters(List<PlanChapter> candidates, int size) {
  if (candidates.isEmpty) return const [];
  final count = size.clamp(1, candidates.length);
  return [
    for (var i = 0; i < count; i++)
      candidates[(i * candidates.length) ~/ count],
  ];
}

/// Nível por parte do curso a partir do teste: 80% ou mais = domino, 50% = praticando.
Map<String, TopicLevel> levelsFromTest(
  List<PlanChapter> chapters,
  List<bool> answers,
) {
  final right = <String, int>{}, total = <String, int>{};
  for (var i = 0; i < answers.length && i < chapters.length; i++) {
    final part = chapters[i].partId;
    total[part] = (total[part] ?? 0) + 1;
    if (answers[i]) right[part] = (right[part] ?? 0) + 1;
  }
  return {
    for (final part in total.keys)
      part: switch ((right[part] ?? 0) / total[part]!) {
        >= 0.8 => TopicLevel.mastered,
        >= 0.5 => TopicLevel.practicing,
        _ => TopicLevel.learning,
      },
  };
}
