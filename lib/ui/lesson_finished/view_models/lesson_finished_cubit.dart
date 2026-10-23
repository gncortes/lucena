import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/survey.dart';

class LessonFinishedState {
  const LessonFinishedState({
    this.ready = false,
    this.title = '',
    this.nextId,
    this.nextTitle,
  });

  final bool ready;

  /// O título da aula concluída.
  final String title;

  /// A próxima aula e o título dela; nulos na última.
  final String? nextId;
  final String? nextTitle;
}

/// A tela "Aula concluída": só lê os títulos. A origem ([kind]) diz de que
/// curso é a aula: Escola ou aulas de finais.
class LessonFinishedCubit extends Cubit<LessonFinishedState> {
  LessonFinishedCubit({
    required this.kind,
    required this.lessonId,
    required this.nextId,
    required this.school,
    required this.endgames,
  }) : super(const LessonFinishedState());

  final SurveyKind kind;
  final String lessonId;
  final String? nextId;
  final LessonRepository school;
  final EndgameLessonRepository endgames;

  Future<void> load(String language) async {
    final LessonTexts texts = kind == SurveyKind.school
        ? await school.texts(language)
        : await endgames.texts(language);
    if (isClosed) return;
    final next = nextId;
    emit(
      LessonFinishedState(
        ready: true,
        title: texts.lessonTitle(lessonId),
        nextId: next,
        nextTitle: next == null ? null : texts.lessonTitle(next),
      ),
    );
  }
}
