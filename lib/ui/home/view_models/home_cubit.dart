import 'dart:async';

import 'package:dartchess/dartchess.dart' show Move, Side;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/lesson_content.dart';
import '../../../data/repositories/training/course_training_repository.dart'
    as course_training;
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/use_cases/training/play_training_opening.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';
import '../../../domain/use_cases/training/build_day_goals.dart';
import '../../../domain/use_cases/training/home_course_card.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../data/repositories/featured/featured_repository.dart';
import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/home/unlock_repository.dart';
import '../../../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/placement/placement_repository.dart';
import '../../../data/repositories/positions/positions_repository.dart';
import '../../placement/view_models/roadmap_loader.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/goal_preference.dart';
import '../../../domain/models/home_layout.dart';
import '../../../domain/models/home_shortcut.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/models/streak.dart';
import '../../../domain/use_cases/beginner_home.dart';
import '../../../domain/use_cases/course_availability.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/featured_rules.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/home_shortcuts.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/home_suggestion.dart';
import '../../../domain/use_cases/mastery.dart';
import '../../../domain/use_cases/streak_rules.dart';
import '../../../domain/use_cases/train_suggestion.dart';

/// O que a tela inicial mostra: onde o jogador está, contra quem joga e o
/// próximo passo.
class HomeState {
  const HomeState({
    this.ready = false,
    this.tourPending = false,
    this.boardControlsDone = false,
    this.stage = OnboardingStage.tour,
    this.current,
    this.next,
    this.character,
    this.teacher,
    this.rating,
    this.school,
    this.endgame,
    this.nickname = '',
    this.level,
    this.ratingChange,
    this.layout,
    this.unlockedBlind = false,
    this.featured,
    this.goal,
    this.courseDone = false,
    this.journeySaved = false,
    this.trainGoal,
    this.journeyStarted = false,
    this.streak = Streak.none,
    this.courseAvailable = true,
    this.placementDone = true,
    this.ratedGames = 0,
    this.training,
  });

  final bool ready;

  /// A primeira abertura: o tour ainda não foi visto.
  final bool tourPending;
  final bool boardControlsDone;

  /// Com [tourPending], a tela da primeira abertura em que a pessoa parou.
  final OnboardingStage stage;

  /// O degrau atual. Nulo com a Jornada concluída.
  final RungProgress? current;

  /// O próximo desafio do degrau atual.
  final Challenge? next;

  /// O personagem do degrau atual (nulo no do Stockfish).
  final Character? character;

  /// O Viktor, no cartão do Curso de finais concluído.
  final Character? teacher;
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

  /// A ordem dos caminhos, que ordena os atalhos. Nulo enquanto lê.
  final HomeLayout? layout;

  /// O cartão "Novo modo desbloqueado: às cegas", depois do primeiro desafio
  /// às cegas vencido na Jornada. Aparece uma vez.
  final bool unlockedBlind;

  /// O final em destaque da seção "Finais em destaque". Nulo: a seção some.
  final FeaturedItem? featured;

  /// O objetivo do perfil (E1.11). Nulo: quem usava o app antes da pergunta
  /// (a tela fica como era).
  final GoalPreference? goal;

  /// Todas as aulas de final liberadas aprovadas: o cartão de "Aprender
  /// finais" vira "Curso concluído".
  final bool courseDone;

  /// A partida do desafio da vez ([next]) está salva: o botão é "Retomar".
  final bool journeySaved;

  /// O final sugerido pelo nível, para o cartão de "Treinar finais" (e para
  /// onde ele cai quando o caminho do objetivo acabou).
  final TrainGoal? trainGoal;

  /// Algum desafio da Jornada já cumprido.
  final bool journeyStarted;

  /// A sequência de dias; com [Streak.lost], a folha da sequência perdida
  /// sai uma vez.
  final Streak streak;

  /// Há aula de final liberada. Falso: o Curso de finais e os finais para
  /// você não aparecem (T83 B1).
  final bool courseAvailable;

  /// A pessoa fez o teste de nível (T83 B4).
  final bool placementDone;

  /// As partidas que mexeram no rating (sem os bônus de speedrun).
  final int ratedGames;
  final HomeTraining? training;

  /// O número do rating aparece (T83 B3).
  bool get showsRating => BeginnerHome.showsRating(goal, ratedGames);

  /// "Finais em destaque" (o final do dia e o destaque) aparece (T83 B3).
  bool get showsFeatured => BeginnerHome.showsFeatured(goal, journeyStarted);

