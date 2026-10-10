import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/home/unlock_repository.dart';
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
import '../../../domain/models/home_layout.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/home_suggestion.dart';
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
    this.layout,
    this.layoutNotice = false,
    this.unlockedBlind = false,
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

  /// Os caminhos em destaque e os de "Outros modos". Nulo enquanto lê.
  final HomeLayout? layout;

  /// O aviso único, para quem fez o tour antes de dar para escolher os
  /// caminhos: "Agora dá para escolher o que aparece aqui".
  final bool layoutNotice;

  /// O cartão "Novo modo desbloqueado: às cegas", depois do primeiro desafio
  /// às cegas vencido na Jornada. Aparece uma vez.
  final bool unlockedBlind;

  /// O caminho do cartão "Continuar": o da vez (a aula de final aberta, as
  /// aulas do iniciante ou a Jornada) se estiver em destaque; senão, o
  /// primeiro em destaque com progresso. Nulo: o cartão some.
  HomePath? get continuePath {
    final layout = this.layout;
    final current = endgame != null
        ? HomePath.endgames
        : school != null
        ? HomePath.learn
        : HomePath.journey;
    if (layout == null) return current;
    return HomeSuggestion.continuePath(
      layout,
      current: current,
      withProgress: {
        if (endgame != null) HomePath.endgames,
        if (school != null) HomePath.learn,
        HomePath.journey,
      },
    );
  }

  HomeState copyWith({bool? layoutNotice, bool? unlockedBlind}) => HomeState(
    ready: ready,
    tourPending: tourPending,
    current: current,
    next: next,
    character: character,
    rating: rating,
    school: school,
    endgame: endgame,
    nickname: nickname,
    level: level,
    ratingChange: ratingChange,
    layout: layout,
    layoutNotice: layoutNotice ?? this.layoutNotice,
    unlockedBlind: unlockedBlind ?? this.unlockedBlind,
  );
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
    this.exerciseFen,
    this.exerciseNumber,
    this.exerciseCount,
    this.lessonOpen = false,
    this.step,
    this.stepCount,
    this.partId,
    this.partNumber,
    this.partCount,
  });

  final String lessonId;

  /// Numa aula em partes: a parte em que o aluno parou (T51).
  final String? partId;
  final int? partNumber;
  final int? partCount;
  final String title;
  final int score;
  final int maxScore;
  final Character? teacher;

  /// O exercício da vez, com a posição dele na lista: o aberto quando o app
  /// fechou ou, com o teste começado, o próximo por resolver.
  final String? openExerciseId;

  /// A posição do exercício da vez, para a miniatura do cartão (que voa até
  /// o tabuleiro dele).
  final String? exerciseFen;
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
    this._homeLayout,
    this._unlocks,
  }) : super(const HomeState());

  final UnlockRepository? _unlocks;

  /// O modo às cegas, para o cartão de modo novo.
  static const blindMode = 'blind';

  // Os caminhos escolhidos. Nulo: sempre a sugestão do nível.
  final HomeLayoutRepository? _homeLayout;

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
    final fulfilled = await _progress.fulfilledChallenges();
    final progress = Mastery.of(
      await _journey.ladder(),
      fulfilled,
      startRung: onboarding.startRung,
    );
    // O primeiro especial às cegas vencido destrava o modo (o anúncio sai
    // uma vez só).
    final blindWon = progress.rungs.any(
      (rung) => rung.rung.specials.any(
        (special) =>
            special.mode == ChallengeMode.blind &&
            rung.specialsDone.contains(special.id),
      ),
    );
    final unlockedBlind =
        blindWon && _unlocks != null && !await _unlocks.seen(blindMode);
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
    final saved = await _homeLayout?.load();
    // Quem fez o tour antes de dar para escolher ganha o aviso, uma vez.
    final notice =
        _homeLayout != null &&
        onboarding.done &&
        saved == null &&
        !await _homeLayout.noticeSeen();
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
        layout: HomeSuggestion.resolve(saved, profile.level),
        layoutNotice: notice,
        unlockedBlind: unlockedBlind,
      ),
    );
  }

  /// O cartão do modo novo saiu (fechado ou tocado): não volta.
  Future<void> dismissUnlocked() async {
    emit(state.copyWith(unlockedBlind: false));
    await _unlocks?.markSeen(blindMode);
  }

  /// O aviso de que dá para escolher os caminhos saiu (fechado ou tocado):
  /// não volta.
  Future<void> dismissLayoutNotice() async {
    emit(state.copyWith(layoutNotice: false));
    await _homeLayout?.markNoticeSeen();
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
        final started =
            done.lessonDone || done.parts.isNotEmpty || done.stars.isNotEmpty;
        if (started && !EndgameLessonRules.passed(each, done)) {
          lesson = each;
          break;
        }
      }
    }
    if (lesson == null) return null;
    final texts = await _endgameLessons.texts(language);
    final done = progress.of(lesson.id);
    final lessonOpen =
        openExercise == null &&
        ongoing != null &&
        ongoing.lessonId == lesson.id &&
        !done.lessonDone;
    // O teste começado (um exercício resolvido ou aberto antes): o cartão
    // leva ao exercício da vez, não à tela da aula.
    final testStarted =
        done.lessonDone && (done.stars.isNotEmpty || done.exercise != null);
    final exercise = openExercise != null
        ? lesson.exercise(openExercise.$2.exerciseId)
        : !lessonOpen && testStarted
        ? EndgameLessonRules.nextExercise(lesson, done)
        : null;
    final exerciseIndex = exercise == null
        ? -1
        : lesson.exercises.indexOf(exercise);
    Character? teacher;
    for (final character in characters) {
      if (character.id == 'master') teacher = character;
    }
    // Numa aula em partes, o passo conta dentro da parte.
    final checkpoint = lessonOpen
        ? EndgameLessonRules.migrate(lesson, ongoing)
        : null;
    final part = lesson.lesson.parts.isEmpty || checkpoint?.part == null
        ? null
        : lesson.lesson.part(checkpoint!.part!);
    return EndgameSummary(
      lessonId: lesson.id,
      title: texts.lessonTitle(lesson.id),
      score: done.scoreOf(lesson),
      maxScore: lesson.maxScore,
      teacher: teacher,
      openExerciseId: exercise?.id,
      exerciseFen: exercise?.fen,
      exerciseNumber: exerciseIndex < 0 ? null : exerciseIndex + 1,
      exerciseCount: exerciseIndex < 0 ? null : lesson.exercises.length,
      lessonOpen: lessonOpen,
      step: !lessonOpen
          ? null
          : part != null
          ? checkpoint!.step + 1
          : ongoing.step + 1,
      stepCount: !lessonOpen
          ? null
          : part?.steps.length ?? lesson.lesson.steps.length,
      partId: part?.id,
      partNumber: part == null ? null : lesson.lesson.parts.indexOf(part) + 1,
      partCount: part == null ? null : lesson.lesson.parts.length,
    );
  }
}
