import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/ui/journey/view_models/journey_cubit.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  Attempt played(String challengeId, int day, {required bool fulfilled}) =>
      Attempt(
        positionId: 'basic.queen.0001',
        playedAt: DateTime.utc(2026, 10, day),
        outcome: fulfilled ? AttemptOutcome.win : AttemptOutcome.loss,
        fulfilled: fulfilled,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        challengeId: challengeId,
      );

  test('lê os degraus com o que já foi concluído', () async {
    final cubit = JourneyCubit(
      FakeJourneyRepository(),
      FakeProgressRepository([
        played('1000/basic.queen.0001', 1, fulfilled: true),
        played('1000/basic.rook.0001', 2, fulfilled: false),
      ]),
    );
    addTearDown(cubit.close);

    await cubit.load();

    final progress = cubit.state.progress!;
    expect(progress.rungs.first.completed, {'1000/basic.queen.0001'});
    expect(progress.rungs[1].status, RungStatus.locked);
    expect(cubit.state.challenge, isNull);
  });

  test('na tela do desafio, traz o histórico dele do mais recente', () async {
    final cubit = JourneyCubit(
      FakeJourneyRepository(),
      FakeProgressRepository([
        played('1000/basic.queen.0001', 1, fulfilled: false),
        played('1000/basic.rook.0001', 2, fulfilled: true),
        played('1000/basic.queen.0001', 3, fulfilled: true),
      ]),
    );
    addTearDown(cubit.close);

    await cubit.load(rungId: '1000', positionId: 'basic.queen.0001');

    expect(cubit.state.challenge!.id, '1000/basic.queen.0001');
    expect(cubit.state.attempts.map((a) => a.playedAt.day), [3, 1]);
  });

  test('o ex-aluno do Viktor recebe a fala do reencontro', () async {
    Future<String?> reunion(SchoolProgress school) async {
      final cubit = JourneyCubit(
        FakeJourneyRepository(),
        FakeProgressRepository(),
        school: FakeSchoolProgressRepository(school),
        lessons: FakeLessonRepository(
          texts: LessonTexts.fromJson({'journey.reunion': 'You came back.'}),
        ),
      );
      addTearDown(cubit.close);
      await cubit.load();
      return cubit.state.reunion;
    }

    expect(await reunion(const SchoolProgress()), isNull);
    expect(
      await reunion(const SchoolProgress(completed: {'pieces.rook'})),
      'You came back.',
    );
  });
}
