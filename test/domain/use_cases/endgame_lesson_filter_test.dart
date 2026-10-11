import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_filter.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_filter.dart';

void main() {
  group('tipo de final pelo material do treino final', () {
    final cases = {
      '8/8/8/4k3/8/8/4P3/4K3 w - - 0 1': {EndgameKind.pawn},
      '8/8/8/4k3/8/8/8/4KQ2 w - - 0 1': {EndgameKind.queen},
      '8/1R6/6P1/8/6r1/7k/8/7K w - - 0 1': {EndgameKind.rook},
      '8/8/8/4k3/8/8/8/2Q1Kr2 w - - 0 1': {EndgameKind.queen, EndgameKind.rook},
      '8/8/8/4k3/8/8/8/3BKN2 w - - 0 1': {
        EndgameKind.bishop,
        EndgameKind.knight,
        EndgameKind.minor,
      },
      '8/8/8/4k3/8/8/p7/4KN2 w - - 0 1': {
        EndgameKind.knight,
        EndgameKind.minor,
      },
      '8/8/8/4k3/8/8/1P6/2R1Kb2 w - - 0 1': {
        EndgameKind.rook,
        EndgameKind.bishop,
      },
    };
    for (final MapEntry(key: fen, value: kinds) in cases.entries) {
      test(fen, () => expect(EndgameLessonFilter.kindsOfFen(fen), kinds));
    }
  });

  test('a faixa da aula é a mais fácil dos nós que a ensinam', () {
    final skills = SkillMap([
      const SkillNode(
        id: 'pawns.kingPawn',
        group: SkillGroup.pawns,
        band: RatingLevel.casual,
        lessons: [
          SkillLesson(id: 'basics.kingPawn', kind: SkillLessonKind.endgame),
        ],
      ),
      const SkillNode(
        id: 'pawns.rookPawnDraw',
        group: SkillGroup.pawns,
        band: RatingLevel.intermediate,
        lessons: [
          SkillLesson(id: 'basics.kingPawn', kind: SkillLessonKind.endgame),
          SkillLesson(id: 'pawns.rookPawnDraw', kind: SkillLessonKind.endgame),
          SkillLesson(id: 'school.x', kind: SkillLessonKind.school),
        ],
      ),
    ]);
    expect(EndgameLessonFilter.levels(skills), {
      'basics.kingPawn': RatingLevel.casual,
      'pawns.rookPawnDraw': RatingLevel.intermediate,
    });
  });
}
