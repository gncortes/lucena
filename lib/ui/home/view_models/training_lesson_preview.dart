import '../../../data/repositories/school/lesson_script_repository.dart';
import '../../../data/repositories/school/lesson_script_repository_asset.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';

/// Read-only projection of the opening of the item that Routes.trainingLesson
/// opens. It never starts a lesson or writes a learning checkpoint.
Future<LessonScriptState?> Function(TrainingLesson)
trainingLessonPreviewLoader({
  required LessonScriptRepository scripts,
  required String language,
}) => (lesson) async {
  final String path;
  if (lesson.kind == TrainingLessonKind.school) {
    return null;
  } else {
    final root = lesson.groupId;
    if (root.isEmpty || !lesson.id.startsWith('$root.')) return null;
    path = AssetLessonScriptRepository.chapterScriptPath(
      root,
      lesson.id.substring(root.length + 1),
    );
  }
  final script = await scripts.script(path);
  final stage = script.stages.firstOrNull;
  final example = stage?.examples.firstOrNull;
  final step = example?.entry.firstOrNull;
  if (stage == null || example == null || step == null) return null;
  final texts = await scripts.texts(script.lessonId, language);
  return LessonScriptState(
    ready: true,
    stageCount: script.stages.length,
    stageId: stage.id,
    exampleCount: stage.examples.length,
    fen: step.fen,
    orientation: example.student,
    lastMove: step.move,
    speech: texts.has(step.t) ? [texts.say(step.t)] : const [],
    marks: step.marks,
    arrows: step.arrows,
    primary: ScriptAction.continuar,
  );
};
