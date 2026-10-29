import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/models/training/school_training_progress.dart';
import 'package:lucena/domain/models/training/school_training_observations.dart';
import 'package:lucena/domain/use_cases/training/reconcile_school_training.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/complete_training_goal.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/domain/use_cases/training/double_training_goals.dart';
import 'package:lucena/domain/use_cases/training/training_date.dart';

import '../fakes/fake_now.dart';
import '../fakes/fake_course_training_repository.dart';
import '../fakes/fake_star_challenge_repository.dart';
import '../fakes/fake_progress_repository.dart';
import '../fakes/fake_speedrun_repository.dart';
import 'mock_exercise_bank.dart';

/// Large deterministic fixture, shared by widget, Patrol and screenshot tests.
/// School support is added with T85.14, using the existing challenge fakes.
final class TrainingScenarioBuilder {
  TrainingScenarioBuilder(this.course, {DateTime? date, this.resources})
    : now = FakeNow(date ?? DateTime(2026, 10, 26, 12));
  final TrainingResources? resources;
  final TrainingCourse course;
  final FakeNow now;
  TrainingCourseConfig get config => switch (course) {
    TrainingCourse.pilares => TrainingCourseConfig.pilares,
    TrainingCourse.escola => TrainingCourseConfig.escola,
  };
  final schoolStars = FakeStarChallengeRepository();
  final schoolProgress = FakeProgressRepository();
  late final schoolSpeedruns = FakeSpeedrunRepository(schoolProgress);
  List<String> get _themes => content.lessons
      .where((l) => l.visible && l.kind == TrainingLessonKind.theme)
      .map((l) => l.id)
      .toList();
  List<String> get _openings => content.lessons
      .where((l) => l.visible && l.kind == TrainingLessonKind.opening)
      .map((l) => l.id)
      .take(4)
      .toList();
  TrainingResources get content =>
      resources ??
      (course == TrainingCourse.escola
          ? throw StateError(
              'Inject visible School resources from LessonRepository',
            )
          : TrainingResources(
              lessons: [
                for (var i = 1; i <= 12; i++)
                  TrainingLesson(
                    id: 'theme$i',
                    kind: TrainingLessonKind.theme,
                    title: 'Tema $i',
                    summary: 'Resumo $i',
                    group: 'Capítulo $i',
                  ),
                for (var i = 1; i <= 4; i++)
                  TrainingLesson(
                    id: 'opening$i',
                    kind: TrainingLessonKind.opening,
                    title: 'Abertura $i',
                    group: 'Aberturas',
                  ),
              ],
              banks: {
                for (var i = 1; i <= 12; i++)
                  'theme$i': MockExerciseBank.forLesson('theme$i'),
              },
              openings: {
                for (var i = 1; i <= 4; i++)
                  'opening$i': [
                    OpeningTrecho(
                      id: 't1',
                      title: 'Linha 1',
                      moves: ['d2d4', 'd7d5', 'c1f4'],
                      mock: true,
                    ),
                    OpeningTrecho(
                      id: 't2',
                      title: 'Linha 2',
                      moves: ['d2d4', 'g8f6'],
                      mock: true,
                    ),
                  ],
              },
            ));

