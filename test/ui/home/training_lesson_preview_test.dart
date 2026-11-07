import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/home/view_models/training_lesson_preview.dart';

import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/training/mock_exercise_bank.dart';

void main() {
  LessonScript script({bool entry = true}) => LessonScript(
    lessonId: 'pilares.c1',
    partId: 'knightFork',
    stages: [
      ScriptStage(
        id: 'ideia',
        examples: [
          ScriptExample(
            id: 'source',
            fen: MockExerciseBank.fen,
            flip: true,
            goal: ScriptGoal.mate,
            entry: entry
                ? const [
                    ScriptStep(
                      fen: MockExerciseBank.blackFen,
                      t: 'source.text',
                    ),
                  ]
                : const [],
            line: const [],
            end: ScriptEnd.etapa,
          ),
        ],
      ),
    ],
  );

  test(
    'preview uses first real entry FEN, orientation and localized text',
    () async {
      final repository = FakeLessonScriptRepository(script(), {
        'source.text': 'Texto da fonte',
      });
      final load = trainingLessonPreviewLoader(
        scripts: repository,
        language: 'pt',
      );
      final preview = await load(
        const TrainingLesson(
          id: 'pilares.c1.knightFork',
          kind: TrainingLessonKind.theme,
          title: 'Garfo',
          groupId: 'pilares.c1',
        ),
      );
      expect(repository.paths, [
        'assets/lessons/roteiros/pilares.c1/knightFork.json',
      ]);
      expect(preview!.fen, MockExerciseBank.blackFen);
      expect(preview.orientation, Side.black);
      expect(preview.speech, ['Texto da fonte']);
      expect(preview.movable, isNull);
      expect(repository.languages, ['pt']);
    },
  );

  test('whole chapter reference has no invented scripted preview', () async {
    final repository = FakeLessonScriptRepository(script());
    final preview =
        await trainingLessonPreviewLoader(scripts: repository, language: 'pt')(
          const TrainingLesson(
            id: 'rook.lucena',
            kind: TrainingLessonKind.theme,
            title: 'Lucena',
            groupId: 'pilares.c4',
          ),
        );
    expect(preview, isNull);
    expect(repository.paths, isEmpty);
  });

  test(
    'unknown opening of script has no invented position or missing-text key',
    () async {
      final repository = FakeLessonScriptRepository(script(entry: false));
      final preview =
          await trainingLessonPreviewLoader(
            scripts: repository,
            language: 'pt',
          )(
            const TrainingLesson(
              id: 'rook',
              kind: TrainingLessonKind.school,
              title: 'Torre',
            ),
          );
      expect(repository.paths, ['assets/lessons/roteiros/rook.json']);
      expect(preview, isNull);
    },
  );
}
