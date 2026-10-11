import '../models/endgame_filter.dart';
import '../models/endgame_lesson.dart';
import '../models/placement.dart';
import '../models/rating_level.dart';

/// De onde vêm os dados dos filtros das aulas de finais: o tipo, pelo
/// material do treino final; a dificuldade, pela faixa do mapa de
/// habilidades (`skills.json`) que liga o nó à aula.
abstract final class EndgameLessonFilter {
  /// Os tipos de final de uma aula, pelas peças da posição do treino final.
  static Set<EndgameKind> kinds(EndgameLesson lesson) =>
      kindsOfFen(lesson.practice.fen);

  /// Os tipos de final pelas peças de uma posição (FEN).
  static Set<EndgameKind> kindsOfFen(String fen) {
    final board = fen.split(' ').first.toLowerCase();
    final queen = board.contains('q');
    final rook = board.contains('r');
    final bishop = board.contains('b');
    final knight = board.contains('n');
    final pawn = board.contains('p');
    return {
      if (queen) EndgameKind.queen,
      if (rook) EndgameKind.rook,
      if (bishop) EndgameKind.bishop,
      if (knight) EndgameKind.knight,
      if ((bishop || knight) && !queen && !rook) EndgameKind.minor,
      if (pawn && !queen && !rook && !bishop && !knight) EndgameKind.pawn,
    };
  }

  /// A faixa de cada aula: a mais fácil dos nós que a ensinam (é por ela
  /// que a aula começa). A aula sem nó fica de fora.
  static Map<String, RatingLevel> levels(SkillMap skills) {
    final levels = <String, RatingLevel>{};
    for (final node in skills.nodes) {
      for (final lesson in node.lessons) {
        if (lesson.kind != SkillLessonKind.endgame) continue;
        final current = levels[lesson.id];
        if (current == null || node.band.index < current.index) {
          levels[lesson.id] = node.band;
        }
      }
    }
    return levels;
  }
}
