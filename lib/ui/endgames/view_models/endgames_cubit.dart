import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/placement/placement_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_filter.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/lesson_content.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/endgame_lesson_filter.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/placement_roadmap.dart';
import '../../placement/view_models/roadmap_loader.dart';

export '../../../domain/models/endgame_filter.dart';

class EndgamesState {
  const EndgamesState({
    this.ready = false,
    this.trail = EndgameTrail.empty,
    this.texts = LessonTexts.empty,
    this.progress = const EndgameProgress(),
    this.viktor,
    this.roadmap,
    this.showAll = false,
    this.hideDone = false,
    this.filter = const EndgameFilter(),
    this.levels = const {},
  });

  /// Os filtros e a ordem da lista da trilha (gravados).
  final EndgameFilter filter;

  /// A faixa de cada aula, pelo mapa de habilidades. Vazio sem o mapa.
  final Map<String, RatingLevel> levels;

  /// A faixa de uma aula. Nula se nenhum nó a liga.
  RatingLevel? level(String lessonId) => levels[lessonId];

  /// Os tipos de final de uma aula.
  Set<EndgameKind> kinds(EndgameLesson lesson) =>
      EndgameLessonFilter.kinds(lesson);

  /// Os tipos que têm ao menos uma aula, na ordem do enum.
  List<EndgameKind> get availableKinds {
    final found = {for (final lesson in trail.lessons) ...kinds(lesson)};
    return [
      for (final kind in EndgameKind.values)
        if (found.contains(kind)) kind,
    ];
  }

  /// As faixas que têm ao menos uma aula, da mais fácil à mais difícil.
  List<RatingLevel> get availableLevels {
    final found = {for (final lesson in trail.lessons) ?levels[lesson.id]};
    return [
      for (final level in RatingLevel.values)
        if (found.contains(level)) level,
    ];
  }

  /// Se a aula passa pelos filtros.
  bool shows(EndgameLesson lesson) => filter.matches(
    kinds: kinds(lesson),
    level: levels[lesson.id],
    status: status(lesson.id),
  );

  /// As aulas que passam pelos filtros, na ordem da trilha.
  List<EndgameLesson> get filteredLessons => [
    for (final lesson in trail.lessons)
      if (shows(lesson)) lesson,
  ];

  /// A lista da trilha, já filtrada, em seções: por módulo (na ordem da
  /// trilha) ou por faixa (das mais fáceis às mais difíceis). Seções vazias
  /// ficam de fora; aulas sem faixa vão para o fim, numa seção sem faixa.
  List<EndgameSection> get sections {
    if (filter.sort == EndgameSort.easiest) {
      final byLevel = <RatingLevel?, List<EndgameLesson>>{};
      for (final lesson in filteredLessons) {
        byLevel.putIfAbsent(levels[lesson.id], () => []).add(lesson);
      }
      return [
        for (final level in [...RatingLevel.values, null])
          if (byLevel[level] case final lessons?)
            EndgameSection(level: level, lessons: lessons),
      ];
    }
    return [
      for (final (index, module) in trail.modules.indexed)
        if (module.lessons.where(shows).toList() case final lessons
            when lessons.isNotEmpty)
          EndgameSection(module: module, number: index + 1, lessons: lessons),
    ];
  }

  EndgamesState copyWith({
    bool? showAll,
    bool? hideDone,
    EndgameFilter? filter,
  }) => EndgamesState(
    ready: ready,
    trail: trail,
    texts: texts,
    progress: progress,
    viktor: viktor,
    roadmap: roadmap,
    showAll: showAll ?? this.showAll,
    hideDone: hideDone ?? this.hideDone,
    filter: filter ?? this.filter,
    levels: levels,
  );

  /// "Para você": esconde as aulas já concluídas.
  final bool hideDone;

  /// As aulas concluídas, na ordem da trilha.
  List<EndgameLesson> get doneLessons => [
    for (final lesson in trail.lessons)
      if (status(lesson.id) == EndgameLessonStatus.passed) lesson,
  ];

  /// "Todos": a trilha inteira, em vez do roteiro. Sem teste feito, a
  /// trilha aparece sempre inteira.
  final bool showAll;

  /// A lista mostra só o roteiro ("Para você").
  bool get forYou => tested && !showAll;

  /// O roteiro do teste de nível (T52). Nulo sem teste feito.
  final PlacementRoadmap? roadmap;

  bool get tested => roadmap != null;

  /// O selo de uma aula pelo roteiro (nulo: sem selo).
  EndgameBadge? badge(String lessonId) => roadmap?.endgameBadges[lessonId];

  final bool ready;
  final EndgameTrail trail;
  final LessonTexts texts;
  final EndgameProgress progress;
  final Character? viktor;

  /// A próxima aula a fazer. Nula com a trilha inteira passada.
  /// Com o teste feito, o próximo passo do roteiro (se a aula existe e não
  /// foi passada).
  String? get next {
    final placed = roadmap?.nextEndgame;
    if (placed != null &&
        status(placed.lessonId) != EndgameLessonStatus.passed) {
      return placed.lessonId;
    }
    return EndgameLessonRules.next(trail, progress)?.id;
  }

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
  (int, int) score(String lessonId) {
    final lesson = trail.lesson(lessonId);
    if (lesson == null) return (0, 0);
    return (progress.of(lessonId).scoreOf(lesson), lesson.maxScore);
  }