  /// Filled history for the progress UI, with every mastery rendering branch.
  TrainingState progress() {
    final state = large();
    const weights = [1, 1, 2, 2, 3, 3, 3];
    const earned = [
      {0, 1, 2, 4},
      {0, 1, 4, 5, 6},
      {0, 1, 2, 3, 4, 5, 6},
      {0, 1, 2, 3, 4, 5},
    ];
    final started = trainingDate(now().subtract(const Duration(days: 9)));
    final cycles = {
      for (final entry in state.cycles.entries)
        entry.key: ThemeCycle.fromJson({
          ...entry.value.toJson(),
          'startedOn': started,
        }),
    };
    for (var theme = 0; theme < 4; theme++) {
      final id = _themes[theme];
      final used = <String>{};
      final days = <ThemeDay>[];
      for (var day = 0; day < (theme == 3 ? 6 : 7); day++) {
        final exercise = content.banks[id]!.firstWhere(
          (e) => e.stars == weights[day] && !used.contains(e.id),
        );
        used.add(exercise.id);
        final hint = theme == 0 && day == 3;
        days.add(
          ThemeDay(
            date: trainingDate(now().subtract(Duration(days: 8 - day))),
            exerciseId: exercise.id,
            stars: exercise.stars,
            correct: earned[theme].contains(day) || hint,
            hint: hint,
            mock: exercise.mock,
          ),
        );
      }
      cycles[id] = ThemeCycle(
        lessonId: id,
        startedOn: trainingDate(now().subtract(const Duration(days: 8))),
        phase: theme == 0
            ? ThemePhase.reinforce
            : theme == 3
            ? ThemePhase.cycle
            : ThemePhase.firm,
        level: theme == 3 ? 3 : 1,
        hadError: theme == 0,
        days: days,
        reinforcement: theme == 0
            ? content.banks[id]!
                  .where((e) => !used.contains(e.id))
                  .map((e) => e.id)
            : const [],
      );
    }
    final filled = state.copyWith(
      cycles: cycles,
      completedLessons: {
        for (final id in state.completedLessons.keys) id: started,
      },
      openings: {
        for (final id in _openings)
          id: OpeningTrack(
            lessonId: id,
            startedOn: started,
            lastNewDate: trainingDate(now().subtract(const Duration(days: 1))),
            doneTrechos: {
              for (final segment in content.openings[id]!.take(2))
                segment.id: trainingDate(
                  now().subtract(const Duration(days: 1)),
                ),
            },
            firstTry: {
              for (final segment in content.openings[id]!.take(2))
                segment.id: [
                  for (
                    var move = 0;
                    move <
                        (segment.moves.length + (segment.black ? 0 : 1)) ~/ 2;
                    move++
                  )
                    move == 0,
                ],
            },
          ),
      },
    );
    return BuildDayGoals(now, config)(
      TrainingState.fromJson({...filled.toJson(), 'day': null}),
      content,
    );
  }

  TrainingState singleCycle() {
    final lesson = content.lessons.firstWhere(
      (l) => l.visible && l.kind == TrainingLessonKind.theme,
    );
    final yesterday = trainingDate(now().subtract(const Duration(days: 1)));
    return BuildDayGoals(now, config)(
      TrainingState(
        course: course,
        installSeed: 'single-cycle',
        onboardingDone: true,
        plan: const TrainingPlan(weekdays: 127, reminderOn: false),
        completedLessons: {
          for (final l in content.lessons.where((l) => l.visible))
            l.id: yesterday,
        },
        cycles: {
          lesson.id: ThemeCycle(lessonId: lesson.id, startedOn: yesterday),
        },
      ),
      content,
    );
  }

  /// Shared Pilares artboard states. Use a fresh builder per sample: second and
  /// nextDay advance [now], so the host must use this same clock.
  TrainingState goalsScenario(String sample) {
    TrainingState first() => BuildDayGoals(now, config)(
      TrainingState(course: course, installSeed: 'first', onboardingDone: true),
      content,
    );
    TrainingState completeNext(TrainingState state) =>
        CompleteTrainingLesson(now, config)(
          state,
          content,
          content.lessons.firstWhere(
            (l) => l.visible && !state.completedLessons.containsKey(l.id),
          ),
        );
    TrainingState middle() {
      var state = large();
      final goals = state.day!.goals;
      final lesson = goals.firstWhere((g) => g.kind == GoalKind.lesson);
      final exercises = goals
          .where((g) => g.kind == GoalKind.exercise)
          .take(3)
          .toList();
      state = state.copyWith(
        day: state.day!.copyWith(
          goals: [
            lesson,
            ...exercises,
            ...goals.where((g) => g.kind == GoalKind.openings),
          ],
        ),
      );
      state = CompleteTrainingLesson(now, config)(
        state,
        content,
        content.lessons.firstWhere((l) => l.id == lesson.ref),
      );
      return CompleteTrainingGoal(now)
          .exercise(state, content, exercises.first.key, correct: true);
    }

    switch (sample) {
      case 'first':
        return first();
      case 'second':
        final state = completeNext(first());
        now.advance(const Duration(days: 1));
        return BuildDayGoals(now, config)(state, content);
      case 'middle':
        return middle();
      case 'goalDone':
        final state = middle();
        final exercise = state.day!.goals.firstWhere(
          (g) => g.kind == GoalKind.exercise && !g.done,
        );
        return CompleteTrainingGoal(now)
            .exercise(state, content, exercise.key, correct: true);
      case 'extraLesson':
        return completeNext(middle());
      case 'nextDay':
        final state = completeNext(middle());
        now.advance(const Duration(days: 1));
        return BuildDayGoals(now, config)(state, content);
      case 'doneExtra':
        return completeNext(allDone());
      case 'dayOff':
        return large(dayOff: true);
      case 'doubled':
        return DoubleTrainingGoals(now, config)(
          completeNext(allDone()),
          content,
        );
      case 'large':
      case 'scrolled':
        return large();
      case 'done':
        return allDone();
      default:
        throw ArgumentError.value(sample, 'sample', 'Unknown goals artboard');
    }
  }

