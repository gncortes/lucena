import 'dart:async';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/use_cases/training/training_analytics.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/placement/placement_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/lesson.dart' show LessonCheckpoint;
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson_content.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_plan.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/build_day_goals.dart';
import '../../../domain/use_cases/training/complete_training_lesson.dart';
import '../../../domain/use_cases/training/double_training_goals.dart';

typedef CourseTestProgress = ({int score, int maxScore, int solved, int total});

final class CourseGuideState {
  const CourseGuideState({
    this.training,
    this.resources,
    this.loading = true,
    this.saving = false,
    this.failed = false,
    this.teacher,
    this.testScores = const {},
    this.testProgress = const {},
    this.levelTestProgress,
    this.lessonCheckpoint,
  });
  final TrainingState? training;
  final TrainingResources? resources;
  final Character? teacher;
  final Map<String, int?> testScores;
  final Map<String, CourseTestProgress> testProgress;
  final CourseTestProgress? levelTestProgress;
  final LessonCheckpoint? lessonCheckpoint;
  final bool loading, saving, failed;
  TrainingLesson? get _nextInOrder => resources?.lessons
      .where(
        (lesson) =>
            lesson.inCourseOrder &&
            (lesson.visible || !lesson.published) &&
            !(training?.completedLessons.containsKey(lesson.id) ?? false),
      )
      .firstOrNull;
  TrainingLesson? get resumedLesson {
    final checkpoint = lessonCheckpoint;
    if (checkpoint?.scriptExample == null) return null;
    return resources?.lessons
        .where(
          (lesson) =>
              lesson.visible &&
              lesson.published &&
              (checkpoint!.open ||
                  !(training?.completedLessons.containsKey(lesson.id) ??
                      false)) &&
              (lesson.id == checkpoint.lessonId ||
                  lesson.id == '${checkpoint.lessonId}.${checkpoint.part}'),
        )
        .firstOrNull;
  }

  TrainingLesson? get nextLesson =>
      resumedLesson ?? (_nextInOrder?.published == true ? _nextInOrder : null);
  bool get awaitingPublication => _nextInOrder?.published == false;
  CourseGuideState copyWith({
    TrainingState? training,
    TrainingResources? resources,
    bool? loading,
    bool? saving,
    bool? failed,
  }) => CourseGuideState(
    training: training ?? this.training,
    resources: resources ?? this.resources,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    failed: failed ?? this.failed,
    teacher: teacher,
    testScores: testScores,
    testProgress: testProgress,
    levelTestProgress: levelTestProgress,
    lessonCheckpoint: lessonCheckpoint,
  );
}

/// Navigation is performed by the view only after these durable commands finish.
final class CourseGuideCubit extends Cubit<CourseGuideState> {
  CourseGuideCubit({
    required this.repository,
    required this.config,
    required this.now,
    this.analytics = const NoAnalyticsRepository(),
    this.trainingAnalytics,
    this.beforeLoad,
    this.characters,
    this.testLessons,
    this.testProgress,
    this.placement,
    this.schoolProgress,
    this.beforeOpeningProfileLoad,
  }) : super(const CourseGuideState());
  final Future<void> Function()? beforeLoad;
  final Future<void> Function()? beforeOpeningProfileLoad;
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final AnalyticsRepository analytics;
  final TrainingAnalytics? trainingAnalytics;
  Future<void> _log(AnalyticsEvent event) {
    unawaited(
      Future<void>.sync(() => analytics.log(event)).catchError((Object _) {}),
    );
    return Future<void>.value();
  }

  final CharacterRepository? characters;
  final EndgameLessonRepository? testLessons;
  final EndgameProgressRepository? testProgress;
  final PlacementRepository? placement;
  final SchoolProgressRepository? schoolProgress;
  Future<void> _pending = Future.value();
  Timer? _saveRetry;

