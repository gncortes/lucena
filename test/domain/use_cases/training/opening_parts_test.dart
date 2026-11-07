import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/use_cases/training/opening_trecho_rules.dart';
import 'package:lucena/domain/use_cases/training/play_training_opening.dart';

import '../../../../testing/fakes/fake_now.dart';

void main() {
  test('part rewinds to common prefix and asks shared student moves once', () {
    final part = OpeningTrecho(
      id: 'part-1',
      title: 'Opening',
      lines: [
        ['e2e4', 'e7e5', 'g1f3'],
        ['e2e4', 'c7c5', 'g1f3'],
      ],
    );
    final play = PlayTrainingOpening(part);
    expect(play.studentMoves, 3);
    var step = play.play(play.initialCursor, 'e2e4');
    expect(step.correct, true);
    step = play.play(step.cursor, 'g1f3');
    expect(play.fens[step.cursor].split(' ')[1], 'w');
    expect(play.san.where((s) => s == 'e4').length, 1);
    step = play.play(step.cursor, 'g1f3');
    expect(play.isComplete(step.cursor), true);
    expect(play.notationIndices(step.cursor).map((i) => play.san[i]), [
      'e4',
      'c5',
      'Nf3',
    ]);
  });

  test('all parts completed chooses lowest first-try accuracy for review', () {
    final now = FakeNow(DateTime(2026, 10, 30));
    final bank = [
      for (var i = 1; i <= 3; i++)
        OpeningTrecho(id: 'p$i', title: 'Part', moves: ['e2e4']),
    ];
    final track = OpeningTrack(
      lessonId: 'opening',
      startedOn: '2026-10-01',
      doneTrechos: {'p1': '2026-10-25', 'p2': '2026-10-28', 'p3': '2026-10-29'},
      firstTry: {
        'p1': [true],
        'p2': [false],
        'p3': [true, false],
      },
    );
    expect(OpeningTrechoRules(now).next(track, bank)?.id, 'p2');
  });

  test('part serialization retains all lines and repertoire', () {
    final part = OpeningTrecho(
      id: 'p1',
      title: 'Opening',
      openingId: 'test',
      profile: 'solido',
      lines: [
        ['e2e4'],
      ],
    );
    final restored = OpeningTrecho.fromJson(part.toJson());
    expect(restored.lines, part.lines);
    expect(restored.profile, 'solido');
    expect(restored.openingId, 'test');
  });
}
