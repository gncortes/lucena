import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/mastery.dart';

/// O que a tela inicial mostra: onde o jogador está, contra quem joga e o
/// próximo passo.
class HomeState {
  const HomeState({
    this.ready = false,
    this.tourPending = false,
    this.current,
    this.next,
    this.character,
    this.rating,
    this.school,
    this.endgame,
    this.nickname = '',
    this.level,
    this.ratingChange,
  });

  final bool ready;

  /// A primeira abertura: o tour ainda não foi visto.
  final bool tourPending;

  /// O degrau atual. Nulo com a Jornada concluída.
  final RungProgress? current;

  /// O próximo desafio do degrau atual.
  final Challenge? next;

  /// O personagem do degrau atual (nulo no do Stockfish).
  final Character? character;
  final int? rating;

  /// O iniciante com aulas por fazer: a tela inicial leva primeiro a elas.
  final SchoolSummary? school;

  /// A aula de final em andamento: a tela inicial oferece continuar nela.
  final EndgameSummary? endgame;

  /// O apelido e a faixa do jogador.
  final String nickname;
  final RatingLevel? level;

  /// Quanto a última partida mudou o rating. Nulo sem duas partidas.
  final int? ratingChange;
}

/// As aulas do Viktor na tela inicial: quantas foram feitas e o professor.
class SchoolSummary {
  const SchoolSummary({
    required this.done,
    required this.total,
    required this.teacher,
    this.ongoingLessonId,
  });

  final int done;
  final int total;
  final Character? teacher;

  /// A lição começada e não terminada: "continuar" abre direto nela.
  final String? ongoingLessonId;
}

/// A aula de final em andamento na tela inicial: a que estava aberta (a
/// lição ou um exercício) ou a primeira começada e ainda não aprovada.
class EndgameSummary {
  const EndgameSummary({
    required this.lessonId,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.teacher,
    this.openExerciseId,
    this.exerciseNumber,
    this.exerciseCount,
    this.lessonOpen = false,
    this.step,
    this.stepCount,
  });

  final String lessonId;
  final String title;
  final int score;
  final int maxScore;
  final Character? teacher;

  /// O exercício aberto quando o app fechou, com a posição dele na lista.
  final String? openExerciseId;
  final int? exerciseNumber;
  final int? exerciseCount;

  /// A lição (os passos) começada e não terminada, e o passo em que parou.
  final bool lessonOpen;
  final int? step;
  final int? stepCount;
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this._journey,
    required this._progress,
    required this._onboarding,
    required this._characters,
    required this._rating,
    required this._lessons,
    required this._school,
    required this._profile,
    required this._endgameLessons,
    required this._endgameProgress,
  }) : super(const HomeState());

  final JourneyRepository _journey;
  final ProgressRepository _progress;
  final OnboardingRepository _onboarding;
  final CharacterRepository _characters;
  final RatingRepository _rating;
  final LessonRepository _lessons;
  final SchoolProgressRepository _school;
  final ProfileRepository _profile;
  final EndgameLessonRepository _endgameLessons;
  final EndgameProgressRepository _endgameProgress;

  /// [language] escolhe as falas das aulas de finais (o título da aula).
  Future<void> load([String language = 'en']) async {
    final onboarding = await _onboarding.load();
    final progress = Mastery.of(
      await _journey.ladder(),
      await _progress.fulfilledChallenges(),
      startRung: onboarding.startRung,
    );
    final current = progress.current;
    Challenge? next;
    for (final challenge in current?.rung.challenges ?? const <Challenge>[]) {
      if (!current!.completed.contains(challenge.id)) {
        next = challenge;
        break;
      }
    }
    final characters = await _characters.characters();
    final rating = await _rating.current();
    final history = await _rating.history();
    final school = await _schoolSummary(characters);
    final profile = await _profile.load();
    final endgame = await _endgameSummary(language, characters);
    if (isClosed) return;
    emit(
      HomeState(
        ready: true,
        tourPending: !onboarding.done,
        current: current,
        next: next,
        // O do Stockfish é o logo dele.
        character: current?.rung.opponent.kind == OpponentKind.stockfish
            ? Character.stockfish
            : characters.forLevel(current?.rung.opponent.level),
        rating: rating.rounded,
        school: school,
        endgame: endgame,
        nickname: profile.nickname,
        level: profile.level,
        ratingChange: history.length < 2
            ? null
            : history.last.rating.rounded -
                  history[history.length - 2].rating.rounded,
      ),
    );
  }

  /// Para quem marcou "iniciante" e ainda não se formou, ou para quem tem
  /// uma lição começada (qualquer perfil): o cartão leva direto a ela.
  Future<SchoolSummary?> _schoolSummary(List<Character> characters) async {
    final profile = await _profile.load();
    final progress = await _school.load();
    final ongoing = progress.ongoing;
    if (profile.level != RatingLevel.beginner && ongoing == null) return null;
    final lessons = (await _lessons.course()).lessons;
    final completed = progress.completed;
    final done = lessons.where((lesson) => completed.contains(lesson.id));
    if (lessons.isEmpty || done.length == lessons.length) return null;
    Character? teacher;
    for (final character in characters) {
      if (character.id == 'master') teacher = character;
    }
    return SchoolSummary(
      done: done.length,
      total: lessons.length,
      teacher: teacher,
      ongoingLessonId: ongoing?.lessonId,
    );
  }

  Future<EndgameSummary?> _endgameSummary(
    String language,
    List<Character> characters,
  ) async {
    final progress = await _endgameProgress.load();
    final trail = await _endgameLessons.trail();
    final openExercise = progress.openExercise;
    final ongoing = progress.ongoing;
    EndgameLesson? lesson;
    if (openExercise != null) {
      lesson = trail.lesson(openExercise.$1);
    } else if (ongoing != null) {
      // A lição começada e não terminada, aberta ou não (como o botão
      // "continuar" da tela da aula).
      lesson = trail.lesson(ongoing.lessonId);
    } else {
      for (final each in trail.lessons) {
        final done = progress.of(each.id);
        final started = done.lessonDone || done.stars.isNotEmpty;
        if (started && !EndgameLessonRules.passed(each, done)) {
          lesson = each;
          break;
        }
      }
    }
    if (lesson == null) return null;
    final texts = await _endgameLessons.texts(language);
    final done = progress.of(lesson.id);
    final exerciseIndex = openExercise == null
        ? -1
        : lesson.exercises.indexWhere(
            (each) => each.id == openExercise.$2.exerciseId,
          );
    final lessonOpen =
        openExercise == null &&
        ongoing != null &&
        ongoing.lessonId == lesson.id &&
        !done.lessonDone;
    Character? teacher;
    for (final character in characters) {
      if (character.id == 'master') teacher = character;
    }
    return EndgameSummary(
      lessonId: lesson.id,
      title: texts.lessonTitle(lesson.id),
      score: done.score,
      maxScore: lesson.maxScore,
      teacher: teacher,
      openExerciseId: exerciseIndex < 0 ? null : openExercise!.$2.exerciseId,
      exerciseNumber: exerciseIndex < 0 ? null : exerciseIndex + 1,
      exerciseCount: exerciseIndex < 0 ? null : lesson.exercises.length,
      lessonOpen: lessonOpen,
      step: lessonOpen ? ongoing.step + 1 : null,
      stepCount: lessonOpen ? lesson.lesson.steps.length : null,
    );
  }
}
