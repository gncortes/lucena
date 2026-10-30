import 'dart:async';

import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';

import '../fakes/fake_now.dart';
import 'mock_exercise_bank.dart';
import 'training_scenario_builder.dart';

const e2eTrainingSeed = 't85-e2e';

enum E2ETrainingScenario {
  welcome,
  large,
  progress,
  done,
  dayOff,
  doubled,
  meta,
  opening,
  medium,
  hard,
  cycle,
  schoolWelcome,
  schoolDayOne,
  schoolPieces,
  schoolMates,
  schoolDone,
  schoolDayOff,
  schoolTwoHours,
  schoolLatest,
  goalsFirst,
  goalsSecond,
  goalsMiddle,
  goalsGoalDone,
  goalsExtraLesson,
  goalsNextDay,
  goalsDoneExtra,
  goalsDayOff,
  goalsDoubled,
  goalsLarge,
  goalsScrolled,
  goalsDone,
}

const e2eGoalsScenarios = {
  E2ETrainingScenario.goalsFirst: 'first',
  E2ETrainingScenario.goalsSecond: 'second',
  E2ETrainingScenario.goalsMiddle: 'middle',
  E2ETrainingScenario.goalsGoalDone: 'goalDone',
  E2ETrainingScenario.goalsExtraLesson: 'extraLesson',
  E2ETrainingScenario.goalsNextDay: 'nextDay',
  E2ETrainingScenario.goalsDoneExtra: 'doneExtra',
  E2ETrainingScenario.goalsDayOff: 'dayOff',
  E2ETrainingScenario.goalsDoubled: 'doubled',
  E2ETrainingScenario.goalsLarge: 'large',
  E2ETrainingScenario.goalsScrolled: 'scrolled',
  E2ETrainingScenario.goalsDone: 'done',
};

/// Real index metadata/IDs, deterministic mock exercise and opening datasets.
/// State is delegated to the production local repository, including on restart.
final class E2ETrainingRepository implements TrainingRepository {
  E2ETrainingRepository(
    PreferencesService preferences,
    LessonContentAssets assets, {
    Future<TrainingResources> Function()? schoolContent,
    FutureOr<void> Function(TrainingState, TrainingState)? onSaved,
  }) : _preferences = preferences,
       _local = TrainingRepositoryLocal(
         preferences,
         LessonContentAssets(reader: _IndexOnlyReader(assets)),
         installSeed: e2eTrainingSeed,
         onSaved: onSaved,
         configs: {
           for (final config in TrainingCourseConfig.all) config.course: config,
         },
         contentSources: {
           TrainingCourseConfig.escola.indexSource: ?schoolContent,
         },
       );
  final TrainingRepositoryLocal _local;
  final PreferencesService _preferences;
  final _resources = <TrainingCourse, Future<TrainingResources>>{};

