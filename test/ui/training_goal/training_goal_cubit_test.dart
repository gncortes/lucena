import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/goal/training_diagnostic.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/goal/tournament_record.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/ui/training_goal/view_models/training_goal_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../domain/use_cases/training/goal/goal_rules_test.dart' show course;

void main() {
  late FakeTrainingRepository repository;
  late FakeNow now;
  late int saves;

  TrainingGoalCubit make() => TrainingGoalCubit(
    repository: repository,
    config: TrainingCourseConfig.pilares,
    now: now,
    afterSave: (_) async => saves++,
  );

  setUp(() {
    now = FakeNow(DateTime(2026, 11, 4, 10));
    saves = 0;
    repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: course()},
    );
  });

  test('sem objetivo, a tela convida a definir um', () async {
    final cubit = make();
    await cubit.load();
    expect(cubit.view!.hasObjective, isFalse);
    await cubit.close();
  });

  test('torneio de amanhã vale; hoje não vale', () async {
    final cubit = make();
    await cubit.load();
    expect(
      await cubit.setObjective(
        kind: ObjectiveKind.tournament,
        date: '2026-11-04',
      ),
      isFalse,
    );
    expect(
      await cubit.setObjective(
        kind: ObjectiveKind.tournament,
        date: '2026-11-05',
      ),
      isTrue,
    );
    expect(cubit.view!.objective!.tournamentDate, '2026-11-05');
    expect(saves, 1, reason: 'reagenda lembretes e o aviso do torneio');
    await cubit.close();
  });

  test('questionário até o plano, e o plano sobrevive a reabrir', () async {
    final cubit = make();
    await cubit.load();
    await cubit.setObjective(
      kind: ObjectiveKind.tournament,
      date: '2026-12-14',
    );
    await cubit.chooseQuestionnaire();
    await cubit.answerTopic('p1', TopicLevel.learning);
    await cubit.answerTopic('p2', TopicLevel.mastered);
    expect(await cubit.finish(), isTrue);
    expect(cubit.view!.plan, isNotNull);
    expect(cubit.view!.plan!.weeks, isNotEmpty);
    await cubit.close();

    final reopened = make();
    await reopened.load();
    expect(reopened.view!.plan!.weeks, isNotEmpty);
    await reopened.close();
  });

  test('rascunho do torneio é gravado a cada campo', () async {
    final cubit = make();
    await cubit.load();
    await cubit.saveDraft(const TournamentDraft(name: 'Aberto'));
    await cubit.saveDraft(const TournamentDraft(name: 'Aberto', points: '3'));
    await cubit.close();

    final reopened = make();
    await reopened.load();
    final draft = reopened.view!.state.tournamentDraft!;
    expect(draft.name, 'Aberto');
    expect(draft.points, '3');
    await reopened.close();
  });

  test('registrar recusa pontos acima das rodadas e aceita o válido', () async {
    final cubit = make();
    await cubit.load();
    await cubit.setObjective(
      kind: ObjectiveKind.tournament,
      date: '2026-11-05',
    );
    now.value = DateTime(2026, 11, 6, 10);
    await cubit.load();
    const bad = TournamentDraft(
      name: 'Aberto',
      date: '2026-11-05',
      points: '9',
      rounds: '5',
    );
    expect(await cubit.register(bad), isFalse);
    expect(cubit.view!.state.tournaments, isEmpty);
    expect(await cubit.register(bad.copyWith(points: '3.5')), isTrue);
    expect(cubit.view!.state.tournaments, hasLength(1));
    expect(cubit.view!.tournamentRegistered, isTrue);
    await cubit.close();
  });

  test(
    'dia perdido: aviso fica até a escolha, e manter limpa o aviso',
    () async {
      final cubit = make();
      await cubit.load();
      await cubit.setObjective(
        kind: ObjectiveKind.tournament,
        date: '2026-12-14',
      );
      await cubit.noteMissed();
      expect(cubit.view!.state.missedDayNoticeOn, '2026-11-04');
      await cubit.confirmMissedKeep();
      expect(cubit.view!.state.missedDayNoticeOn, isNull);
      await cubit.close();
    },
  );

  test('falha de gravação não deixa a tela seguir', () async {
    final cubit = make();
    await cubit.load();
    repository.writeError = StateError('disco cheio');
    expect(await cubit.setObjective(kind: ObjectiveKind.improve), isFalse);
    expect(cubit.view!.hasObjective, isFalse);
    await cubit.close();
  });
}