  /// O que o cartão azul de cima mostra (T83, os 20 estados da prancha
  /// "card-estados"). Nulo: nenhum cartão.
  HomeHero? get hero {
    if (!ready) return null;
    if (training != null) return HomeHero.course;
    final goal = this.goal;
    if (goal == GoalPreference.learn && !boardControlsDone) {
      return HomeHero.firstSteps;
    }
    if (goal == null) {
      // Sem objetivo: a aula de final em andamento (ou recomendada), as
      // aulas do iniciante ou a Jornada.
      if (endgame != null) return HomeHero.endgame;
      if (school != null) return HomeHero.school;
      return _journeyOr(HomeHero.speedrun);
    }
    return switch (HomeSuggestion.goalPath(goal, course: courseAvailable)) {
      HomePath.learn when school != null => HomeHero.school,
      HomePath.endgames when endgame != null => HomeHero.endgame,
      HomePath.endgames when courseDone => HomeHero.courseDone,
      HomePath.endgames ||
      HomePath.train => trainGoal != null ? HomeHero.train : HomeHero.speedrun,
      _ => _journeyOr(trainGoal != null ? HomeHero.train : HomeHero.speedrun),
    };
  }

  HomeHero _journeyOr(HomeHero done) =>
      current != null && next != null ? HomeHero.journey : done;

  /// Os atalhos da grade: todos os caminhos marcados, na ordem do nível.
  List<HomeShortcut> get shortcuts {
    final shown = layout ?? HomeSuggestion.of(level ?? RatingLevel.casual);
    return HomeShortcuts.of(
      order: shown.order,
      visible: shown.visible,
      learning: goal == GoalPreference.learn,
    );
  }

  HomeState copyWith({bool? unlockedBlind, Streak? streak}) => HomeState(
    ready: ready,
    tourPending: tourPending,
    boardControlsDone: boardControlsDone,
    stage: stage,
    current: current,
    next: next,
    character: character,
    teacher: teacher,
    rating: rating,
    school: school,
    endgame: endgame,
    nickname: nickname,
    level: level,
    ratingChange: ratingChange,
    layout: layout,
    unlockedBlind: unlockedBlind ?? this.unlockedBlind,
    featured: featured,
    goal: goal,
    courseDone: courseDone,
    journeySaved: journeySaved,
    trainGoal: trainGoal,
    journeyStarted: journeyStarted,
    streak: streak ?? this.streak,
    courseAvailable: courseAvailable,
    placementDone: placementDone,
    ratedGames: ratedGames,
    training: training,
  );
}

/// O cartão azul de cima da tela inicial: um lugar do app por vez.
enum HomeHero {
  course(HomePath.learn),

  /// Como mover as peças, antes da primeira partida de quem aprende a jogar.
  firstSteps(HomePath.journey),

  /// A lição da vez na Escola.
  school(HomePath.learn),

  /// O adversário atual da Jornada.
  journey(HomePath.journey),

  /// A aula de final em andamento ou a recomendada.
  endgame(HomePath.endgames),

  /// O Curso de finais todo aprovado: o botão leva ao treino.
  courseDone(HomePath.train),

  /// O final sugerido pelo nível.
  train(HomePath.train),

  /// Nada por fazer nos outros: o speedrun.
  speedrun(HomePath.speedrun);

  const HomeHero(this.path);

  /// O caminho que o cartão já mostra (sai dos atalhos).
  final HomePath path;
}

final class HomeTraining {
  const HomeTraining({
    required this.config,
    required this.state,
    required this.resources,
    required this.card,
    this.lessonPreview,
  });
  final TrainingCourseConfig config;
  final TrainingState state;
  final TrainingResources resources;
  final HomeCourseCard card;
  final LessonScriptState? lessonPreview;
  TrainingExercise? get exercise => resources.banks[card.ref]
      ?.where((e) => e.id == card.goal?.itemId)
      .firstOrNull;
  OpeningTrecho? get opening => resources.openings[card.ref]
      ?.where((e) => e.id == card.goal?.items[card.ref])
      .firstOrNull;
  PlayTrainingOpening? get openingLine =>
      opening == null ? null : PlayTrainingOpening(opening!);

  String? get fen {
    if (card.destination == HomeCourseDestination.lessonTab) return null;
    final line = openingLine;
    return exercise?.fen ??
        (line == null ? lessonPreview?.fen : line.fens[line.initialCursor]);
  }

