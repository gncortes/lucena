import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/speech_keys.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';

void main() {
  test('chaves das histórias da Lição apontam para os widgets existentes', () {
    expect(LessonScriptKeys.balloonSeeMore, SpeechKeys.balloonSeeMore);
    expect(LessonScriptKeys.lessonVoiceToggle, VoiceKeys.speakButton);
    expect(LessonScriptKeys.lessonAnalyze, LessonScriptKeys.analyze);
    expect(LessonScriptKeys.lessonPauseToggle, LessonScriptKeys.demoToggle);
  });
}
