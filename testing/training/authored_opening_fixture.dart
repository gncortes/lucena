import 'dart:convert';

import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';

/// Keeps the legacy authored-example compatibility scenarios independent of
/// the current repertoire parts. Copies the same source objects as
/// tools/lessons/exportar_treino.py:opening_excerpts; never writes assets.
Future<TrainingResources> authoredOpeningFixture(
  LessonContentAssets assets,
  TrainingResources current,
) async {
  final openings = <String, List<OpeningTrecho>>{};
  final chapters = <String, Map<String, dynamic>>{};
  for (final lesson in current.lessons.where(
    (lesson) => lesson.kind == TrainingLessonKind.opening,
  )) {
    final chapter = chapters[lesson.groupId] ??= jsonDecode(
      await assets.loadString('assets/lessons/endgames/${lesson.groupId}.json'),
    ) as Map<String, dynamic>;
    final prefix = '${lesson.groupId}.';
    if (!lesson.id.startsWith(prefix)) {
      throw FormatException('Authored lesson is outside ${lesson.groupId}');
    }
    final sourcePart = lesson.id.substring(prefix.length);
    final part = (chapter['parts'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((part) => part['id'] == sourcePart);
    final path = part['roteiro'] as String;
    final source =
        jsonDecode(await assets.loadString(path)) as Map<String, dynamic>;
    if (source['licao'] != lesson.groupId || source['parte'] != sourcePart) {
      throw FormatException('Authored source does not match ${lesson.id}');
    }
    final ids = <String>{};
    openings[lesson.id] = [
      for (final stage
          in (source['etapas'] as List).cast<Map<String, dynamic>>())
        for (final example
            in (stage['exemplos'] as List).cast<Map<String, dynamic>>())
          _excerpt(lesson, stage, example, path, ids),
    ];
  }
  return TrainingResources(
    lessons: current.lessons,
    banks: current.banks,
    openings: openings,
    errorFeedback: current.errorFeedback,
    offlineChapters: current.offlineChapters,
    hasUnpublishedContent: current.hasUnpublishedContent,
  );
}

OpeningTrecho _excerpt(
  TrainingLesson lesson,
  Map<String, dynamic> stage,
  Map<String, dynamic> example,
  String path,
  Set<String> ids,
) {
  final id = '${stage['id']}.${example['id']}';
  if (!ids.add(id) || example['vira'] is! bool) {
    throw FormatException('Invalid authored example ${lesson.id}/$id');
  }
  return OpeningTrecho(
    id: id,
    title: lesson.title,
    fen: example['fen'] as String,
    black: example['vira'] as bool,
    stage: stage['id'] as String,
    source: path,
    example: example,
  );
}
