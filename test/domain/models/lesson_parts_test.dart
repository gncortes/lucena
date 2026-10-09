import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';

/// T51, C1: aulas em partes, os passos `think` e `demo`, a parte
/// recomendada (sem travas) e a migração do progresso antigo.
void main() {
  const fen = '2k5/1r6/2K5/Q7/8/8/8/8 w - - 0 1';

  Map<String, dynamic> talk(String id) => {
    'type': 'talk',
    'id': id,
    'fen': fen,
  };

  final parted = AssetLessonRepository.parseLesson({
    'id': 'queen.vsRook.philidor',
    'parts': [
      {
        'id': 'philidor',
        'steps': [
          {
            'type': 'think',
            'id': 't1',
            'fen': fen,
            'minutes': 5,
            'hints': 2,
            'arrows': ['a5e5'],
            'marks': ['e8'],
          },
          talk('intro'),
          {
            'type': 'move',
            'id': 'pin',
            'fen': fen,
            'line': [
              {
                'teach': 'a5a6',
                'accept': ['a5a6'],
              },
            ],
          },
        ],
      },
      {
        'id': 'fork',
        'steps': [
          {
            'type': 'demo',
            'id': 'd1',
            'fen': fen,
            'side': 'white',
            'line': [
              {
                'uci': 'a5e5',
                'arrows': ['e5e8'],
              },
              {'uci': 'b7b1'},
            ],
          },
          talk('far'),
        ],
      },
    ],
  });

  EndgameLesson endgame(Lesson lesson) => EndgameLesson(
    id: lesson.id,
    module: 'queen',
    lesson: lesson,
    exercises: const [],
    passScore: 0,
    keyPositions: const [],
    practice: const Practice(fen: fen, goal: PositionGoal.win),
  );

  test('lê as partes, com os passos de pensar e de demonstração', () {
    expect(parted.parts.map((part) => part.id), ['philidor', 'fork']);
    expect(parted.steps.map((step) => step.id), [
      't1',
      'intro',
      'pin',
      'd1',
      'far',
    ]);
    final think = parted.steps.first as ThinkStep;
    expect(think.minutes, 5);
    expect(think.hints, 2);
    expect(think.arrows, [('a5', 'e5')]);
    expect(think.marks, ['e8']);
    final demo = parted.part('fork')!.steps.first as DemoStep;
    expect(demo.line.map((move) => move.uci), ['a5e5', 'b7b1']);
    expect(demo.line.first.arrows, [('e5', 'e8')]);
  });

  test('aula no formato antigo é lida como uma parte só', () {
    final old = AssetLessonRepository.parseLesson({
      'id': 'rook.lucena',
      'steps': [talk('a'), talk('b')],
    });
    expect(old.parts, isEmpty);
    expect(old.sections.single.id, Lesson.wholeId);
    expect(old.sections.single.steps.length, 2);
  });

  test('o passo da aula inteira cai na parte certa', () {
    final (part, step) = parted.locate(3)!;
    expect(part.id, 'fork');
    expect(step, 0);
    expect(parted.locate(9), isNull);
  });

  test('a parte recomendada é a primeira não feita, e nada trava', () {
    final lesson = endgame(parted);
    expect(
      EndgameLessonRules.recommendedPart(
        lesson,
        const EndgameLessonProgress(),
      )?.id,
      'philidor',
    );
    // Fez só a segunda: a recomendada continua sendo a primeira.
    const second = EndgameLessonProgress(parts: {'fork'});
    expect(EndgameLessonRules.recommendedPart(lesson, second)?.id, 'philidor');

    final both = EndgameLessonRules.completePart(lesson, second, 'philidor');
    expect(both.lessonDone, isTrue);
    expect(EndgameLessonRules.recommendedPart(lesson, both), isNull);
  });

  test('lição concluída antes das partes: todas as partes feitas', () {
    final lesson = endgame(parted);
    final old = EndgameLessonProgress.fromJson({
      'lessonDone': true,
      'stars': {'e01': 2},
    });
    expect(old.partsDone(lesson), {'philidor', 'fork'});
    expect(old.stars, {'e01': 2});
    expect(EndgameLessonRules.recommendedPart(lesson, old), isNull);
  });

  test('checkpoint antigo (passo da aula inteira) vira o da parte', () {
    final lesson = endgame(parted);
    final old = LessonCheckpoint.fromJson({
      'lesson': 'queen.vsRook.philidor',
      'step': 4,
      'fen': fen,
      'open': true,
    });
    final migrated = EndgameLessonRules.migrate(lesson, old)!;
    expect(migrated.part, 'fork');
    expect(migrated.step, 1);
    expect(migrated.fen, fen);
    expect(migrated.open, isTrue);
  });

  test('checkpoint com o timer e as dicas volta igual', () {
    final checkpoint = LessonCheckpoint(
      lessonId: 'queen.vsRook.philidor',
      step: 0,
      part: 'philidor',
      thinkStartedAt: DateTime.utc(2026, 10, 8, 20),
      hintsShown: 1,
      demoMove: 2,
    );
    expect(LessonCheckpoint.fromJson(checkpoint.toJson()), checkpoint);
    final progress = const EndgameLessonProgress(parts: {'fork'}).toJson();
    expect(EndgameLessonProgress.fromJson(progress).parts, {'fork'});
  });

  test('tempo estimado da parte', () {
    // 5 min de pensar + meio minuto de conversa + 1 min de prática.
    expect(parted.part('philidor')!.minutes, 7);
  });
}
