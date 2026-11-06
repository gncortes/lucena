import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/load_failure.dart';
import 'package:lucena/domain/models/training/goal/goal_undo.dart';
import 'package:lucena/domain/models/training/goal/study_plan.dart';
import 'package:lucena/domain/models/training/goal/tournament_record.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/training_goal/view_models/training_goal_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../domain/use_cases/training/goal/goal_rules_test.dart' show course;

// Contrato `docs/tasks/T85-contrato-torneio-meta.md`: G1, G2, G3, G7, G9, G10.

void main() {
  late FakeTrainingRepository repository;
  late FakeNow now;
  late int reminders;
  Object? reminderError;

  TrainingGoalCubit make() => TrainingGoalCubit(
    repository: repository,
    config: TrainingCourseConfig.pilares,
    now: now,
    afterSave: (_) async {
      reminders++;
      if (reminderError case final e?) throw e;
    },
  );

  TrainingState withPlan() => TrainingState(
    course: TrainingCourse.pilares,
    installSeed: 's',
    objective: const TrainingObjective(
      kind: ObjectiveKind.tournament,
      setOn: '2026-11-01',
      tournamentDate: '2026-12-14',
      tournamentName: 'Aberto',
    ),
    studyPlan: StudyPlan(createdOn: '2026-11-01', chapterIds: const ['x']),
    tournaments: const [
      TournamentRecord(
        id: 'a',
        name: 'Velho',
        date: '2026-10-11',
        tenthsPoints: 35,
        rounds: 5,
      ),
    ],
  );

  setUp(() {
    now = FakeNow(DateTime(2026, 11, 4, 10));
    reminders = 0;
    reminderError = null;
    repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: course()},
      states: {TrainingCourse.pilares: withPlan()},
    );
  });

  tearDown(() => repository.dispose());

  test('G1: ficar sem objetivo grava, e desfazer devolve tudo', () async {
    final cubit = make();
    await cubit.load();
    expect(await cubit.removeObjective(), isTrue);
    expect(cubit.view!.hasObjective, isFalse);
    expect(cubit.view!.canUndo, isTrue);
    expect(cubit.view!.undoKind, UndoKind.objectiveRemoved);
    expect(await cubit.undo(), isTrue);
    expect(cubit.view!.objective!.tournamentName, 'Aberto');
    expect(cubit.view!.hasPlan, isTrue);
    expect(cubit.view!.canUndo, isFalse);
    await cubit.close();
  });

  test('G3: reescolher o mesmo objetivo no dia seguinte não grava', () async {
    final cubit = make();
    await cubit.load();
    final before = repository.writes;
    expect(
      await cubit.setObjective(
        kind: ObjectiveKind.tournament,
        date: '2026-12-14',
        name: 'Aberto',
      ),
      isTrue,
    );
    expect(repository.writes, before);
    expect(cubit.view!.hasPlan, isTrue);
    await cubit.close();
  });

  test('G5: o nome segue para o objetivo, cortado em 60', () async {
    final cubit = make();
    await cubit.load();
    expect(await cubit.renameObjective('z' * 200), isTrue);
    expect(cubit.view!.tournamentName.length, 60);
    expect(cubit.view!.hasPlan, isTrue);
    await cubit.close();
  });

  test('G7: apagar e desfazer pelo view model', () async {
    final cubit = make();
    await cubit.load();
    expect(await cubit.deleteTournament('a'), isTrue);
    expect(cubit.view!.tournaments, isEmpty);
    expect(await cubit.undo(), isTrue);
    expect(cubit.view!.tournaments.single.id, 'a');
    await cubit.close();
  });

  test('G7: editar devolve false com campo inválido', () async {
    final cubit = make();
    await cubit.load();
    final draft = cubit.view!.editDraft('a');
    expect(
      await cubit.editTournament('a', draft.copyWith(rounds: '')),
      isFalse,
    );
    expect(
      await cubit.editTournament('a', draft.copyWith(name: 'Novo')),
      isTrue,
    );
    expect(cubit.view!.tournaments.single.name, 'Novo');
    await cubit.close();
  });

  group('G9: falha ao gravar com dados na tela', () {
    test('a tela fica com os dados e o aviso; tentar de novo grava', () async {
      final cubit = make();
      await cubit.load();
      repository.writeError = Exception('disco');
      expect(await cubit.removeObjective(), isFalse);
      expect(cubit.state.view, isNotNull);
      expect(cubit.state.failed, isFalse);
      expect(cubit.state.saveFailed, isTrue);
      expect(cubit.view!.hasObjective, isTrue);
      repository.writeError = null;
      expect(await cubit.retrySave(), isTrue);
      expect(cubit.state.saveFailed, isFalse);
      expect(cubit.view!.hasObjective, isFalse);
      await cubit.close();
    });

    test('sem espaço vira a falha noSpace', () async {
      final cubit = make();
      await cubit.load();
      repository.writeError = const FileSystemFull();
      await cubit.deleteTournament('a');
      expect(cubit.state.saveFailed, isTrue);
      expect(cubit.state.failure, isNot(LoadFailure.offline));
      cubit.dismissSaveError();
      expect(cubit.state.saveFailed, isFalse);
      await cubit.close();
    });
  });

  test('G10: falha no lembrete depois de gravar não vira erro', () async {
    final cubit = make();
    await cubit.load();
    reminderError = Exception('alarme');
    expect(await cubit.removeObjective(), isTrue);
    expect(reminders, 1);
    expect(cubit.state.saveFailed, isFalse);
    expect(cubit.state.failed, isFalse);
    expect(cubit.view!.hasObjective, isFalse);
    await cubit.close();
  });

  test('G10: registrar com lembrete quebrado devolve true', () async {
    final cubit = make();
    await cubit.load();
    reminderError = Exception('alarme');
    final ok = await cubit.register(
      const TournamentDraft(
        name: 'Copa',
        date: '2026-11-01',
        points: '3',
        rounds: '5',
      ),
    );
    expect(ok, isTrue);
    expect(cubit.view!.tournaments.first.name, 'Copa');
    await cubit.close();
  });
}

/// Erro qualquer só para o teste (o mapeamento fino é do [LoadFailure.of]).
final class FileSystemFull implements Exception {
  const FileSystemFull();
}
