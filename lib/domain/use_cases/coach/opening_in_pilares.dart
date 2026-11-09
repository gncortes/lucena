import '../../models/training/training_content.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import 'opening_in_course.dart';

/// Uma lição (parte) de uma abertura do Pilares.
final class OpeningPart {
  const OpeningPart({
    required this.number,
    required this.lessonEntry,
    required this.done,
  });

  /// 1, 2, 3… na ordem do curso.
  final int number;
  final TrainingLesson lessonEntry;
  final bool done;
}

/// As partes de uma abertura no curso e a que o Treinador põe em evidência.
final class OpeningInPilares {
  const OpeningInPilares({
    required this.slot,
    required this.parts,
    required this.highlight,
  });

  final String slot;
  final List<OpeningPart> parts;

  /// A parte que trata do ponto fraco: a que o servidor ligou; sem isso, a
  /// primeira por fazer (ou a primeira, se todas estão feitas).
  final OpeningPart highlight;

  /// O repertório da abertura (`solido` ou `agressivo`).
  String get perfil => const {'london', 'caroKann', 'slav'}.contains(slot)
      ? 'solido'
      : 'agressivo';

  bool get allDone => parts.every((p) => p.done);
}

/// As lições do [slot] no curso, na ordem dele, com a parte em destaque.
/// `null` quando o curso não tem essa abertura.
OpeningInPilares? openingInPilares({
  required String slot,
  required TrainingResources resources,
  TrainingState? state,
  int? serverPart,
}) {
  final lessons = [
    for (final l in resources.lessons)
      if (lessonSlot(l.id) == slot ||
          resources.openings[l.id]?.firstOrNull?.openingId == slot)
        l,
  ];
  if (lessons.isEmpty) return null;
  final doneOnes = state?.completedLessons ?? const <String, String>{};
  final parts = [
    for (final (i, l) in lessons.indexed)
      OpeningPart(
        number: i + 1,
        lessonEntry: l,
        done: doneOnes.containsKey(l.id),
      ),
  ];
  final fromServer = serverPart == null
      ? null
      : parts.where((p) => p.number == serverPart).firstOrNull;
  final highlight =
      fromServer ?? parts.where((p) => !p.done).firstOrNull ?? parts.first;
  return OpeningInPilares(slot: slot, parts: parts, highlight: highlight);
}