  Side get orientation => opening != null
      ? (opening!.black ? Side.black : Side.white)
      : lessonPreview?.orientation ??
            (fen?.split(' ')[1] == 'b' ? Side.black : Side.white);
}

/// O final sugerido pelo nível e a primeira posição dele por cumprir (a
/// miniatura).
class TrainGoal {
  const TrainGoal({required this.suggestion, this.fen});

  final TrainSuggestion suggestion;
  final String? fen;
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
    this.partId,
    this.partStage = 0,
    this.partNumber,
    this.partCount,
    this.recommended = false,
    this.progress = 0,
    this.fen,
  });

  final String lessonId;

  /// Quanto do capítulo está feito: as partes da lição e os exercícios
  /// resolvidos, de 0 a 1.
  final double progress;

  /// A miniatura do cartão: o exercício da vez ou, sem ele, a posição-chave
  /// da aula.
  final String? fen;

  /// Próximo final do roteiro, ainda sem aula/exercício em andamento.
  final bool recommended;

  /// Numa aula em partes: a parte em que o aluno parou (T51).
  final String? partId;

  /// A etapa da parte em que o aluno saiu: o "Continuar" volta nela.
  final int partStage;
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

  /// A lição (os passos) começada e não terminada. O passo não aparece:
  /// fechar o app reabre no início da parte (ou da lição, sem partes).
  final bool lessonOpen;
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
    this._placement,
    this._featured,
    this._featuredProgress,
    this._now,
    this._positions,
    this._activity,
    this._games,
    this._analytics = const NoAnalyticsRepository(),
    this._courseTraining,
    this._trainingCourses = const [],
    this.trainingLessonPreview,
  }) : super(const HomeState());

  final AnalyticsRepository _analytics;
  final course_training.TrainingRepository? _courseTraining;
  final List<TrainingCourseConfig> _trainingCourses;

  /// Reads the same resolved script/checkpoint as the lesson destination.
  /// Absent content leaves the preview empty rather than inventing a FEN.
  final Future<LessonScriptState?> Function(TrainingLesson)?
  trainingLessonPreview;

  // A sequência de dias: sem ela (ou sem o relógio), a folha não sai.
  final ActivityRepository? _activity;

  // A partida salva, para o "Retomar" da Jornada.
  final OngoingGameRepository? _games;

  // O catálogo de posições, para o cartão de "Treinar finais".
  final PositionsRepository? _positions;

  // Os finais em destaque: sem eles (ou sem o relógio), a seção não aparece.
  final FeaturedRepository? _featured;
  final FeaturedProgressRepository? _featuredProgress;
  final Now? _now;

  final UnlockRepository? _unlocks;
  final PlacementRepository? _placement;

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
    final school = await _optionalContent(() => _schoolSummary(characters));
    final profile = await _profile.load();
    final saved = await _homeLayout?.load();
    final goal = profile.goal;
    final courseAvailable = await CourseAvailability(_endgameLessons.trail)();
    final layout = HomeSuggestion.resolve(
      saved,
      profile.level,
      goal: goal,
      course: courseAvailable,
    );
    final priority = layout.shown.firstOrNull;
    final goalPath = goal == null
        ? null
        : HomeSuggestion.goalPath(goal, course: courseAvailable);
    final endgame = await _optionalContent(
      () => _endgameSummary(
        language,
        characters,
        recommend:
            goalPath == HomePath.endgames ||
            (goal == null &&
                (priority == HomePath.endgames || priority == HomePath.forYou)),
        firstUnpassed: goalPath == HomePath.endgames,
      ),
    );
    final courseDone =
        goalPath == HomePath.endgames &&
        endgame == null &&
        (await _optionalContent(_courseDone) ?? false);
    // O treino é o cartão de "Treinar finais" e para onde os outros caem
    // quando acabam (a Jornada vencida, o curso concluído).
    final trainGoal =
        goalPath == HomePath.train ||
            (goalPath == HomePath.endgames && endgame == null) ||
            (goal != null && current == null)
        ? await _trainGoal(profile.level, rating.rounded)
        : null;
    final journeySaved = next != null && await _journeySaved(next);
    final featured = await _featuredItem();
    final streak = await _streak();
    final placementDone =
        _placement == null || await _placement.result() != null;
    final training = await _optionalContent(_trainingSummary);
    if (isClosed) return;
    emit(
      HomeState(
        ready: true,
        tourPending: !onboarding.done,
        boardControlsDone: onboarding.boardControlsDone,
        stage: onboarding.stage,
        current: current,
        next: next,
        // O do Stockfish é o logo dele.
        character: current?.rung.opponent.kind == OpponentKind.stockfish
            ? Character.stockfish
            : characters.forLevel(current?.rung.opponent.level),
        teacher: characters.where((each) => each.id == 'master').firstOrNull,
        rating: rating.rounded,
        school: school,
        endgame: endgame,
        nickname: profile.nickname,
        level: profile.level,
        ratingChange: history.length < 2
            ? null
            : history.last.rating.rounded -
                  history[history.length - 2].rating.rounded,
        layout: layout,
        unlockedBlind: unlockedBlind,
        featured: featured,
        goal: goal,
        courseDone: courseDone,
        journeySaved: journeySaved,
        trainGoal: trainGoal,
        journeyStarted: fulfilled.isNotEmpty,
        streak: streak,
        courseAvailable: courseAvailable,
        placementDone: placementDone,
        ratedGames: history.where((entry) => !entry.isBonus).length,
        training: training,
      ),
    );
  }

  Future<HomeTraining?> _trainingSummary() async {
    final repository = _courseTraining;
    final now = _now;
    if (repository == null || now == null) return null;
    final active =
        <
          ({
            TrainingCourseConfig config,
            TrainingState state,
            TrainingResources resources,
          })
        >[];
    for (final config in _trainingCourses) {
      final before = await repository.load(config.course);
      if (!before.onboardingDone) continue;
      final resources = await repository.resources(config.course);
      final state = await repository.update(
        config.course,
        (s) => BuildDayGoals(now, config)(s, resources),
      );
      active.add((config: config, state: state, resources: resources));
    }
    final latest = latestTrainingCourse(active.map((e) => e.state));
    if (latest == null) return null;
    final selected = active.firstWhere((e) => e.state.course == latest.course);
    final card = homeCourseCard(selected.state, selected.resources);
    final lesson = selected.resources.lessons
        .where((l) => l.id == card?.ref)
        .firstOrNull;
    final preview =
        card?.destination == HomeCourseDestination.lesson && lesson != null
        ? await _optionalContent(
            () async => trainingLessonPreview?.call(lesson),
          )
        : null;
    return card == null
        ? null
        : HomeTraining(
            config: selected.config,
            state: selected.state,
            resources: selected.resources,
            card: card,
            lessonPreview: preview,
          );
  }

  /// A sequência de hoje. [Streak.lost] só fica quando a folha da sequência
  /// perdida ainda não saiu e a que acabou tinha pelo menos dois dias.
  Future<Streak> _streak() async {
    final activity = _activity;
    final now = _now;
    if (activity == null || now == null) return Streak.none;
    final at = now();
    final streak = StreakRules.of(await activity.days(), at);
    final pending =
        streak.lost >= 2 &&
        await activity.lostPending(StreakRules.lostLastDay(at));
    return pending ? streak : streak.withoutLost;
  }

  /// A folha da sequência perdida de [lost] foi respondida: [played] se foi
  /// jogar o final de hoje, senão "Agora não".
  void lostAnswered(Streak lost, {required bool played}) => unawaited(
    _analytics.log(
      AnalyticsEvents.sequenciaPerdida(
        tamanho: lost.lost,
        recorde: lost.record,
        acao: played ? 'jogou_hoje' : 'agora_nao',
      ),
    ),
  );

  /// A folha da sequência perdida saiu: não volta.
  Future<void> lostShown() async {
    final now = _now;
    if (now == null) return;
    emit(state.copyWith(streak: state.streak.withoutLost));
    await _activity?.markLostShown(StreakRules.lostLastDay(now()));
  }

  /// Todas as aulas de final liberadas já foram aprovadas.
  Future<bool> _courseDone() async {
    final lessons = (await _endgameLessons.trail()).lessons;
    final progress = await _endgameProgress.load();
    return lessons.isNotEmpty &&
        lessons.every(
          (lesson) => EndgameLessonRules.passed(lesson, progress.of(lesson.id)),
        );
  }

  /// A partida de [challenge] ficou salva no meio (a mesma regra da tela do
  /// desafio): o cartão oferece retomá-la.
  Future<bool> _journeySaved(Challenge challenge) async {
    final snapshot = await _games?.load();
    if (snapshot == null) return false;
    if (snapshot.moves.isEmpty && snapshot.clock == null) return false;
    final mode = snapshot.mode;
    if (mode.challengeId != challenge.id ||
        mode.isSpeedrun ||
        mode.fromLink ||
        snapshot.startFen != challenge.position.fen ||
        mode.positionId != challenge.position.id ||
        mode.opponent != challenge.opponent.kind ||
        mode.level != challenge.opponent.level ||
        mode.goal != challenge.goal) {
      return false;
    }
    var position = GameRules.fromFen(snapshot.startFen);
    for (final uci in snapshot.moves) {
      final move = Move.parse(uci);
      if (position == null || move == null) return false;
      position = GameRules.play(position, move)?.position;
    }
    return position != null && GameRules.endOf(position) == null;
  }

  /// O final sugerido pelo nível e a primeira posição dele por cumprir.
  Future<TrainGoal?> _trainGoal(RatingLevel level, int rating) async {
    final positions = _positions;
    if (positions == null) return null;
    final fulfilled = await _progress.fulfilledPositions();
    final suggestion = TrainSuggestion.of(
      level,
      await positions.catalog(),
      fulfilled,
      rating: rating,
    );
    if (suggestion == null) return null;
    final list = await positions.bySubcategory(suggestion.subcategory.key);
    return TrainGoal(
      suggestion: suggestion,
      fen: list
          .where((position) => !fulfilled.contains(position.id))
          .firstOrNull
          ?.fen,
    );
  }

  /// O final da seção "Finais em destaque": o primeiro da lista.
  Future<FeaturedItem?> _featuredItem() async {
    final repository = _featured;
    final progress = _featuredProgress;
    final now = _now;
    if (repository == null || progress == null || now == null) return null;
    final catalog = await repository.catalog();
    final played = await progress.played();
    return FeaturedRules.home(FeaturedRules.items(catalog, played, now: now()));
  }

  /// O cartão do modo novo saiu (fechado ou tocado): não volta.
  Future<void> dismissUnlocked() async {
    emit(state.copyWith(unlockedBlind: false));
    await _unlocks?.markSeen(blindMode);
  }

  Future<T?> _optionalContent<T>(Future<T> Function() read) async {
    try {
      return await read();
    } on LessonContentUnavailable {
      return null;
    }
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
    List<Character> characters, {
    required bool recommend,
    bool firstUnpassed = false,
  }) async {
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
    var recommended = false;
    final placement = _placement;
    if (lesson == null && recommend && placement != null) {
      final roadmap = await RoadmapLoader(
        placement: placement,
        school: _lessons,
        schoolProgress: _school,
        endgames: _endgameLessons,
        endgameProgress: _endgameProgress,
      ).load();
      final next = roadmap?.steps.where((step) => !step.school).firstOrNull;
      if (next != null) {
        lesson = trail.lesson(next.lessonId);
        recommended = lesson != null;
      }
    }
    // O objetivo "Aprender finais" sem roteiro: a primeira aula por passar.
    if (lesson == null && firstUnpassed) {
      for (final each in trail.lessons) {
        if (!EndgameLessonRules.passed(each, progress.of(each.id))) {
          lesson = each;
          recommended = true;
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
    final testStarted = done.stars.isNotEmpty || done.exercise != null;
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
    // Numa aula em partes, o cartão mostra a parte; sem partes, a nota.
    final checkpoint = lessonOpen
        ? EndgameLessonRules.migrate(lesson, ongoing)
        : null;
    final part = lesson.lesson.parts.isEmpty || checkpoint?.part == null
        ? null
        : lesson.lesson.part(checkpoint!.part!);
    final steps = lesson.lesson.sections.length + lesson.exercises.length;
    return EndgameSummary(
      lessonId: lesson.id,
      progress: steps == 0
          ? 0
          : (done.partsDone(lesson).length + done.solvedOf(lesson)) / steps,
      fen:
          exercise?.fen ??
          lesson.keyPositions.firstOrNull?.fen ??
          lesson.practice?.fen,
      recommended: recommended,
      title: texts.lessonTitle(lesson.id),
      score: done.scoreOf(lesson),
      maxScore: lesson.maxScore,
      teacher: teacher,
      openExerciseId: exercise?.id,
      exerciseFen: exercise?.fen,
      exerciseNumber: exerciseIndex < 0 ? null : exerciseIndex + 1,
      exerciseCount: exerciseIndex < 0 ? null : lesson.exercises.length,
      lessonOpen: lessonOpen,
      partId: part?.id,
      partStage: part == null ? 0 : checkpoint!.step,
      partNumber: part == null ? null : lesson.lesson.parts.indexOf(part) + 1,
      partCount: part == null ? null : lesson.lesson.parts.length,
    );
  }
}
