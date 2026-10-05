import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/rating_level.dart';
import 'lesson_cubit.dart';

/// A situação de uma aula na trilha.
enum LessonStatus { locked, open, completed }

class SchoolState {
  const SchoolState({
    this.ready = false,
    this.course = const Course(modules: []),
    this.texts = LessonTexts.empty,
    this.completed = const {},
    this.openAll = false,
    this.ongoing,
    this.viktor,
  });

  final bool ready;
  final Course course;
  final LessonTexts texts;
  final Set<String> completed;

  /// Quem não marcou "iniciante" pode abrir qualquer aula.
  final bool openAll;

  /// A aula começada e não terminada.
  final String? ongoing;
  final Character? viktor;

  /// A próxima aula a fazer: a começada ou a primeira não concluída. Nula
  /// com o curso inteiro concluído.
  String? get next {
    if (ongoing != null) return ongoing;
    for (final lesson in course.lessons) {
      if (!completed.contains(lesson.id)) return lesson.id;
    }
    return null;
  }

  bool get graduated =>
      course.lessons.isNotEmpty &&
      course.lessons.every((lesson) => completed.contains(lesson.id));

  /// Quantas aulas há e quantas foram concluídas.
  int get total => course.lessons.length;
  int get done =>
      course.lessons.where((lesson) => completed.contains(lesson.id)).length;

  LessonStatus status(String lessonId) {
    if (completed.contains(lessonId)) return LessonStatus.completed;
    if (openAll) return LessonStatus.open;
    final lessons = course.lessons;
    final index = lessons.indexWhere((lesson) => lesson.id == lessonId);
    if (index <= 0) return LessonStatus.open;
    return completed.contains(lessons[index - 1].id)
        ? LessonStatus.open
        : LessonStatus.locked;
  }

  /// A aula que falta concluir para liberar [lessonId].
  String? blockedBy(String lessonId) {
    final lessons = course.lessons;
    final index = lessons.indexWhere((lesson) => lesson.id == lessonId);
    return index > 0 ? lessons[index - 1].id : null;
  }
}

/// A trilha da Escola do Viktor: os módulos e as aulas, com o que já foi
/// feito.
class SchoolCubit extends Cubit<SchoolState> {
  SchoolCubit({
    required this._lessons,
    required this._progress,
    required this._characters,
    required this._profile,
  }) : super(const SchoolState());

  final LessonRepository _lessons;
  final SchoolProgressRepository _progress;
  final CharacterRepository _characters;
  final ProfileRepository _profile;

  Future<void> load(String language) async {
    final course = await _lessons.course();
    final texts = await _lessons.texts(language);
    final progress = await _progress.load();
    final profile = await _profile.load();
    final characters = await _characters.characters();
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == LessonCubit.viktorId) viktor = character;
    }
    emit(
      SchoolState(
        ready: true,
        course: course,
        texts: texts,
        completed: progress.completed,
        openAll: profile.level != RatingLevel.beginner,
        ongoing: progress.ongoing?.lessonId,
        viktor: viktor,
      ),
    );
  }
}
