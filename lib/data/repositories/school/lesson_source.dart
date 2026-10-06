import '../../../domain/models/lesson.dart';
import '../endgames/endgame_lesson_repository.dart';
import '../endgames/endgame_progress_repository.dart';
import 'lesson_repository.dart';
import 'school_progress_repository.dart';

/// De onde uma aula vem e onde o progresso dela fica: a escola do iniciante
/// ou a trilha das aulas de finais. A tela da aula é a mesma.
abstract class LessonSource {
  /// É uma lição de aula de final (a tela de fim volta para a aula, em vez
  /// de seguir a trilha da escola).
  bool get endgame;

  Future<Lesson?> lesson(String id);

  Future<LessonTexts> texts(String language);

  /// A posição da aula no conjunto (1 é a primeira) e quantas há.
  Future<(int, int)> placeOf(String id);

  /// Onde o aluno parou, se há aula começada.
  Future<LessonCheckpoint?> checkpoint();

  Future<void> saveCheckpoint(LessonCheckpoint checkpoint);

  /// Sair pelo voltar: o passo fica guardado, mas o app não reabre na aula.
  Future<void> leave();

  /// Conclui a aula [id]: grava e diz o que vem depois.
  Future<LessonOutcome> complete(String id);
}

/// O que acontece ao concluir uma aula.
class LessonOutcome {
  const LessonOutcome({this.last = false, this.next});

  /// Era a última do conjunto (na escola, a formatura).
  final bool last;

  /// A próxima aula. Nula na última.
  final String? next;
}

/// As aulas da escola, com o progresso dela.
class SchoolLessonSource implements LessonSource {
  SchoolLessonSource(this._lessons, this._progress);

  final LessonRepository _lessons;
  final SchoolProgressRepository _progress;

  @override
  bool get endgame => false;

  @override
  Future<Lesson?> lesson(String id) async =>
      (await _lessons.course()).lesson(id);

  @override
  Future<LessonTexts> texts(String language) => _lessons.texts(language);

  @override
  Future<(int, int)> placeOf(String id) async {
    final lessons = (await _lessons.course()).lessons;
    return (
      lessons.indexWhere((lesson) => lesson.id == id) + 1,
      lessons.length,
    );
  }

  @override
  Future<LessonCheckpoint?> checkpoint() async =>
      (await _progress.load()).ongoing;

  @override
  Future<void> saveCheckpoint(LessonCheckpoint checkpoint) async {
    final progress = await _progress.load();
    await _progress.save(progress.copyWith(ongoing: checkpoint));
  }

  @override
  Future<void> leave() async {
    final progress = await _progress.load();
    final ongoing = progress.ongoing;
    if (ongoing == null) return;
    await _progress.save(
      progress.copyWith(ongoing: ongoing.copyWith(open: false)),
    );
  }

  @override
  Future<LessonOutcome> complete(String id) async {
    final lessons = (await _lessons.course()).lessons;
    final progress = await _progress.load();
    final completed = {...progress.completed, id};
    await _progress.save(SchoolProgress(completed: completed));
    final index = lessons.indexWhere((lesson) => lesson.id == id);
    return LessonOutcome(
      last:
          lessons.last.id == id ||
          lessons.every((lesson) => completed.contains(lesson.id)),
      next: index >= 0 && index + 1 < lessons.length
          ? lessons[index + 1].id
          : null,
    );
  }
}

/// A lição de uma aula de final, com o progresso das aulas de finais.
class EndgameLessonSource implements LessonSource {
  EndgameLessonSource(this._lessons, this._progress);

  final EndgameLessonRepository _lessons;
  final EndgameProgressRepository _progress;

  @override
  bool get endgame => true;

  @override
  Future<Lesson?> lesson(String id) async =>
      (await _lessons.trail()).lesson(id)?.lesson;

  @override
  Future<LessonTexts> texts(String language) => _lessons.texts(language);

  @override
  Future<(int, int)> placeOf(String id) async {
    final lessons = (await _lessons.trail()).lessons;
    return (
      lessons.indexWhere((lesson) => lesson.id == id) + 1,
      lessons.length,
    );
  }

  @override
  Future<LessonCheckpoint?> checkpoint() async =>
      (await _progress.load()).ongoing;

  @override
  Future<void> saveCheckpoint(LessonCheckpoint checkpoint) async {
    final progress = await _progress.load();
    await _progress.save(progress.copyWith(ongoing: checkpoint));
  }

  @override
  Future<void> leave() async {
    final progress = await _progress.load();
    final ongoing = progress.ongoing;
    if (ongoing == null) return;
    await _progress.save(
      progress.copyWith(ongoing: ongoing.copyWith(open: false)),
    );
  }

  @override
  Future<LessonOutcome> complete(String id) async {
    final progress = await _progress.load();
    await _progress.save(
      progress
          .withLesson(id, progress.of(id).copyWith(lessonDone: true))
          .copyWith(clearOngoing: true),
    );
    final trail = await _lessons.trail();
    return LessonOutcome(
      last: trail.lessons.lastOrNull?.id == id,
      next: trail.after(id)?.id,
    );
  }
}