  TrainingState large({int cycleDay = 1, bool dayOff = false}) {
    if (course != TrainingCourse.pilares) {
      return schoolPieces(dayOff: dayOff);
    }
    if (cycleDay < 1 || cycleDay > 7) throw RangeError.range(cycleDay, 1, 7);
    final data = content;
    final themes = _themes;
    final openings = _openings;
    if (themes.length < 10 || openings.length < 4) {
      throw StateError('Large fixture requires ten themes and four openings');
    }
    const started = '2026-10-01';
    final cycles = <String, ThemeCycle>{};
    for (var i = 1; i <= 7; i++) {
      final days = <ThemeDay>[];
      final used = <int, int>{1: 0, 2: 0, 3: 0};
      for (var d = 1; d < cycleDay; d++) {
        final stars = [1, 1, 2, 2, 3, 3, 3][d - 1];
        final exercise = data.banks[themes[i - 1]]!
            .where((e) => e.stars == stars)
            .elementAt(used[stars]!);
        used[stars] = used[stars]! + 1;
        days.add(
          ThemeDay(
            date: '2026-10-${(d + 1).toString().padLeft(2, '0')}',
            exerciseId: exercise.id,
            stars: stars,
            correct: true,
            mock: true,
          ),
        );
      }
      cycles[themes[i - 1]] = ThemeCycle(
        lessonId: themes[i - 1],
        startedOn: started,
        level: [1, 1, 2, 2, 3, 3, 3][cycleDay - 1],
        streak: (cycleDay - 1) % 2,
        days: days,
      );
    }
    cycles[themes[7]] = ThemeCycle(
      lessonId: themes[7],
      startedOn: started,
      phase: ThemePhase.reinforce,
      reinforcement: data.banks[themes[7]]!.map((e) => e.id),
    );
    final state = TrainingState(
      course: course,
      installSeed: 'large-fixture',
      onboardingDone: true,
      plan: TrainingPlan(weekdays: dayOff ? 0 : 127),
      completedLessons: {
        for (final id in themes.take(8)) id: started,
        for (final id in openings) id: started,
        if (resources != null)
          for (final lesson in data.lessons.takeWhile((l) => l.id != themes[8]))
            lesson.id: started,
      },
      cycles: cycles,
      openings: {
        for (final id in openings)
          id: OpeningTrack(lessonId: id, startedOn: started),
      },
    );
    return BuildDayGoals(now, config)(state, data);
  }

  TrainingState missed({int cycleDay = 1}) {
    final state = large(cycleDay: cycleDay);
    now.advance(const Duration(days: 1));
    return BuildDayGoals(now, config)(state, content);
  }

  TrainingState allDone({
    bool leaveOpenings = false,
    bool leaveExercises = false,
  }) {
    if (course == TrainingCourse.escola) return schoolAllDone();
    var state = large();
    for (final goal in state.day!.goals) {
      if (goal.kind == GoalKind.exercise || goal.kind == GoalKind.reinforce) {
        if (leaveExercises) continue;
        state = CompleteTrainingGoal(now)
            .exercise(state, content, goal.key, correct: true);
      } else if (goal.kind == GoalKind.openings) {
        if (leaveOpenings) continue;
        for (final id in goal.items.keys) {
          state = CompleteTrainingGoal(now)
              .opening(state, content, id, [true, true]);
        }
      } else if (goal.kind == GoalKind.lesson) {
        state = CompleteTrainingLesson(now, config)(
          state,
          content,
          content.lessons.firstWhere((l) => l.id == goal.ref),
        );
      }
    }
    return state;
  }