  @override
  Stream<TrainingState> get changes => _local.changes;
  @override
  Future<TrainingState> load(TrainingCourse course) => _local.load(course);
  @override
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  ) => _local.update(course, change);
  @override
  Future<TrainingState> transact(
    TrainingCourse course,
    FutureOr<TrainingState> Function(TrainingState) change,
  ) => _local.transact(course, change);

  @override
  Future<TrainingResources> resources(TrainingCourse course) =>
      _resources.putIfAbsent(course, () async {
        final index = await _local.resources(course);
        if (course == TrainingCourse.escola) return index;
        final black = await _preferences.getBool('training.e2e.black') ?? false;
        return TrainingResources(
          lessons: index.lessons,
          banks: {
            for (final lesson in index.lessons)
              if (lesson.kind == TrainingLessonKind.theme)
                lesson.id: MockExerciseBank.forLesson(lesson.id, black: black),
          },
          openings: {
            for (final lesson in index.lessons)
              if (lesson.kind == TrainingLessonKind.opening)
                lesson.id: [
                  OpeningTrecho(
                    id: 't1',
                    title: lesson.title,
                    lines: [
                      ['d2d4', 'd7d5', 'c1f4'],
                    ],
                    mock: true,
                  ),
                  OpeningTrecho(
                    id: 't2',
                    title: lesson.title,
                    lines: [
                      ['d2d4', 'g8f6'],
                    ],
                    mock: true,
                  ),
                ],
          },
        );
      });

  Future<void> seed(E2ETrainingScenario scenario, FakeNow now) async {
    now.value = DateTime(2026, 10, 26, 12);
    final course = scenario.name.startsWith('school')
        ? TrainingCourse.escola
        : TrainingCourse.pilares;
    await _preferences.setBool(
      'training.e2e.black',
      value: scenario == E2ETrainingScenario.meta,
    );
    _resources.remove(course);
    final data = await resources(course);
    if (data.lessons.isEmpty) {
      throw StateError('T85 requires the real course content via CONTENT_URL');
    }
    final builder = TrainingScenarioBuilder(
      course,
      date: now(),
      resources: data,
    );
    var state = switch (scenario) {
      E2ETrainingScenario.welcome => TrainingState(
        course: course,
        installSeed: e2eTrainingSeed,
      ),
      E2ETrainingScenario.large => builder.large(),
      E2ETrainingScenario.progress => builder.progress(),
      E2ETrainingScenario.done => builder.allDone(),
      E2ETrainingScenario.dayOff => builder.large(dayOff: true),
      E2ETrainingScenario.doubled => builder.doubled(),
      E2ETrainingScenario.meta => builder.allDone(
        leaveExercises: true,
        leaveOpenings: true,
      ),
      E2ETrainingScenario.opening => builder.allDone(leaveOpenings: true),
      E2ETrainingScenario.medium => builder.large(cycleDay: 3),
      E2ETrainingScenario.hard => builder.large(cycleDay: 5),
      E2ETrainingScenario.cycle => builder.singleCycle(),
      E2ETrainingScenario.schoolWelcome => TrainingState(
        course: course,
        installSeed: e2eTrainingSeed,
      ),
      E2ETrainingScenario.schoolDayOne => builder.schoolDayOne(),
      E2ETrainingScenario.schoolPieces ||
      E2ETrainingScenario.schoolLatest => builder.schoolPieces(),
      E2ETrainingScenario.schoolMates => builder.schoolMates(),
      E2ETrainingScenario.schoolDone => builder.schoolAllDone(),
      E2ETrainingScenario.schoolDayOff => builder.schoolOffDay(),
      E2ETrainingScenario.schoolTwoHours => builder.schoolTwoHours(),
      E2ETrainingScenario.goalsFirst ||
      E2ETrainingScenario.goalsSecond ||
      E2ETrainingScenario.goalsMiddle ||
      E2ETrainingScenario.goalsGoalDone ||
      E2ETrainingScenario.goalsExtraLesson ||
      E2ETrainingScenario.goalsNextDay ||
      E2ETrainingScenario.goalsDoneExtra ||
      E2ETrainingScenario.goalsDayOff ||
      E2ETrainingScenario.goalsDoubled ||
      E2ETrainingScenario.goalsLarge ||
      E2ETrainingScenario.goalsScrolled ||
      E2ETrainingScenario.goalsDone => builder.goalsScenario(
        e2eGoalsScenarios[scenario]!,
      ),
    };
    now.value = builder.now();
    if (scenario == E2ETrainingScenario.schoolLatest) {
      for (final goal
          in state.day!.goals
              .where((g) => g.kind == GoalKind.lesson)
              .toList()) {
        state = CompleteTrainingLesson(now, builder.config)(
          state,
          data,
          data.lessons.firstWhere((l) => l.id == goal.ref),
        );
      }
      state = state.copyWith(
        lastActivityAt: now().subtract(const Duration(hours: 3)),
      );
      final other =
          TrainingScenarioBuilder(
                TrainingCourse.pilares,
                date: now(),
                resources: await resources(TrainingCourse.pilares),
              )
              .allDone(leaveExercises: true)
              .copyWith(
                lastActivityAt: now().subtract(const Duration(hours: 2)),
              );
      await _local.update(
        TrainingCourse.pilares,
        (_) => TrainingState.fromJson({
          ...other.toJson(),
          'installSeed': e2eTrainingSeed,
        }),
      );
    }
    // Builder's historic seed stays unchanged for existing widget fixtures.
    final seeded = TrainingState.fromJson({
      ...state.toJson(),
      'installSeed': e2eTrainingSeed,
    });
    await _local.update(course, (_) => seeded);
  }
}

/// Reuse the production index parser without requesting private exercise banks.
final class _IndexOnlyReader extends LessonContentReader {
  _IndexOnlyReader(this.assets);
  final LessonContentAssets assets;
  @override
  Future<String> read(String path) {
    if (path != 'assets/courses/pilares/index.json') {
      throw const LessonContentUnavailable();
    }
    return assets.loadString(path);
  }
}
