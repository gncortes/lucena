import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  final trail = FakeEndgameLessonRepository.sample;
  final lucena = trail.lesson('rook.lucena')!;

  test('acerto de primeira vale todas as estrelas; erro e dica tiram uma', () {
    expect(EndgameLessonRules.earned(3, mistakes: 0, hints: 0), 3);
    expect(EndgameLessonRules.earned(3, mistakes: 1, hints: 0), 2);
    expect(EndgameLessonRules.earned(3, mistakes: 1, hints: 1), 1);
    expect(EndgameLessonRules.earned(1, mistakes: 2, hints: 1), 0);
  });

  test('a nota passa com todos resolvidos e a soma no mínimo', () {
    expect(lucena.maxScore, 6);
    const partial = EndgameLessonProgress(stars: {'e01': 1, 'e02': 2});
    expect(EndgameLessonRules.allSolved(lucena, partial), isFalse);
    expect(EndgameLessonRules.passed(lucena, partial), isFalse);

    const low = EndgameLessonProgress(
      lessonDone: true,
      stars: {'e01': 1, 'e02': 1, 'e03': 1},
    );
    expect(low.score, 3);
    expect(EndgameLessonRules.allSolved(lucena, low), isTrue);
    expect(EndgameLessonRules.passed(lucena, low), isFalse);

    const enough = EndgameLessonProgress(
      lessonDone: true,
      stars: {'e01': 1, 'e02': 0, 'e03': 3},
    );
    expect(EndgameLessonRules.passed(lucena, enough), isTrue);
    // Sem a lição feita, a nota sozinha não aprova.
    const noLesson = EndgameLessonProgress(
      stars: {'e01': 1, 'e02': 2, 'e03': 3},
    );
    expect(EndgameLessonRules.passed(lucena, noLesson), isFalse);
  });

  test('o speedrun do final é o da posição do treino', () {
    expect(
      EndgameLessonRules.speedrunOf(lucena, sampleSpeedruns)?.id,
      'ending.queen',
    );
    expect(
      EndgameLessonRules.speedrunOf(
        trail.lesson('rook.philidor')!,
        sampleSpeedruns,
      ),
      isNull,
    );
  });

  test('a próxima aula é a primeira sem lição ou sem nota', () {
    expect(
      EndgameLessonRules.next(trail, const EndgameProgress())?.id,
      'rook.lucena',
    );
    final lessonOnly = EndgameProgress(
      lessons: {'rook.lucena': const EndgameLessonProgress(lessonDone: true)},
    );
    expect(EndgameLessonRules.next(trail, lessonOnly)?.id, 'rook.lucena');
    final passed = EndgameProgress(
      lessons: {
        'rook.lucena': const EndgameLessonProgress(
          lessonDone: true,
          stars: {'e01': 1, 'e02': 2, 'e03': 3},
        ),
      },
    );
    expect(EndgameLessonRules.next(trail, passed)?.id, 'rook.philidor');
    final all = passed.withLesson(
      'rook.philidor',
      const EndgameLessonProgress(lessonDone: true, stars: {'e01': 1}),
    );
    expect(EndgameLessonRules.next(trail, all), isNull);
  });
}