  @override
  Future<void> close() async {
    _saveRetry?.cancel();
    await super.close();
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _pending.then((_) => action());
    _pending = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<void> load() => _serial(() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, failed: false));
    try {
      await beforeLoad?.call();
      final resources = await repository.resources(config.course);
      final teachers = await characters?.characters();
      final scores = await _testScores(resources);
      final checkpoint = config.course == TrainingCourse.escola
          ? (await schoolProgress?.load())?.ongoing
          : (await testProgress?.load())?.ongoing;
      final levelResult = config.course == TrainingCourse.pilares
          ? await placement?.result()
          : null;
      final levelAnswers = levelResult?.answers;
      final before = await repository.load(config.course);
      final training = before.onboardingDone
          ? await repository.update(
              config.course,
              (s) => BuildDayGoals(now, config)(s, resources),
            )
          : before;
      if (!isClosed) {
        emit(
          CourseGuideState(
            training: training,
            resources: resources,
            loading: false,
            teacher: teachers
                ?.where((c) => c.id == Character.masterId)
                .firstOrNull,
            testScores: scores.scores,
            testProgress: scores.details,
            lessonCheckpoint: checkpoint,
            levelTestProgress: levelAnswers == null || levelAnswers.isEmpty
                ? null
                : (
                    score: levelAnswers.where((a) => a.correct).length,
                    maxScore: levelAnswers.length,
                    solved: levelAnswers.length,
                    total: levelAnswers.length,
                  ),
          ),
        );
      }
    } on Object {
      if (!isClosed) emit(state.copyWith(loading: false, failed: true));
    }
  });

  Future<({Map<String, int?> scores, Map<String, CourseTestProgress> details})>
  _testScores(TrainingResources resources) async {
    final lessons = testLessons, progress = testProgress;
    if (lessons == null || progress == null) {
      return (
        scores: const <String, int?>{},
        details: const <String, CourseTestProgress>{},
      );
    }
    try {
      final trail = await lessons.trail();
      final records = await progress.load();
      final scores = <String, int?>{};
      final details = <String, CourseTestProgress>{};
      for (final entry in resources.lessons.where(
        (l) => l.kind == TrainingLessonKind.test,
      )) {
        final lesson = trail.lesson(entry.id);
        scores[entry.id] = null;
        if (lesson == null) continue;
        final record = records.of(lesson.id);
        if (lesson.id.startsWith('pilares.')) {
          final answers = record.completedTestOf(lesson);
          if (answers == null || answers.isEmpty) continue;
          final correct = answers.values.where((correct) => correct).length;
          final total = answers.length;
          details[entry.id] = (
            score: correct,
            maxScore: total,
            solved: total,
            total: total,
          );
          scores[entry.id] = (100 * correct / total).round();
          continue;
        }
        final score = record.scoreOf(lesson), solved = record.solvedOf(lesson);
        details[entry.id] = (
          score: score,
          maxScore: lesson.maxScore,
          solved: solved,
          total: lesson.exercises.length,
        );
        if (lesson.maxScore > 0 && solved > 0) {
          scores[entry.id] = (100 * score / lesson.maxScore).round();
        }
      }
      return (
        scores: Map<String, int?>.unmodifiable(scores),
        details: Map<String, CourseTestProgress>.unmodifiable(details),
      );
    } on LessonContentUnavailable {
      return (
        scores: const <String, int?>{},
        details: const <String, CourseTestProgress>{},
      );
    }
  }

  Future<bool> _change(TrainingState Function(TrainingState) change) =>
      _serial(() async {
        if (state.resources == null) return false;
        if (!isClosed) emit(state.copyWith(saving: true, failed: false));
        try {
          final saved = await repository.update(config.course, change);
          _saveRetry?.cancel();
          if (!isClosed) emit(state.copyWith(training: saved, saving: false));
          return true;
        } on Object {
          if (!isClosed) emit(state.copyWith(saving: false, failed: true));
          _saveRetry?.cancel();
          _saveRetry = Timer(const Duration(seconds: 1), () {
            if (!isClosed) unawaited(_change(change));
          });
          return false;
        }
      });

  Future<bool> selectOpeningProfile(String profile, {String? startPart}) async {
    final saved = await _change((s) {
      if (profile != 'solido' && profile != 'agressivo') {
        throw ArgumentError.value(profile);
      }
      final requestedPart = startPart ?? state.nextLesson?.partId ?? '';
      final next = s.copyWith(
        openingProfile: profile,
        openingProfileStartPart: requestedPart.isNotEmpty
            ? requestedPart
            : s.openingProfileStartPart.isEmpty
            ? 'chosen'
            : s.openingProfileStartPart,
      );
      final day = next.day;
      if (day == null) return next;
      return next.copyWith(
        day: day.copyWith(
          goals: [
            ...day.goals.where((g) => g.kind != GoalKind.openings),
            ...config.followUps
                .build(next, state.resources!, now)
                .where((g) => g.kind == GoalKind.openings),
          ],
        ),
      );
    });
    if (saved) {
      try {
        await beforeOpeningProfileLoad?.call();
      } on Object {
        if (!isClosed) emit(state.copyWith(failed: true));
        return false;
      }
      await load();
      if (!state.failed && state.training?.day != null) {
        // The newly downloaded profile may contain tracks that were absent
        // from the previous resources. Build today's opening goals from it.
        return _change(
          (s) => s.copyWith(
            day: s.day!.copyWith(
              goals: [
                ...s.day!.goals.where((goal) => goal.kind != GoalKind.openings),
                ...config.followUps
                    .build(s, state.resources!, now)
                    .where((goal) => goal.kind == GoalKind.openings),
              ],
            ),
          ),
        );
      }
    }
    return saved && !state.failed;
  }

  Future<bool> start(TrainingPlan plan) => _change(
    (s) => BuildDayGoals(now, config)(
      s.copyWith(plan: plan, onboardingDone: true),
      state.resources!,
    ),
  );
  Future<bool> selectTab(CourseGuideTab tab, {String origin = 'toque'}) async {
    final saved = await _change((s) => s.copyWith(tab: tab));
    if (saved) {
      await _log(
        AnalyticsEvents.cursoGuiaAba(
          curso: config.course.name,
          aba: switch (tab) {
            CourseGuideTab.lesson => 'aula',
            CourseGuideTab.goals => 'metas',
            CourseGuideTab.progress => 'progresso',
            CourseGuideTab.catalog => 'catalogo',
          },
          origem: origin,
        ),
      );
    }
    return saved;
  }

  Future<void> announceTab({required String origin}) async {
    final tab = state.training?.tab;
    if (state.failed || state.loading || tab == null) return;
    await _log(
      AnalyticsEvents.cursoGuiaAba(
        curso: config.course.name,
        aba: switch (tab) {
          CourseGuideTab.lesson => 'aula',
          CourseGuideTab.goals => 'metas',
          CourseGuideTab.progress => 'progresso',
          CourseGuideTab.catalog => 'catalogo',
        },
        origem: origin,
      ),
    );
  }

  Future<bool> savePlan(TrainingPlan plan) =>
      _change((s) => s.copyWith(plan: plan));
  Future<bool> markTourSeen() =>
      _change((s) => s.copyWith(tourSeen: true, tab: CourseGuideTab.lesson));
  Future<bool> doubleGoals() =>
      _change((s) => DoubleTrainingGoals(now, config)(s, state.resources!));
  Future<bool> observeLesson(TrainingLesson lesson, {bool redo = false}) =>
      _change(
        (s) => CompleteTrainingLesson(now, config)(
          s,
          state.resources!,
          lesson,
          redo: redo,
        ),
      );
}
