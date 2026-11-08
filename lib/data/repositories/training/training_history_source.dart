import 'dart:convert';

import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/training_date.dart';
import '../learning/learning_repository.dart';
import 'course_training_repository.dart';

/// Bootstrap current-version, observed account completions before the first
/// plan. Live training then follows explicit completion events. Undated legacy
/// grades and guest history never become nominal account completions.
final class TrainingHistorySource {
  const TrainingHistorySource(
    this.repository, {
    required this.learning,
    required this.now,
  });
  final TrainingRepository repository;
  final LearningRepository? learning;
  final Now now;

  Future<void> bootstrap(TrainingCourseConfig config) async {
    final source = learning;
    if (source == null) return;
    final uid = source.currentUid();
    final before = await repository.load(config.course);
    if (before.onboardingDone || before.day != null) return;
    final records = uid == null ? [] : await source.load(uid);
    if (records.isEmpty && before.bootstrapImports.isEmpty) return;
    final resources = await repository.resources(config.course);
    final versions = <(bool, String), Future<String?>>{};
    final completed =
        <String, ({TrainingLesson lesson, String date, String version})>{};
    final at = now();
    for (final record in records) {
      if (!const {
        'school_lesson',
        'endgame_lesson',
        'endgame_chapter',
      }.contains(record.kind)) {
        continue;
      }
      final id = record.kind == 'endgame_lesson'
          ? record.unitId.replaceAll('/', '.')
          : record.unitId;
      final lesson = resources.lessons
          .where((l) => l.visible && l.id == id)
          .firstOrNull;
      if (lesson == null ||
          (record.kind == 'school_lesson') !=
              (lesson.kind == TrainingLessonKind.school)) {
        continue;
      }
      final date = lesson.kind == TrainingLessonKind.test
          ? record.testPassedAt
          : record.contentCompletedAt;
      if (date == null || date.isAfter(at)) continue;
      final endgame = record.kind != 'school_lesson';
      final root = record.unitId.split('/').first;
      final version = await versions.putIfAbsent((
        endgame,
        root,
      ), () => source.versionOf(endgame, root));
      if (version == null || version != record.version) continue;
      completed[lesson.id] = (
        lesson: lesson,
        date: trainingDate(date.toLocal()),
        version: version,
      );
    }
    if (source.currentUid() != uid) return;
    await repository.update(config.course, (current) {
      if (current.onboardingDone ||
          current.day != null ||
          source.currentUid() != uid) {
        return current;
      }
      var next = current;
      final imports = {...current.bootstrapImports};
      final lessons = {...current.completedLessons};
      final cycles = {...current.cycles};
      final openings = {...current.openings};
      for (final entry in current.bootstrapImports.entries) {
        final id = entry.key;
        final imported = entry.value;
        final candidate = completed[id];
        final untouched =
            lessons[id] == imported.completedOn &&
            (imported.cycleJson == null ||
                imported.cycleJson == jsonEncode(cycles[id]?.toJson())) &&
            (imported.openingJson == null ||
                imported.openingJson == jsonEncode(openings[id]?.toJson()));
        if (untouched &&
            candidate?.version == imported.version &&
            candidate?.date == imported.completedOn) {
          continue;
        }
        imports.remove(id);
        // A changed track/date has become operational. Relinquish provenance,
        // preserving its completion and all work, even if the source expired.
        if (!untouched) continue;
        lessons.remove(id);
        if (imported.cycleJson != null) cycles.remove(id);
        if (imported.openingJson != null) openings.remove(id);
      }
      if (imports.length != current.bootstrapImports.length) {
        next = current.copyWith(
          completedLessons: lessons,
          cycles: cycles,
          openings: openings,
          bootstrapImports: imports,
        );
      }
      for (final entry in completed.values) {
        if (next.completedLessons.containsKey(entry.lesson.id)) continue;
        final previousCycle = next.cycles[entry.lesson.id];
        final previousOpening = next.openings[entry.lesson.id];
        if (!next.cycles.containsKey(entry.lesson.id) &&
            !next.openings.containsKey(entry.lesson.id)) {
          next = config.followUps.lessonCompleted(
            next,
            entry.lesson,
            entry.date,
          );
        }
        next = next.copyWith(
          completedLessons: {
            ...next.completedLessons,
            entry.lesson.id: entry.date,
          },
          bootstrapImports: {
            ...next.bootstrapImports,
            entry.lesson.id: TrainingBootstrapImport(
              version: entry.version,
              completedOn: entry.date,
              cycleJson:
                  previousCycle == null && next.cycles[entry.lesson.id] != null
                  ? jsonEncode(next.cycles[entry.lesson.id]!.toJson())
                  : null,
              openingJson:
                  previousOpening == null &&
                      next.openings[entry.lesson.id] != null
                  ? jsonEncode(next.openings[entry.lesson.id]!.toJson())
                  : null,
            ),
          },
        );
      }
      return next;
    });
  }
}
