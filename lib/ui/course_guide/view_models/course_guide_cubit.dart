import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
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

final class CourseGuideState {
  const CourseGuideState({
    this.training,
    this.resources,
    this.loading = true,
    this.saving = false,
    this.failed = false,
    this.teacher,
    this.testScores = const {},
  });
  final TrainingState? training;
  final TrainingResources? resources;
  final Character? teacher;
  final Map<String, int?> testScores;
  final bool loading, saving, failed;
  TrainingLesson? get nextLesson => resources?.lessons
      .where(
        (lesson) =>
            lesson.visible &&
            !(training?.completedLessons.containsKey(lesson.id) ?? false),
      )
      .firstOrNull;
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
  );
}

/// Navigation is performed by the view only after these durable commands finish.
final class CourseGuideCubit extends Cubit<CourseGuideState> {
  CourseGuideCubit({
    required this.repository,
    required this.config,
    required this.now,
    this.beforeLoad,
    this.characters,
    this.testLessons,
    this.testProgress,
  }) : super(const CourseGuideState());
  final Future<void> Function()? beforeLoad;
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final CharacterRepository? characters;
  final EndgameLessonRepository? testLessons;
  final EndgameProgressRepository? testProgress;
  Future<void> _pending = Future.value();

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
            testScores: scores,
          ),
        );
      }
    } on Object {
      if (!isClosed) emit(state.copyWith(loading: false, failed: true));
    }
  });

  Future<Map<String, int?>> _testScores(TrainingResources resources) async {
    final lessons = testLessons, progress = testProgress;
    if (lessons == null || progress == null) return const {};
    try {
      final trail = await lessons.trail();
      final records = await progress.load();
      return Map.unmodifiable({
        for (final entry in resources.lessons.where(
          (l) => l.kind == TrainingLessonKind.test,
        ))
          entry.id: switch (trail.lesson(entry.id)) {
            final lesson?
                when lesson.maxScore > 0 &&
                    records.of(lesson.id).solvedOf(lesson) > 0 =>
              (100 * records.of(lesson.id).scoreOf(lesson) / lesson.maxScore)
                  .round(),
            _ => null,
          },
      });
    } on LessonContentUnavailable {
      return const {};
    }
  }

  Future<bool> _change(TrainingState Function(TrainingState) change) =>
      _serial(() async {
        if (state.resources == null) return false;
        if (!isClosed) emit(state.copyWith(saving: true, failed: false));
        try {
          final saved = await repository.update(config.course, change);
          if (!isClosed) emit(state.copyWith(training: saved, saving: false));
          return true;
        } on Object {
          if (!isClosed) emit(state.copyWith(saving: false, failed: true));
          return false;
        }
      });

  Future<bool> start(TrainingPlan plan) => _change(
    (s) => BuildDayGoals(now, config)(
      s.copyWith(plan: plan, onboardingDone: true),
      state.resources!,
    ),
  );
  Future<bool> selectTab(CourseGuideTab tab) =>
      _change((s) => s.copyWith(tab: tab));

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
