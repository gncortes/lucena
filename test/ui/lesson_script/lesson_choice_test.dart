import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/script_fixture.dart';

void main() {
  for (final correct in [false, true]) {
    test(
      'authored choice $correct continues and cold restart begins the stage',
      () async {
        final json = scriptJson();
        final example =
            ((json['etapas'] as List).first['exemplos'] as List).first as Map;
        example['linha'] = [];
        final question = example['pergunta'] as Map;
        question['escolhas'] = [
          for (final result in [false, true])
            {
              't': result ? 'choice.no' : 'choice.yes',
              'correta': result,
              'passos': [
                {
                  'fen': example['fen'],
                  't': result ? 'choice.correct' : 'choice.wrong',
                },
              ],
            },
        ];
        final source = FakeLessonSource();
        LessonScriptCubit open() => LessonScriptCubit(
          lessonId: 'choice.fixture',
          partId: 'part',
          scriptPath: 'script.json',
          language: 'pt',
          scripts: FakeLessonScriptRepository(
            LessonScript.fromJson(json),
            scriptTexts(json),
          ),
          kpk: FakeKpkRepository(FakeKpkOracle()),
          source: source,
        );
        final cubit = open();
        await cubit.start();
        for (
          var i = 0;
          i < 10 && cubit.state.phase == ScriptPhase.entrada;
          i++
        ) {
          await cubit.onAction(ScriptAction.continuar);
        }
        expect(cubit.state.phase, ScriptPhase.pergunta);
        expect(cubit.answerChoices, ['choice.yes', 'choice.no']);
        expect(cubit.state.movable, isNull);
        expect(cubit.state.primary, isNull);
        final fen = cubit.state.fen;
        await cubit.answerChoice(correct ? 1 : 0);
        expect(cubit.state.tone, correct ? ScriptTone.good : ScriptTone.bad);
        expect(cubit.state.fen, fen);
        expect(cubit.state.primary, ScriptAction.continuar);
        expect(cubit.answerChoices, isEmpty);
        expect(
          source.checkpoints.last.scriptTrack,
          'choice:${correct ? 1 : 0}',
        );
        await cubit.onAction(ScriptAction.continuar);
        expect(cubit.state.exampleIndex, 1);
        await cubit.close();
        final restored = open();
        await restored.start();
        expect(restored.state.tone, ScriptTone.neutral);
        expect(restored.state.phase, ScriptPhase.entrada);
        expect(restored.state.exampleIndex, 0);
        final speech = restored.state.speech;
        await restored.answerChoice(correct ? 0 : 1);
        expect(restored.state.speech, speech);
        await restored.close();
      },
    );
  }
}
