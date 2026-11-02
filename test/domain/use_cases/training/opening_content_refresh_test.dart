import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/opening_trecho_rules.dart';

import '../../../../testing/fakes/fake_now.dart';

void main() {
  final now = FakeNow(DateTime(2026, 10, 29, 12));
  final builder = BuildDayGoals(now, TrainingCourseConfig.pilares);
  final real = OpeningTrecho.fromJson({
    'id': 'ideia.ex1',
    'titulo': 'Real',
    'cor': 'brancas',
    'exemplo': {'id': 'ex1', 'fen': GameRules.initial.fen, 'linha': []},
  });
  final content = TrainingResources(
    lessons: [
      const TrainingLesson(
        id: 'opening',
        kind: TrainingLessonKind.opening,
        title: '',
      ),
    ],
    openings: {
      'opening': [real],
    },
  );
  TrainingState saved({bool doneToday = false, bool goalDone = false}) =>
      TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'keep-seed',
        completedLessons: {'opening': '2026-10-20', 'other': '2026-10-21'},
        lastLessonDate: '2026-10-28',
        offDayCredits: ['other'],
        day: DayGoals(
          date: '2026-10-29',
          studyDay: true,
          doubled: true,
          goals: [
            TrainingGoal(kind: GoalKind.lesson, ref: 'other', done: true),
            TrainingGoal(
              kind: GoalKind.openings,
              ref: 'openings',
              hintUsed: true,
              mock: true,
              done: goalDone,
              items: {'opening': 'mock-1'},
            ),
          ],
        ),
        openings: {
          'opening': OpeningTrack(
            lessonId: 'opening',
            startedOn: '2026-10-20',
            lastNewDate: doneToday ? '2026-10-29' : '2026-10-28',
            doneTrechos: {'t1': doneToday ? '2026-10-29' : '2026-10-28'},
            firstTry: {
              't1': [true, true],
            },
            pendingMistakes: {
              'mock-1': [0],
            },
          ),
        },
      );
  setUp(() => now.value = DateTime(2026, 10, 29, 12));

  test('same day refresh replaces missing pending ID and preserves all other state', () {
    final before = saved();
    final after = builder(before, content);
    final goal = after.day!.goals.last;
    expect(goal.items, {'opening': 'ideia.ex1'});
    expect(goal.hintUsed, true);
    expect(goal.mock, false);
    expect(goal.done, false);
    expect(after.day!.date, before.day!.date);
    expect(after.day!.doubled, true);
    expect(after.day!.plan.toJson(), before.day!.plan.toJson());
    final oldJson = Map<String, Object?>.from(before.toJson())..remove('day');
    final newJson = Map<String, Object?>.from(after.toJson())..remove('day');
    expect(newJson, oldJson);
    expect(builder(after, content), same(after));
  });

  test('missing source and legacy bank never reconcile frozen goals', () {
    final before = saved();
    expect(builder(before, TrainingResources()), same(before));
    expect(
      builder(
        before,
        TrainingResources(
          openings: {
            'opening': [
              OpeningTrecho(id: 't2', title: '', moves: ['e2e4']),
            ],
          },
        ),
      ),
      same(before),
    );
  });

  test(
    'completed legacy opening today consumes slot without awarding new content',
    () {
      final before = saved(doneToday: true, goalDone: true);
      expect(builder(before, content), same(before));
      final incompleteAggregate = builder(saved(doneToday: true), content);
      expect(incompleteAggregate.day!.goals.last.items, {'opening': 't1'});
      expect(incompleteAggregate.day!.goals.last.done, true);
      expect(incompleteAggregate.openings['opening']!.doneTrechos, {
        't1': '2026-10-29',
      });
      expect(
        OpeningTrechoRules(now)
            .next(incompleteAggregate.openings['opening']!, [real]),
        isNull,
      );
    },
  );

  test(
    'next study day chooses real segment without resetting legacy history',
    () {
      now.value = DateTime(2026, 10, 30, 12);
      final after = builder(saved(doneToday: true, goalDone: true), content);
      expect(
        after.day!.goals.where((g) => g.kind == GoalKind.openings).single.items,
        {'opening': 'ideia.ex1'},
      );
      expect(after.openings['opening']!.firstTry, {
        't1': [true, true],
      });
      expect(after.completedLessons['other'], '2026-10-21');
    },
  );

  test(
    'current mastery intersects IDs while retaining legacy stored scores',
    () {
      final track = OpeningTrack(
        lessonId: 'opening',
        startedOn: '2026-10-20',
        doneTrechos: {'t1': 'old', 'mock-1': 'old', 'ideia.ex1': 'today'},
        firstTry: {
          't1': [true, true],
          'mock-1': [true],
          'ideia.ex1': [true, false],
        },
      );
      expect(OpeningTrechoRules.currentProgress(track, [real]), (
        done: 1,
        firmMoves: 1,
        seenMoves: 2,
      ));
      expect(track.firmMoves, 4);
      expect(track.firstTry.length, 3);
      expect(
        OpeningTrechoRules.currentProgress(saved().openings['opening']!, [
          real,
        ]),
        (done: 0, firmMoves: 0, seenMoves: 0),
      );
    },
  );
}
