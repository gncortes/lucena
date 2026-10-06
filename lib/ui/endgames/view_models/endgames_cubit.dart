import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../school/view_models/lesson_cubit.dart';

/// A situação de uma aula de final na trilha.
enum EndgameLessonStatus {
  /// Nada feito ainda.
  open,

  /// A lição foi feita ou há exercícios resolvidos, mas a nota não passou.
  started,

  /// Lição feita e nota mínima alcançada.
  passed,
}

class EndgamesState {
  const EndgamesState({
    this.ready = false,
    this.trail = EndgameTrail.empty,
    this.texts = LessonTexts.empty,
    this.progress = const EndgameProgress(),
    this.viktor,
  });

  final bool ready;
  final EndgameTrail trail;
  final LessonTexts texts;
  final EndgameProgress progress;
  final Character? viktor;

  /// A próxima aula a fazer. Nula com a trilha inteira passada.
  String? get next => EndgameLessonRules.next(trail, progress)?.id;

  int get total => trail.lessons.length;

  int get passed => trail.lessons
      .where((lesson) => status(lesson.id) == EndgameLessonStatus.passed)
      .length;

  EndgameLessonStatus status(String lessonId) {
    final lesson = trail.lesson(lessonId);
    if (lesson == null) return EndgameLessonStatus.open;
    final each = progress.of(lessonId);
    if (EndgameLessonRules.passed(lesson, each)) {
      return EndgameLessonStatus.passed;
    }
    if (each.lessonDone || each.stars.isNotEmpty) {
      return EndgameLessonStatus.started;
    }
    return EndgameLessonStatus.open;
  }

  /// A nota de uma aula, sobre o total de estrelas.
  (int, int) score(String lessonId) =>
      (progress.of(lessonId).score, trail.lesson(lessonId)?.maxScore ?? 0);
}

/// A trilha das aulas de finais: os módulos e as aulas, com o que já foi
/// feito. Toda aula fica aberta: a ordem é uma sugestão.
class EndgamesCubit extends Cubit<EndgamesState> {
  EndgamesCubit({
    required this._lessons,
    required this._progress,
    required this._characters,
  }) : super(const EndgamesState());

  final EndgameLessonRepository _lessons;
  final EndgameProgressRepository _progress;
  final CharacterRepository _characters;

  Future<void> load(String language) async {
    final trail = await _lessons.trail();
    final texts = await _lessons.texts(language);
    final progress = await _progress.load();
    final characters = await _characters.characters();
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == LessonCubit.viktorId) viktor = character;
    }
    emit(
      EndgamesState(
        ready: true,
        trail: trail,
        texts: texts,
        progress: progress,
        viktor: viktor,
      ),
    );
  }
}
