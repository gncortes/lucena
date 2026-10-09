import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/placement/placement_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/placement_roadmap.dart';
import '../../placement/view_models/roadmap_loader.dart';
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
    this.roadmap,
    this.showAll = false,
    this.hideDone = false,
  });

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
        !placed.soon &&
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
  }) : super(const EndgamesState());

  final SettingsRepository? _settings;

  /// Troca entre "Para você" e "Todos", e grava a escolha.
  Future<void> setShowAll(bool showAll) async {
    emit(
      EndgamesState(
        ready: state.ready,
        trail: state.trail,
        texts: state.texts,
        progress: state.progress,
        viktor: state.viktor,
        roadmap: state.roadmap,
        showAll: showAll,
        hideDone: state.hideDone,
      ),
    );
    final settings = _settings;
    if (settings == null) return;
    await settings.save((await settings.load()).copyWith(endgamesAll: showAll));
  }

  /// Mostra ou esconde as aulas concluídas em "Para você", e grava a escolha.
  Future<void> setHideDone(bool hideDone) async {
    emit(
      EndgamesState(
        ready: state.ready,
        trail: state.trail,
        texts: state.texts,
        progress: state.progress,
        viktor: state.viktor,
        roadmap: state.roadmap,
        showAll: state.showAll,
        hideDone: hideDone,
      ),
    );
    final settings = _settings;
    if (settings == null) return;
    await settings.save(
      (await settings.load()).copyWith(endgamesHideDone: hideDone),
    );
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
    final trail = await _lessons.trail();
    final texts = await _lessons.texts(language);
    final progress = await _progress.load();
    final characters = await _characters.characters();
    final saved = await _settings?.load();
    final all = showAll ?? saved?.endgamesAll ?? false;
    final hideDone = saved?.endgamesHideDone ?? false;
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
      if (character.id == LessonCubit.viktorId) viktor = character;
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
      ),
    );
  }
}