  TrainingState doubled() {
    final done = allDone();
    final extra = course == TrainingCourse.escola
        ? content.lessons.firstWhere(
            (l) => l.visible && !done.completedLessons.containsKey(l.id),
          )
        : content.lessons.firstWhere((l) => l.id == _themes[9]);
    var state = CompleteTrainingLesson(now, config)(done, content, extra);
    if (course == TrainingCourse.escola) state = _completeSchoolGoals(state);
    return DoubleTrainingGoals(now, config)(state, content);
  }

  TrainingState schoolDayOne({int minutes = 30, bool dayOff = false}) =>
      BuildDayGoals(now, config)(
        TrainingState(
          course: course,
          installSeed: 'school-fixture',
          onboardingDone: true,
          plan: TrainingPlan(minutes: minutes, weekdays: dayOff ? 0 : 127),
        ),
        content,
      );

  TrainingState schoolOffDay() => schoolDayOne(dayOff: true);
  TrainingState schoolTwoHours() => schoolDayOne(minutes: 120);

  TrainingState schoolPieces({
    bool dayOff = false,
    bool completedStars = false,
  }) {
    final pieces = content.lessons
        .where((l) => l.visible && l.id.startsWith('pieces.'))
        .take(5)
        .toList();
    final date = trainingDate(now());
    final yesterday = trainingDate(now().subtract(const Duration(days: 1)));
    final state = TrainingState(
      course: course,
      installSeed: 'school-pieces',
      onboardingDone: true,
      plan: TrainingPlan(weekdays: dayOff ? 0 : 127),
      completedLessons: {for (final l in pieces) l.id: yesterday},
      school: SchoolTrainingProgress(
        pieceLevels: {
          for (var i = 0; i < pieces.length; i++)
            pieces[i].id.split('.').last: completedStars ? 3 : i % 3,
        },
        pieceAdvancedOn: {
          for (final l in pieces)
            l.id.split('.').last: completedStars ? date : yesterday,
        },
      ),
    );
    return BuildDayGoals(now, config)(state, content);
  }

  TrainingState schoolMates({bool completedBots = false}) {
    final date = trainingDate(now());
    final state = TrainingState(
      course: course,
      installSeed: 'school-mates',
      onboardingDone: true,
      plan: const TrainingPlan(weekdays: 127),
      completedLessons: {
        for (final l in content.lessons.where(
          (l) => l.visible && l.groupId == 'firstMates',
        ))
          l.id: date,
      },
      school: SchoolTrainingProgress(
        botsCompletedOn: {
          if (completedBots) 'mates.twoRooks': date,
          if (completedBots) 'mates.queen': date,
        },
        speedrunCompletedOn: completedBots ? date : null,
      ),
    );
    return BuildDayGoals(now, config)(state, content);
  }

  TrainingState schoolAllDone() {
    var state = schoolDayOne();
    for (final goal in state.day!.goals.toList()) {
      state = CompleteTrainingLesson(now, config)(
        state,
        content,
        content.lessons.firstWhere((l) => l.id == goal.ref),
      );
    }
    return _completeSchoolGoals(state);
  }

  TrainingState _completeSchoolGoals(
    TrainingState state,
  ) => ReconcileSchoolTraining(now)(
    state,
    content,
    SchoolTrainingObservations(
      starRuns: [
        for (final g in state.day!.goals.where((g) => g.kind == GoalKind.stars))
          StarChallengeRun(
            piece: ChallengePiece.values.byName(g.ref.split('.').last),
            level: ChallengeLevel.values.byName(g.itemId!),
            points: 99,
            at: now(),
          ),
      ],
      botWins: [
        for (final g in state.day!.goals.where((g) => g.kind == GoalKind.bot))
          SchoolBotWin(positionId: g.itemId!, rung: '1000', at: now()),
      ],
      speedruns: [SchoolSpeedrunFinish(id: 'journey.mates', at: now())],
    ),
  );

  FakeTrainingRepository repository(TrainingState state) =>
      FakeTrainingRepository(
        states: {course: state},
        content: {course: content},
      );
  String get date => trainingDate(now());
}
