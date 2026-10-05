import 'package:lucena/data/repositories/school/lesson_repository.dart';
import 'package:lucena/data/repositories/school/school_progress_repository.dart';
import 'package:lucena/domain/models/lesson.dart';

/// Um curso pequeno, com um passo de cada tipo.
class FakeLessonRepository implements LessonRepository {
  FakeLessonRepository({Course? course, LessonTexts? texts})
    : _course = course ?? sample,
      _texts = texts ?? sampleTexts;

  final Course _course;
  final LessonTexts _texts;

  /// As línguas pedidas.
  final languages = <String>[];

  static const sample = Course(
    modules: [
      CourseModule(
        id: 'pieces',
        lessons: [
          Lesson(
            id: 'pieces.rook',
            steps: [
              TalkStep(id: 'intro', fen: '8/8/8/8/3R4/8/8/8 w - - 0 1'),
              StarsStep(
                id: 'stars',
                fen: '8/8/8/8/8/8/8/R7 w - - 0 1',
                stars: ['a5', 'e5'],
              ),
            ],
          ),
          Lesson(
            id: 'pieces.mate',
            steps: [
              MoveStep(
                id: 'mate',
                fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
                line: [
                  MoveTurn(accept: {'a1a8'}),
                ],
              ),
            ],
          ),
        ],
      ),
      CourseModule(
        id: 'mates',
        lessons: [
          Lesson(
            id: 'mates.queen',
            steps: [
              PlayStep(id: 'play', fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1'),
            ],
          ),
        ],
      ),
    ],
  );

  static final sampleTexts = LessonTexts.fromJson({
    'module.pieces': 'The pieces',
    'module.mates': 'First mates',
    'pieces.rook.title': 'The rook',
    'pieces.rook.intro': 'The rook moves in straight lines.',
    'pieces.rook.stars': 'Take the rook to the stars.',
    'pieces.rook.stars.done': 'Well done!',
    'pieces.mate.title': 'Checkmate',
    'pieces.mate.mate': 'Find the mate.',
    'pieces.mate.mate.hint': 'The back rank is weak.',
    'mates.queen.title': 'Queen mate',
    'mates.queen.play': 'Mate the king.',
    'coach.praise': ['Excellent.'],
    'coach.good': ['Good.'],
    'coach.star': ['A star!'],
    'coach.hint': ['Look at this move.'],
    'coach.stalemate': ['Stalemate!'],
    'coach.draw': ['A draw.'],
    'coach.lost': ['You were mated.'],
    'coach.retry': ['Again.'],
    'coach.keepGoing': ['Keep going.'],
    'coach.lessonDone': ['Lesson done.'],
    'coach.graduation': ['You graduated.'],
    'school.welcome': 'Welcome.',
    'school.welcomeBack': ['Welcome back.'],
    'school.graduated': 'Graduated.',
  });

  @override
  Future<Course> course() async => _course;

  @override
  Future<LessonTexts> texts(String language) async {
    languages.add(language);
    return _texts;
  }
}

class FakeSchoolProgressRepository implements SchoolProgressRepository {
  FakeSchoolProgressRepository([this.saved = const SchoolProgress()]);

  SchoolProgress saved;

  @override
  Future<SchoolProgress> load() async => saved;

  @override
  Future<void> save(SchoolProgress progress) async => saved = progress;
}
