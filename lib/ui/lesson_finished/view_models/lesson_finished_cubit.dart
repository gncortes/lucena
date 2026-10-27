import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/race/race_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/survey.dart';
import '../../../domain/use_cases/race_rules.dart';

class LessonFinishedState {
  const LessonFinishedState({
    this.ready = false,
    this.title = '',
    this.lessonId = '',
    this.nextId,
    this.nextTitle,
    this.practice,
    this.raceSubcategory,
    this.hasExercises = false,
  });

  final bool ready;

  /// O título da aula concluída.
  final String title;

  /// A aula concluída.
  final String lessonId;

  /// A próxima aula e o título dela; nulos na última.
  final String? nextId;
  final String? nextTitle;

  /// Aula de final: o final de verdade, o tipo de final dele na Corrida (nulo
  /// quando a Corrida não tem problemas dele) e se há o teste da aula.
  final Practice? practice;
  final String? raceSubcategory;
  final bool hasExercises;
}

/// A tela "Aula concluída": lê os títulos e, numa aula de final, o treino e o
/// tipo de final dele na Corrida (o bloco "E agora?"). A origem ([kind]) diz
/// de que curso é a aula: Escola ou aulas de finais.
class LessonFinishedCubit extends Cubit<LessonFinishedState> {
  LessonFinishedCubit({
    required this.kind,
    required this.lessonId,
    required this.nextId,
    required this.school,
    required this.endgames,
    required this.race,
    this.analytics = const NoAnalyticsRepository(),
  }) : super(const LessonFinishedState());

  final SurveyKind kind;
  final String lessonId;
  final String? nextId;
  final LessonRepository school;
  final EndgameLessonRepository endgames;
  final RaceRepository race;
  final AnalyticsRepository analytics;

  Future<void> load(String language) async {
    final LessonTexts texts = kind == SurveyKind.school
        ? await school.texts(language)
        : await endgames.texts(language);
    EndgameLesson? lesson;
    String? subcategory;
    if (kind == SurveyKind.endgames) {
      lesson = (await endgames.trail()).lesson(lessonId);
      if (lesson != null) {
        subcategory = RaceRules.subcategoryOf(
          await race.problems(),
          lesson.practice.fen,
        );
      }
    }
    if (isClosed) return;
    unawaited(
      analytics.log(
        AnalyticsEvents.aulaConcluida(
          aulaId: lessonId,
          tipoAula: kind == SurveyKind.school ? 'escola' : 'finais',
        ),
      ),
    );
    final next = nextId;
    emit(
      LessonFinishedState(
        ready: true,
        title: texts.lessonTitle(lessonId),
        lessonId: lessonId,
        nextId: next,
        nextTitle: next == null ? null : texts.lessonTitle(next),
        practice: lesson?.practice,
        raceSubcategory: subcategory,
        hasExercises: lesson?.exercises.isNotEmpty ?? false,
      ),
    );
  }
}