  /// A medalha da nota de um capítulo (GradeMedal M2): só depois de aprovado
  /// ou com todos os exercícios resolvidos; nula no que ainda não foi feito.
  ExerciseGrade? medal(String lessonId) {
    final lesson = trail.lesson(lessonId);
    if (lesson == null || lesson.exercises.isEmpty) return null;
    final each = progress.of(lessonId);
    if (!EndgameLessonRules.allSolved(lesson, each) &&
        !EndgameLessonRules.passed(lesson, each)) {
      return null;
    }
    return EndgameLessonRules.grade(lesson, each.scoreOf(lesson));
  }

  /// A parte (módulo) de um capítulo e o número dele dentro dela (1, 2...).
  (EndgameModule, int)? place(String lessonId) {
    for (final module in trail.modules) {
      final index = module.lessons.indexWhere((l) => l.id == lessonId);
      if (index >= 0) return (module, index + 1);
    }
    return null;
  }
}

/// Uma seção da lista filtrada: um módulo da trilha ou uma faixa de
/// dificuldade (nula: aulas sem faixa).
class EndgameSection {
  const EndgameSection({
    required this.lessons,
    this.module,
    this.number = 0,
    this.level,
  });

  final EndgameModule? module;

  /// O número do módulo na trilha (1, 2...).
  final int number;
  final RatingLevel? level;
  final List<EndgameLesson> lessons;

  String get id => module?.id ?? 'level.${level?.name ?? 'none'}';
}

/// A trilha das aulas de finais: os módulos e as aulas, com o que já foi
/// feito. Toda aula fica aberta: a ordem é uma sugestão.
class EndgamesCubit extends Cubit<EndgamesState> {
  EndgamesCubit({
    required this._lessons,
    required this._progress,
    required this._characters,
    this._placement,
    this._school,
    this._schoolProgress,
    this._settings,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const EndgamesState());

  final AnalyticsRepository _analytics;

  final SettingsRepository? _settings;

  /// Troca entre "Para você" e "Todos", e grava a escolha.
  Future<void> setShowAll(bool showAll) async {
    emit(state.copyWith(showAll: showAll));
    await _save((settings) => settings.copyWith(endgamesAll: showAll));
  }

  /// Mostra ou esconde as aulas concluídas em "Para você", e grava a escolha.
  Future<void> setHideDone(bool hideDone) async {
    emit(state.copyWith(hideDone: hideDone));
    await _save((settings) => settings.copyWith(endgamesHideDone: hideDone));
  }

  /// Troca os filtros da lista da trilha, e grava.
  Future<void> setFilter(EndgameFilter filter) async {
    emit(state.copyWith(filter: filter));
    await _save((settings) => settings.copyWith(endgamesFilter: filter));
  }

  Future<void> toggleKind(EndgameKind kind) =>
      setFilter(state.filter.toggleKind(kind));

  Future<void> toggleLevel(RatingLevel level) =>
      setFilter(state.filter.toggleLevel(level));

  Future<void> toggleStatus(EndgameLessonStatus status) =>
      setFilter(state.filter.toggleStatus(status));

  Future<void> setSort(EndgameSort sort) =>
      setFilter(state.filter.withSort(sort));

  /// Tira todos os filtros (e volta à ordem da trilha).
  Future<void> clearFilter() => setFilter(const EndgameFilter());

  Future<void> _save(AppSettings Function(AppSettings) change) async {
    final settings = _settings;
    if (settings == null) return;
    await settings.save(change(await settings.load()));
  }

  final PlacementRepository? _placement;
  final LessonRepository? _school;
  final SchoolProgressRepository? _schoolProgress;

  final EndgameLessonRepository _lessons;
  final EndgameProgressRepository _progress;
  final CharacterRepository _characters;

  /// [showAll] escolhe o filtro desta visita (sem gravar); nulo, vale o
  /// gravado.
  Future<void> load(String language, {bool? showAll}) async {
    try {
      await _load(language, showAll: showAll);
    } on LessonContentUnavailable {
      unawaited(
        _analytics.log(
          AnalyticsEvents.aulaIndisponivel(origem: 'trilha_finais'),
        ),
      );
      if (!isClosed) emit(const EndgamesState(ready: true));
    }
  }

  Future<void> _load(String language, {bool? showAll}) async {
    final trail = await _lessons.trail();
    final texts = await _lessons.texts(language);
    final progress = await _progress.load();
    final characters = await _characters.characters();
    final saved = await _settings?.load();
    final all = showAll ?? saved?.endgamesAll ?? false;
    final hideDone = saved?.endgamesHideDone ?? false;
    final filter = saved?.endgamesFilter ?? state.filter;
    final skills = await _placement?.skills();
    final placement = _placement;
    final school = _school;
    final schoolProgress = _schoolProgress;
    final roadmap =
        placement == null || school == null || schoolProgress == null
        ? null
        : await RoadmapLoader(
            placement: placement,
            school: school,
            schoolProgress: schoolProgress,
            endgames: _lessons,
            endgameProgress: _progress,
          ).load();
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == Character.masterId) viktor = character;
    }
    emit(
      EndgamesState(
        ready: true,
        trail: trail,
        texts: texts,
        progress: progress,
        viktor: viktor,
        roadmap: roadmap,
        showAll: all,
        hideDone: hideDone,
        filter: filter,
        levels: skills == null ? const {} : EndgameLessonFilter.levels(skills),
      ),
    );
  }
}
