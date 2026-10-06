import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';

/// As aulas de finais do Viktor e as falas delas.
abstract class EndgameLessonRepository {
  /// A trilha: os módulos com as aulas que existem, na ordem do catálogo.
  Future<EndgameTrail> trail();

  /// As falas de [language] (`pt`, `en`) de todas as aulas, com as chaves
  /// prefixadas pelo id da aula (`rook.lucena.title`, `rook.lucena.ex.e01`),
  /// por cima das falas da escola (`coach.*`, `module.*`). O que falta no
  /// idioma vem do inglês.
  Future<LessonTexts> texts(String language);
}
