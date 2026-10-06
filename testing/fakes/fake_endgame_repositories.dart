import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';

import 'fake_school_repositories.dart';

/// Uma trilha pequena: duas aulas de torre, uma com speedrun e outra sem.
class FakeEndgameLessonRepository implements EndgameLessonRepository {
  FakeEndgameLessonRepository({EndgameTrail? trail, LessonTexts? texts})
    : _trail = trail ?? sample,
      _texts = texts ?? sampleTexts;

  final EndgameTrail _trail;
  final LessonTexts _texts;

  /// A Lucena de exemplo: a torre vai para a quarta fileira (a ponte).
  static const lucenaFen = '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1';

  static const sample = EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: 'rook.lucena',
            module: 'rook',
            lesson: Lesson(
              id: 'rook.lucena',
              steps: [
                TalkStep(id: 'intro', fen: lucenaFen),
                MoveStep(
                  id: 'bridge',
                  fen: lucenaFen,
                  line: [
                    MoveTurn(accept: {'c1c4'}),
                  ],
                ),
              ],
            ),
            exercises: [
              Exercise(
                id: 'e01',
                stars: 1,
                fen: lucenaFen,
                goal: PositionGoal.win,
                line: [
                  MoveTurn(accept: {'c1c4'}),
                ],
              ),
              Exercise(
                id: 'e02',
                stars: 2,
                fen: lucenaFen,
                goal: PositionGoal.win,
                line: [
                  // O ensinado é c1c4; c1c5 também é bom, mas sai da linha.
                  MoveTurn(accept: {'c1c4', 'c1c5'}, reply: 'a2a1'),
                  MoveTurn(accept: {'c4c5'}),
                ],
              ),
              Exercise(
                id: 'e03',
                stars: 3,
                fen: lucenaFen,
                goal: PositionGoal.win,
                line: [
                  MoveTurn(accept: {'c1c4'}),
                ],
              ),
            ],
            passScore: 4,
            keyPositions: [
              KeyPosition(id: 'lucena', fen: lucenaFen, ref: 'book1'),
            ],
            practice: Practice(
              fen: '8/1R6/6P1/8/6r1/7k/8/7K w - - 0 1',
              goal: PositionGoal.win,
              positionId: 'basic.queen.0001',
            ),
            references: [
              Reference(
                id: 'book1',
                kind: 'book',
                fields: {
                  'author': 'Author',
                  'title': 'Endgames',
                  'publisher': 'Press',
                  'year': '2008',
                },
              ),
              Reference(
                id: 'study1',
                kind: 'study',
                fields: {
                  'author': 'Someone',
                  'title': 'Rook endings',
                  'url': 'https://lichess.org/study/abc',
                },
              ),
            ],
          ),
          EndgameLesson(
            id: 'rook.philidor',
            module: 'rook',
            lesson: Lesson(
              id: 'rook.philidor',
              steps: [TalkStep(id: 'intro', fen: lucenaFen)],
            ),
            exercises: [
              Exercise(
                id: 'e01',
                stars: 1,
                fen: lucenaFen,
                goal: PositionGoal.win,
                line: [
                  MoveTurn(accept: {'c1c4'}),
                ],
              ),
            ],
            passScore: 1,
            keyPositions: [KeyPosition(id: 'philidor', fen: lucenaFen)],
            practice: Practice(
              fen: lucenaFen,
              goal: PositionGoal.draw,
              positionId: null,
            ),
          ),
        ],
      ),
    ],
  );

  static final sampleTexts = LessonTexts.fromJson({
    ...FakeLessonRepository.sampleTexts.toJson(),
    'endgames.welcome': 'These are the endgame lessons.',
    'endgames.welcomeBack': ['Good to see you again.'],
    'endgames.allPassed': 'All passed.',
    'endgames.module.rook': 'Rook endgames',
    'endgames.lesson.intro': 'First the lesson, then the exercises.',
    'endgames.lesson.passed': 'Passed.',
    'endgames.lesson.failed': 'Not this time.',
    'rook.lucena.title': 'The Lucena position',
    'rook.lucena.summary': 'The bridge.',
    'rook.lucena.intro': 'This is the Lucena position.',
    'rook.lucena.bridge': 'Build the bridge.',
    'rook.lucena.bridge.hint': 'The rook goes to the fourth rank.',
    'rook.lucena.bridge.done': 'That is the bridge.',
    'rook.lucena.ex.e01': 'White to play and win.',
    'rook.lucena.ex.e01.hint': 'Think of the bridge.',
    'rook.lucena.ex.e01.solution': 'The rook goes to c4.',
    'rook.lucena.ex.e02': 'Win again.',
    'rook.lucena.ex.e02.hint': 'Bridge first.',
    'rook.lucena.ex.e02.solution': 'Bridge, then the king walks out.',
    'rook.lucena.ex.e03': 'The hard one.',
    'rook.lucena.ex.e03.hint': 'Same idea.',
    'rook.lucena.ex.e03.solution': 'Same bridge.',
    'rook.lucena.key.lucena': 'The classic Lucena position.',
    'rook.lucena.history': 'Named after Lucena, shown by Salvio.',
    'rook.lucena.practice': 'Now the real endgame.',
    'rook.philidor.title': 'The Philidor defence',
    'rook.philidor.summary': 'The third rank.',
    'rook.philidor.intro': 'Hold the third rank.',
    'rook.philidor.ex.e01': 'Hold.',
    'rook.philidor.ex.e01.hint': 'Third rank.',
    'rook.philidor.ex.e01.solution': 'Rook to the third rank.',
    'rook.philidor.key.philidor': 'Philidor, 1777.',
    'rook.philidor.history': 'Philidor showed it in 1777.',
    'rook.philidor.practice': 'Defend.',
  });

  @override
  Future<EndgameTrail> trail() async => _trail;

  @override
  Future<LessonTexts> texts(String language) async => _texts;
}

class FakeEndgameProgressRepository implements EndgameProgressRepository {
  FakeEndgameProgressRepository([this.saved = const EndgameProgress()]);

  EndgameProgress saved;

  @override
  Future<EndgameProgress> load() async => saved;

  @override
  Future<void> save(EndgameProgress progress) async => saved = progress;
}
