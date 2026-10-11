import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/goldens/golden_harness.dart';

void main() {
  const teaching = {
    'pt':
        'Dama contra torre é vitória, mas a dama sozinha não consegue: a '
        'torre colada no rei defende tudo. Primeiro, empurre o rei preto '
        'para a borda e só então procure o garfo.',
    'ar':
        'الوزير ضد الرخ فوز، لكن الوزير وحده لا يكفي: الرخ الملتصق بالملك '
        'يدافع عن كل شيء. ادفع الملك الأسود أولًا إلى الحافة ثم ابحث عن '
        'الشوكة.',
  };
  const game = {
    'pt': 'Esse lance eu não esperava!',
    'ar': 'لم أتوقع هذه النقلة!',
  };

  group('TeacherSpeech, ensino (balão embaixo)', () {
    Goldens.matrix(
      'teacher_speech_teaching',
      (variant) => TeacherSpeech(
        teacher: FakeCharacterRepository.viktor,
        text: teaching[variant.locale.languageCode],
        speechContext: SpeechContext.teaching,
      ),
      height: 320,
    );
  });

  group('TeacherSpeech, partida (balão ao lado)', () {
    Goldens.matrix(
      'teacher_speech_game',
      (variant) => TeacherSpeech(
        teacher: FakeCharacterRepository.viktor,
        text: game[variant.locale.languageCode],
        speechContext: SpeechContext.game,
      ),
      height: 200,
    );
  });
}
