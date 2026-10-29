import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/play_training_opening.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';

void main() {
  final first = OpeningTrecho(
    id: 't1',
    title: 'line',
    moves: ['e2e4', 'e7e5', 'g1f3'],
  );
  final second = OpeningTrecho(
    id: 't2',
    title: 'line 2',
    moves: ['d2d4', 'd7d5'],
  );
  final black = OpeningTrecho(
    id: 'b1',
    title: 'black',
    black: true,
    moves: ['d2d4', 'd7d5'],
  );
  final now = FakeNow(DateTime(2026, 10, 29, 12));
  late FakeTrainingRepository repository;
  late TrainingOpeningCubit cubit;
  TrainingOpeningCubit create() => TrainingOpeningCubit(
    repository: repository,
    config: TrainingCourseConfig.pilares,
    now: now,
  );
  setUp(() async {
    now.value = DateTime(2026, 10, 29, 12);
    repository = FakeTrainingRepository(
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'test',
          day: DayGoals(
            date: '2026-10-29',
            studyDay: true,
            goals: [
              TrainingGoal(
                kind: GoalKind.openings,
                ref: 'openings',
                items: {'white': 't1', 'black': 'b1'},
              ),
            ],
          ),
          openings: {
            'white': OpeningTrack(lessonId: 'white', startedOn: '2026-10-28'),
            'black': OpeningTrack(lessonId: 'black', startedOn: '2026-10-28'),
          },
        ),
      },
      content: {
        TrainingCourse.pilares: TrainingResources(
          openings: {
            'white': [first, second],
            'black': [black],
          },
        ),
      },
    );
    cubit = create();
    await cubit.load(lessonId: 'white');
  });
  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('validates full exported line and begins at initial position', () {
    expect(cubit.state.fen, GameRules.initial.fen);
    expect(cubit.state.line!.san, ['e4', 'e5', 'Nf3']);
    expect(
      () => PlayTrainingOpening(
        OpeningTrecho(id: 'bad', title: '', moves: ['e2e5']),
      ),
      throwsFormatException,
    );
    expect(
      () =>
          PlayTrainingOpening(OpeningTrecho(id: 'empty', title: '', moves: [])),
      throwsFormatException,
    );
  });
  test(
    'wrong and illegal moves restore position and count once per student move',
    () async {
      final fen = cubit.state.fen;
      await cubit.play('d2d4');
      await cubit.play('e2e5');
      expect(cubit.state.fen, fen);
      expect(cubit.state.cursor, 0);
      expect(cubit.state.wrong, true);
      await cubit.play('e2e4');
      expect(cubit.state.cursor, 2);
      expect(cubit.state.firstTry, [false]);
      await cubit.play('g1f3');
      expect(cubit.state.firstTry, [false, true]);
      final saved = await repository.load(TrainingCourse.pilares);
      expect(saved.openings['white']!.firstTry['t1'], [false, true]);
      expect(saved.day!.allDone, false);
    },
  );
  test('hint affects only the current first-try result', () async {
    await cubit.hint();
    await cubit.play('e2e4');
    await cubit.play('g1f3');
    expect(cubit.state.firstTry, [false, true]);
  });
  test(
    'review blocks play and hint until returning to current position',
    () async {
      await cubit.play('e2e4');
      cubit.review(1);
      expect(cubit.state.reviewing, true);
      final fen = cubit.state.fen;
      await cubit.play('g1f3');
      await cubit.hint();
      expect(cubit.state.cursor, 2);
      expect(cubit.state.fen, fen);
      expect(cubit.state.hint, false);
      cubit.review(0);
      expect(cubit.state.fen, GameRules.initial.fen);
      cubit.review(3);
      expect(cubit.state.shown, 0);
      cubit.review(2);
      await cubit.play('g1f3');
      expect(cubit.state.phase, TrainingOpeningPhase.complete);
    },
  );
  test(
    'black automatically plays white, next means a different opening',
    () async {
      await cubit.play('e2e4');
      await cubit.play('g1f3');
      expect(await cubit.nextOpening(), true);
      expect(cubit.state.lessonId, 'black');
      expect(cubit.state.cursor, 1);
      expect(cubit.state.fen, PlayTrainingOpening(black).fens[1]);
      await cubit.play('d7d5');
      expect(cubit.state.firstTry, [true]);
      expect(await cubit.nextOpening(), false);
      expect(cubit.state.saved!.day!.allDone, true);
      expect(
        cubit.state.saved!.openings['white']!.doneTrechos.containsKey('t2'),
        false,
      );
    },
  );
  test('interrupted opening restarts the same frozen segment', () async {
    await cubit.play('e2e4');
    final restart = create();
    await restart.load(lessonId: 'white');
    expect(restart.state.cursor, 0);
    expect(restart.state.trecho!.id, 't1');
    expect(restart.state.firstTry, isEmpty);
    await restart.close();
  });
  test(
    'does not navigate or report complete until disk write resolves',
    () async {
      await cubit.play('e2e4');
      final disk = Completer<void>();
      repository.beforeSave = disk.future;
      final pending = cubit.play('g1f3');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.phase, TrainingOpeningPhase.saving);
      expect(await cubit.nextOpening(), false);
      disk.complete();
      await pending;
      expect(cubit.state.phase, TrainingOpeningPhase.complete);
    },
  );
  test('disk failure keeps attempts and retry persists once', () async {
    repository.writeError = StateError('disk');
    await cubit.play('e2e4');
    await cubit.play('g1f3');
    expect(cubit.state.error, true);
    expect(cubit.state.phase, TrainingOpeningPhase.saving);
    expect(cubit.state.firstTry, [true, true]);
    repository.writeError = null;
    await cubit.save();
    expect(cubit.state.phase, TrainingOpeningPhase.complete);
    expect(repository.writes, 1);
  });
  test('midnight expires with no infinite retry or result recorded', () async {
    await cubit.play('e2e4');
    now.value = DateTime(2026, 10, 30);
    await cubit.play('g1f3');
    expect(cubit.state.phase, TrainingOpeningPhase.expired);
    await cubit.save();
    expect(cubit.state.phase, TrainingOpeningPhase.expired);
    expect(
      (await repository.load(TrainingCourse.pilares))
          .openings['white']!
          .firstTry,
      isEmpty,
    );
  });
  for (final useHint in [false, true]) {
    test(
      'persisted ${useHint ? 'hint' : 'mistake'} survives JSON and restart',
      () async {
        if (useHint) {
          await cubit.hint();
        } else {
          await cubit.play('d2d4');
          await cubit.play('d2d4');
        }
        final disk = await repository.load(TrainingCourse.pilares);
        expect(disk.openings['white']!.pendingMistakes['t1'], [0]);
        final jsonRoundTrip = TrainingState.fromJson(disk.toJson());
        expect(jsonRoundTrip.openings['white']!.pendingMistakes['t1'], [0]);
        final restarted = create();
        await restarted.load(lessonId: 'white');
        expect(restarted.state.cursor, 0);
        await restarted.play('e2e4');
        await restarted.play('g1f3');
        final stored = await repository.load(TrainingCourse.pilares);
        expect(stored.openings['white']!.firstTry['t1'], [false, true]);
        expect(
          stored.openings['white']!.pendingMistakes.containsKey('t1'),
          false,
        );
        await restarted.close();
      },
    );
    test(
      '${useHint ? 'hint' : 'mistake'} disk failure blocks new moves until retry',
      () async {
        repository.writeError = StateError('disk');
        if (useHint) {
          await cubit.hint();
        } else {
          await cubit.play('d2d4');
        }
        expect(cubit.state.phase, TrainingOpeningPhase.mistakeSaving);
        expect(cubit.state.error, true);
        expect(cubit.state.hint, false);
        await cubit.play('e2e4');
        expect(cubit.state.cursor, 0);
        expect(
          (await repository.load(TrainingCourse.pilares))
              .openings['white']!
              .pendingMistakes,
          isEmpty,
        );
        repository.writeError = null;
        await cubit.retry();
        expect(cubit.state.phase, TrainingOpeningPhase.playing);
        expect(cubit.state.hint, useHint);
        await cubit.play('e2e4');
        await cubit.play('g1f3');
        expect(cubit.state.firstTry, [false, true]);
      },
    );
  }
  test(
    'hint is revealed only after durable mark and concurrent calls are ignored',
    () async {
      final disk = Completer<void>();
      repository.beforeSave = disk.future;
      final pending = cubit.hint();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.phase, TrainingOpeningPhase.mistakeSaving);
      expect(cubit.state.hint, false);
      await cubit.hint();
      await cubit.play('e2e4');
      expect(cubit.state.cursor, 0);
      disk.complete();
      await pending;
      expect(cubit.state.hint, true);
      expect(repository.writes, 1);
      await cubit.hint();
      expect(repository.writes, 1);
    },
  );
  test('completion merges another instance marks and preserves other segments and tracks', () async {
    await repository.update(
      TrainingCourse.pilares,
      (s) => s.copyWith(
        openings: {
          ...s.openings,
          'white': s.openings['white']!.withMistake('t2', 0),
          'black': s.openings['black']!.withMistake('b1', 0),
        },
      ),
    );
    final other = create();
    await other.load(lessonId: 'white');
    await other.play('e2e4');
    await other.hint();
    await cubit.play('e2e4');
    await cubit.play('g1f3');
    final stored = await repository.load(TrainingCourse.pilares);
    expect(stored.openings['white']!.firstTry['t1'], [true, false]);
    expect(cubit.state.firstTry, [true, false]);
    expect(stored.openings['white']!.pendingMistakes, {
      't2': [0],
    });
    expect(stored.openings['black']!.pendingMistakes, {
      'b1': [0],
    });
    expect(stored.openings['white']!.startedOn, '2026-10-28');
    await other.close();
  });
  test('pending marks are immutable and older JSON defaults to empty', () {
    final source = <String, List<int>>{
      't1': [0],
    };
    final track = OpeningTrack(
      lessonId: 'white',
      startedOn: 'date',
      pendingMistakes: source,
    );
    source['t1']!.add(1);
    expect(track.pendingMistakes['t1'], [0]);
    expect(() => track.pendingMistakes['t1']!.add(1), throwsUnsupportedError);
    expect(() => track.pendingMistakes['t2'] = [1], throwsUnsupportedError);
    final legacy = Map<String, dynamic>.from(track.toJson())
      ..remove('pendingMistakes');
    expect(OpeningTrack.fromJson(legacy).pendingMistakes, isEmpty);
  });
  test(
    'day off and following study day retain unfinished segment penalties',
    () async {
      await cubit.hint();
      now.value = DateTime(2026, 10, 31, 12);
      await cubit.load();
      expect(cubit.state.saved!.day!.studyDay, false);
      expect(cubit.state.saved!.openings['white']!.pendingMistakes['t1'], [0]);
      now.value = DateTime(2026, 11, 2, 12);
      await cubit.load();
      expect(cubit.state.saved!.day!.studyDay, true);
      expect(cubit.state.saved!.openings['white']!.pendingMistakes['t1'], [0]);
      expect(cubit.state.saved!.openings['white']!.doneTrechos, isEmpty);
    },
  );
  test(
    'list derives availability from frozen aggregate and daily completion',
    () async {
      await cubit.load();
      expect(cubit.state.pending, ['white', 'black']);
      expect(cubit.state.goal!.items['white'], 't1');
      final player = create();
      await player.load(lessonId: 'white');
      await player.play('e2e4');
      await player.play('g1f3');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.pending, ['black']);
      expect(cubit.state.saved!.openings['white']!.firstTry['t1'], [
        true,
        true,
      ]);
      await player.close();
    },
  );
}
