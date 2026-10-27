import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
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

  /// As referências da aula [id] (partidas, estudos...), que o `ref` de um
  /// passo aponta. A escola não tem.
  Future<List<Reference>> references(String id);

  /// A posição da aula no conjunto (1 é a primeira) e quantas há.
  Future<(int, int)> placeOf(String id);

  /// A aula [id] nunca foi começada: nenhuma parte feita, nenhuma estrela e
  /// nenhum ponto de retomada dela (a `primeira_vez` do Analytics).
  Future<bool> untouched(String id);

  /// Onde o aluno parou, se há aula começada.
  Future<LessonCheckpoint?> checkpoint();

  Future<void> saveCheckpoint(LessonCheckpoint checkpoint);

  /// Descarta o ponto de retomada (ele aponta para o que não existe mais).
  Future<void> clearCheckpoint();

  /// Sair pelo voltar: o passo fica guardado, mas o app não reabre na aula.
  Future<void> leave();

  /// Conclui a aula [id]: grava e diz o que vem depois.
  Future<LessonOutcome> complete(String id);

  /// Conclui a parte [partId] da aula [id] (aula em partes, T51): grava e
  /// diz a próxima parte recomendada.
  Future<LessonOutcome> completePart(String id, String partId);
}

/// O que acontece ao concluir uma aula.
class LessonOutcome {
  const LessonOutcome({
    this.last = false,
    this.next,
    this.nextPart,
    this.path = const [],
  });

  /// Na formatura da escola: os módulos que o aluno percorreu, em ordem
  /// (o caminho que vai na imagem de compartilhar).
  final List<CourseModule> path;

  /// Numa aula em partes: a próxima parte recomendada. Nula com todas
  /// feitas (o próximo é o teste final).
  final String? nextPart;

  /// Era a última do conjunto (na escola, a formatura).
  final bool last;

  /// A próxima aula. Nula na última.
  final String? next;
}

/// Serializa snapshots e saída para uma gravação pendente não reabrir a aula.
mixin _CheckpointWriter {
  Future<void> _checkpointWrites = Future<void>.value();

  Future<void> _writeCheckpoint(Future<void> Function() write) {
    final next = _checkpointWrites.then((_) => write());
    // Uma falha é devolvida ao chamador, sem bloquear gravações futuras.
    _checkpointWrites = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }
}

/// As aulas da escola, com o progresso dela.
class SchoolLessonSource with _CheckpointWriter implements LessonSource {
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
  Future<List<Reference>> references(String id) async => const [];

  @override
  Future<(int, int)> placeOf(String id) async {
    final lessons = (await _lessons.course()).lessons;
    return (
      lessons.indexWhere((lesson) => lesson.id == id) + 1,
      lessons.length,
    );
  }

  @override
  Future<bool> untouched(String id) async {
    final progress = await _progress.load();
    return !progress.completed.contains(id) && progress.ongoing?.lessonId != id;
  }

  @override
  Future<LessonCheckpoint?> checkpoint() async =>
      (await _progress.load()).ongoing;

  @override
  Future<void> saveCheckpoint(LessonCheckpoint checkpoint) =>
      _writeCheckpoint(() async {
        final progress = await _progress.load();
        await _progress.save(progress.copyWith(ongoing: checkpoint));
      });

  @override
  Future<void> clearCheckpoint() => _writeCheckpoint(() async {
    final progress = await _progress.load();
    await _progress.save(progress.copyWith(clearOngoing: true));
  });

  @override
  Future<void> leave() => _writeCheckpoint(() async {
    final progress = await _progress.load();
    final ongoing = progress.ongoing;
    if (ongoing == null) return;
    await _progress.save(
      progress.copyWith(ongoing: ongoing.copyWith(open: false)),
    );
  });

  @override
  Future<LessonOutcome> complete(String id) async {
    await _checkpointWrites;
    final course = await _lessons.course();
    final lessons = course.lessons;
    final progress = await _progress.load();
    final completed = {...progress.completed, id};
    await _progress.save(SchoolProgress(completed: completed));
    final index = lessons.indexWhere((lesson) => lesson.id == id);
    final last =
        lessons.last.id == id ||
        lessons.every((lesson) => completed.contains(lesson.id));
    return LessonOutcome(
      last: last,
      path: last ? course.modules : const [],
      next: index >= 0 && index + 1 < lessons.length
          ? lessons[index + 1].id
          : null,
    );
  }

  // A escola não tem partes: a aula inteira é a parte.
  @override
  Future<LessonOutcome> completePart(String id, String partId) => complete(id);
}

/// A lição de uma aula de final, com o progresso das aulas de finais.
class EndgameLessonSource with _CheckpointWriter implements LessonSource {
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
  Future<List<Reference>> references(String id) async =>
      (await _lessons.trail()).lesson(id)?.references ?? const [];

  @override
  Future<(int, int)> placeOf(String id) async {
    final lessons = (await _lessons.trail()).lessons;
    return (
      lessons.indexWhere((lesson) => lesson.id == id) + 1,
      lessons.length,
    );
  }

  @override
  Future<bool> untouched(String id) async {
    final progress = await _progress.load();
    final each = progress.of(id);
    return !each.lessonDone &&
        each.parts.isEmpty &&
        each.stars.isEmpty &&
        progress.ongoing?.lessonId != id;
  }

  @override
  Future<LessonCheckpoint?> checkpoint() async =>
      (await _progress.load()).ongoing;

  @override
  Future<void> saveCheckpoint(LessonCheckpoint checkpoint) =>
      _writeCheckpoint(() async {
        final progress = await _progress.load();
        await _progress.save(progress.copyWith(ongoing: checkpoint));
      });

  @override
  Future<void> clearCheckpoint() => _writeCheckpoint(() async {
    final progress = await _progress.load();
    await _progress.save(progress.copyWith(clearOngoing: true));
  });

  @override
  Future<void> leave() => _writeCheckpoint(() async {
    final progress = await _progress.load();
    final ongoing = progress.ongoing;
    if (ongoing == null) return;
    await _progress.save(
      progress.copyWith(ongoing: ongoing.copyWith(open: false)),
    );
  });

  @override
  Future<LessonOutcome> complete(String id) async {
    await _checkpointWrites;
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

  @override
  Future<LessonOutcome> completePart(String id, String partId) async {
    await _checkpointWrites;
    final trail = await _lessons.trail();
    final lesson = trail.lesson(id);
    final progress = await _progress.load();
    if (lesson == null) return const LessonOutcome();
    final updated = EndgameLessonRules.completePart(
      lesson,
      progress.of(id),
      partId,
    );
    await _progress.save(
      progress.withLesson(id, updated).copyWith(clearOngoing: true),
    );
    return LessonOutcome(
      last: updated.lessonDone,
      nextPart: EndgameLessonRules.recommendedPart(lesson, updated)?.id,
      // A "Aula concluída" oferece a próxima aula da trilha.
      next: trail.after(id)?.id,
    );
  }
}
