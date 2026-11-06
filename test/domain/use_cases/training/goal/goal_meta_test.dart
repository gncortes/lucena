import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/goal/goal_undo.dart';
import 'package:lucena/domain/models/training/goal/study_plan.dart';
import 'package:lucena/domain/models/training/goal/tournament_record.dart';
import 'package:lucena/domain/models/training/goal/training_diagnostic.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/goal/goal_actions.dart';
import 'package:lucena/domain/use_cases/training/goal/goal_limits.dart';
import 'package:lucena/domain/use_cases/training/goal/goal_view.dart';
import 'package:lucena/domain/use_cases/training/goal/tournament_rules.dart';

import 'goal_rules_test.dart' show course;

// Contrato `docs/tasks/T85-contrato-torneio-meta.md`, gaps G1–G8 e limites (§8).

const today = '2026-11-04';

TrainingState base() =>
    TrainingState(course: TrainingCourse.pilares, installSeed: 's');

TrainingObjective tournament(
  String date, {
  String setOn = today,
  String name = '',
}) => TrainingObjective(
  kind: ObjectiveKind.tournament,
  setOn: setOn,
  tournamentDate: date,
  tournamentName: name,
);

const improve = TrainingObjective(kind: ObjectiveKind.improve, setOn: today);

final plan = StudyPlan(createdOn: today, chapterIds: const ['c1', 'c2']);
final oldPlan = StudyPlan(createdOn: '2026-10-01', chapterIds: const ['c9']);

TournamentRecord record(String id, {String date = '2026-10-11'}) =>
    TournamentRecord(
      id: id,
      name: 'Aberto $id',
      date: date,
      tenthsPoints: 35,
      rounds: 5,
    );

TournamentDraft draft({
  String name = 'Aberto',
  String date = '2026-10-28',
  String points = '4,5',
  String rounds = '7',
  String notes = '',
}) => TournamentDraft(
  name: name,
  date: date,
  points: points,
  rounds: rounds,
  notes: notes,
);

/// Torneio com plano, teste concluído, um registro e um rascunho.
TrainingState planned() => base().copyWith(
  objective: tournament('2026-12-14', name: 'Aberto de Jundiaí'),
  studyPlan: plan,
  previousStudyPlan: oldPlan,
  diagnostic: TrainingDiagnostic(
    method: DiagnosticMethod.test,
    testChapterIds: const ['c1'],
    testAnswers: const [true],
    finished: true,
  ),
  tournamentPushFor: '2026-12-14',
  tournaments: [record('a')],
  tournamentDraft: const TournamentDraft(points: '3'),
);

String json(TrainingState s) => jsonEncode(s.toJson());

TrainingState roundTrip(TrainingState s) => TrainingState.fromJson(
  jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
);

void main() {
  group('G1: ficar sem objetivo', () {
    test('tira objetivo e plano; histórico +1; registros e rascunho ficam', () {
      final before = planned();
      final s = clearObjective(before);
      expect(s.objective, isNull);
      expect(s.studyPlan, isNull);
      expect(s.previousStudyPlan, isNull);
      expect(s.tournamentPushFor, isNull);
      expect(s.objectiveHistory.single.tournamentName, 'Aberto de Jundiaí');
      expect(s.tournaments.single.id, 'a');
      expect(s.tournamentDraft!.points, '3');
      expect(tournamentPush(s, DateTime(2026, 11, 4, 12)), isNull);
    });

    test('Pergunta 3: o teste de nível concluído fica', () {
      final s = clearObjective(planned());
      expect(s.diagnostic!.finished, isTrue);
    });

    test('Pergunta 3: teste pela metade é descartado', () {
      final s = clearObjective(
        planned().copyWith(
          diagnostic: TrainingDiagnostic(
            method: DiagnosticMethod.test,
            testChapterIds: const ['c1', 'c2'],
            testAnswers: const [true],
          ),
        ),
      );
      expect(s.diagnostic, isNull);
    });

    test('desfazer devolve o estado igual ao de antes', () {
      final before = planned();
      final undone = undoLast(clearObjective(before));
      expect(json(undone), json(before));
      expect(undone.undoSlot, isNull);
    });

    test('sem objetivo, tirar não grava', () {
      final s = base();
      expect(identical(clearObjective(s), s), isTrue);
    });

    test('a Guia volta ao vazio', () {
      final view = GoalView.of(clearObjective(planned()), course(), today);
      expect(view.hasObjective, isFalse);
      expect(view.offersRegisterTournament, isFalse);
    });
  });

  group('G2: trocar com desfazer', () {
    test('trocar a data seguida de desfazer devolve plano e diagnóstico', () {
      final before = planned();
      final changed = applyObjective(before, tournament('2026-12-20'));
      expect(changed.studyPlan, isNull);
      expect(changed.undoSlot!.kind, UndoKind.objectiveChanged);
      final undone = undoLast(changed);
      expect(json(undone), json(before));
    });

    test('a troca guarda o teste de nível concluído (Pergunta 3)', () {
      final changed = applyObjective(planned(), improve);
      expect(changed.diagnostic!.finished, isTrue);
      expect(changed.previousStudyPlan, isNull);
    });

    test('primeira escolha não oferece desfazer', () {
      expect(applyObjective(base(), improve).undoSlot, isNull);
    });

    test('com plano, trocar pede confirmação; só o nome, não', () {
      final view = GoalView.of(planned(), course(), today);
      expect(
        view.changeFor(kind: ObjectiveKind.tournament, date: '2026-12-20'),
        ObjectiveChange.change,
      );
      expect(
        view.confirmChange(kind: ObjectiveKind.tournament, date: '2026-12-20'),
        isTrue,
      );
      expect(
        view.changeFor(
          kind: ObjectiveKind.tournament,
          date: '2026-12-14',
          name: 'Outro nome',
        ),
        ObjectiveChange.rename,
      );
      expect(
        view.changeFor(
          kind: ObjectiveKind.tournament,
          date: '2026-12-14',
          name: 'Aberto de Jundiaí',
        ),
        ObjectiveChange.none,
      );
      expect(view.confirmRemove, isTrue);
    });

    test('sem plano, trocar não pede confirmação', () {
      final view = GoalView.of(
        base().copyWith(objective: improve),
        course(),
        today,
      );
      expect(
        view.confirmChange(kind: ObjectiveKind.tournament, date: '2026-12-20'),
        isFalse,
      );
      expect(view.confirmRemove, isFalse);
    });

    test('o desfazer vale até a próxima ação de objetivo ou registro', () {
      var s = deleteTournament(planned(), 'a')!;
      s = clearObjective(s);
      final undone = undoLast(s);
      expect(undone.objective, isNotNull);
      expect(undone.tournaments, isEmpty);
    });

    test('desfazer sem nada guardado não grava', () {
      final s = base();
      expect(identical(undoLast(s), s), isTrue);
    });
  });

  group('G3: reescolher o mesmo', () {
    test('mesma escolha no dia seguinte não apaga o plano nem grava', () {
      final s = planned();
      final again = applyObjective(
        s,
        tournament(
          '2026-12-14',
          setOn: '2026-11-05',
          name: 'Aberto de Jundiaí',
        ),
      );
      expect(identical(again, s), isTrue);
    });

    test('"Seu objetivo" abre com a escolha atual', () {
      final view = GoalView.of(planned(), course(), today);
      final choice = view.objectiveChoice;
      expect(choice.kind, ObjectiveKind.tournament);
      expect(choice.date, '2026-12-14');
      expect(choice.name, 'Aberto de Jundiaí');
    });

    test('sem objetivo, "Seu objetivo" abre em branco', () {
      final choice = GoalView.of(base(), course(), today).objectiveChoice;
      expect(choice.kind, isNull);
      expect(choice.date, isNull);
      expect(choice.name, '');
    });
  });

  group('G5: nome e data', () {
    test('mudar só o nome não refaz o plano nem oferece desfazer', () {
      final s = applyObjective(
        planned(),
        tournament('2026-12-14', name: 'Copa SP'),
      );
      expect(s.objective!.tournamentName, 'Copa SP');
      expect(s.studyPlan, isNotNull);
      expect(s.undoSlot, isNull);
      expect(s.objectiveHistory, isEmpty);
    });

    test('renomear corta em 60 e o lembrete usa o nome', () {
      final s = renameObjective(planned(), 'x' * 1000000);
      expect(s.objective!.tournamentName.length, maxTournamentName);
      final named = renameObjective(planned(), '  Copa SP ');
      final push = tournamentPush(named, DateTime(2026, 11, 4, 12));
      expect(push!.name, 'Copa SP');
    });

    test('renomear com o mesmo nome não grava', () {
      final s = planned();
      expect(identical(renameObjective(s, 'Aberto de Jundiaí'), s), isTrue);
    });

    test('nome do objetivo de 1 MB grava com 60', () {
      final s = applyObjective(
        base(),
        tournament('2026-12-14', name: 'y' * 1000000),
      );
      expect(s.objective!.tournamentName.length, 60);
    });
  });

  group('G6: registro e quando oferecer', () {
    test('com "melhorar", a data do registro aceita a semana passada', () {
      expect(draftError(draft(date: '2026-10-28'), today: today), isNull);
    });

    test('data futura ou de mais de 2 anos é recusada', () {
      expect(
        draftError(draft(date: '2026-11-05'), today: today),
        DraftError.date,
      );
      expect(
        draftError(draft(date: '2024-11-03'), today: today),
        DraftError.date,
      );
      expect(draftError(draft(date: '2024-11-04'), today: today), isNull);
      expect(draftError(draft(date: ''), today: today), DraftError.date);
      final range = registerDateRange(today);
      expect(range.first, '2024-11-04');
      expect(range.last, today);
    });

    test('torneio daqui a 10 dias: o rascunho nasce com hoje', () {
      expect(draftFromObjective(tournament('2026-11-14'), today).date, today);
    });

    test('torneio que já passou: o rascunho nasce com a data dele', () {
      expect(
        draftFromObjective(tournament('2026-11-01'), today).date,
        '2026-11-01',
      );
    });

    test('"Registrar torneio": melhorar e lista vazia', () {
      final view = GoalView.of(
        base().copyWith(objective: improve),
        course(),
        today,
      );
      expect(view.offersRegisterTournament, isTrue);
    });

    test('"Registrar torneio" some com torneio futuro e com lista cheia', () {
      final future = GoalView.of(
        base().copyWith(objective: tournament('2026-11-14')),
        course(),
        today,
      );
      expect(future.offersRegisterTournament, isFalse);
      final withList = GoalView.of(
        base().copyWith(objective: improve, tournaments: [record('a')]),
        course(),
        today,
      );
      expect(withList.offersRegisterTournament, isFalse);
    });

    test(
      '"Registrar torneio" volta quando o torneio passou e foi registrado',
      () {
        final view = GoalView.of(
          base().copyWith(
            objective: tournament('2026-11-01'),
            tournaments: [record('a', date: '2026-11-01')],
          ),
          course(),
          today,
        );
        expect(view.offersRegisterTournament, isTrue);
      },
    );

    test('torneio passado sem registro: só "Registrar desempenho"', () {
      final view = GoalView.of(
        base().copyWith(objective: tournament('2026-11-01')),
        course(),
        today,
      );
      expect(view.awaitingRegister, isTrue);
      expect(view.offersRegisterTournament, isFalse);
    });
  });

  group('G7: editar e apagar registro', () {
    test('editar troca os campos, mantém id e posição, e desfaz', () {
      final before = base().copyWith(tournaments: [record('b'), record('a')]);
      final edited = editTournament(
        before,
        'a',
        draft(name: 'Corrigido', points: '5', rounds: '9'),
        today: today,
      )!;
      expect(edited.tournaments.map((t) => t.id), ['b', 'a']);
      expect(edited.tournaments.last.name, 'Corrigido');
      expect(edited.tournaments.last.tenthsPoints, 50);
      expect(edited.undoSlot!.kind, UndoKind.tournamentEdited);
      expect(json(undoLast(edited)), json(before));
    });

    test('editar com campo inválido ou id que não existe devolve null', () {
      final s = base().copyWith(tournaments: [record('a')]);
      expect(editTournament(s, 'a', draft(points: ''), today: today), isNull);
      expect(editTournament(s, 'zz', draft(), today: today), isNull);
    });

    test('apagar tira da lista e desfazer devolve', () {
      final before = base().copyWith(
        objective: improve,
        tournaments: [record('a')],
      );
      final deleted = deleteTournament(before, 'a')!;
      expect(deleted.tournaments, isEmpty);
      expect(deleted.undoSlot!.kind, UndoKind.tournamentDeleted);
      expect(
        GoalView.of(deleted, course(), today).offersRegisterTournament,
        isTrue,
      );
      expect(json(undoLast(deleted)), json(before));
    });

    test(
      'apagar o registro do torneio do objetivo volta a pedir o registro',
      () {
        final s = deleteTournament(
          base().copyWith(
            objective: tournament('2026-11-01'),
            tournaments: [record('a', date: '2026-11-01')],
          ),
          'a',
        )!;
        expect(GoalView.of(s, course(), today).awaitingRegister, isTrue);
      },
    );

    test('o rascunho da edição sobrevive a fechar à força', () {
      var s = base().copyWith(tournaments: [record('a')]);
      s = saveTournamentEdit(s, 'a', draft(name: 'Meio caminho'));
      final back = roundTrip(s);
      final view = GoalView.of(back, course(), today);
      expect(view.editDraft('a').name, 'Meio caminho');
      expect(view.state.tournamentDraft, isNull);
    });

    test('sem rascunho, a edição abre com o registro salvo', () {
      final view = GoalView.of(
        base().copyWith(tournaments: [record('a')]),
        course(),
        today,
      );
      final d = view.editDraft('a');
      expect(d.name, 'Aberto a');
      expect(d.points, '3,5');
      expect(d.rounds, '5');
      expect(d.date, '2026-10-11');
    });
  });

  group('G8: descartar o rascunho', () {
    test('descartar limpa o rascunho e reabrir vem vazio', () {
      final s = discardTournamentDraft(
        saveTournamentDraft(
          base().copyWith(objective: improve),
          draft(points: '2'),
        ),
      );
      expect(s.tournamentDraft, isNull);
      expect(GoalView.of(s, course(), today).registerDraft.points, '');
    });

    test('rascunho inicial sem mudança não pede confirmação', () {
      final view = GoalView.of(
        base().copyWith(objective: improve),
        course(),
        today,
      );
      expect(view.draftChanged(view.registerDraft), isFalse);
      expect(
        view.draftChanged(view.registerDraft.copyWith(points: '1')),
        isTrue,
      );
    });
  });

  group('§8 limites', () {
    test('o 101º registro é recusado e nada antigo sai', () {
      final full = base().copyWith(
        tournaments: [for (var i = 0; i < 100; i++) record('$i')],
      );
      expect(registerTournament(full, draft(), 'novo', today: today), isNull);
      expect(GoalView.of(full, course(), today).tournamentsFull, isTrue);
    });

    test('nome do registro grava com 60; anotações com 500', () {
      final s = registerTournament(
        base(),
        draft(name: 'n' * 1000000, notes: 'a' * 900),
        'x',
        today: today,
      )!;
      expect(s.tournaments.single.name.length, maxTournamentName);
      expect(s.tournaments.single.notes.length, maxTournamentNotes);
    });

    test('mais de 30 rodadas é erro', () {
      expect(
        draftError(draft(points: '4', rounds: '31')),
        DraftError.roundsTooMany,
      );
      expect(draftError(draft(points: '4', rounds: '30')), isNull);
    });

    test('o histórico de objetivos guarda os 20 mais recentes', () {
      var s = base();
      for (var i = 0; i < 25; i++) {
        s = applyObjective(
          s,
          tournament('2027-01-${(i + 1).toString().padLeft(2, '0')}'),
        );
      }
      expect(s.objectiveHistory.length, maxObjectiveHistory);
      expect(s.objectiveHistory.first.tournamentDate, '2027-01-24');
    });
  });

  group('§9 persistência', () {
    test('a cópia do desfazer sobrevive a fechar à força', () {
      final before = planned();
      final back = roundTrip(clearObjective(before));
      expect(back.undoSlot!.kind, UndoKind.objectiveRemoved);
      expect(json(undoLast(back)), json(before));
    });

    test('a escolha não salva de "Seu objetivo" volta ao reabrir', () {
      var s = saveObjectiveDraft(
        planned(),
        const ObjectiveDraft(
          kind: ObjectiveKind.tournament,
          date: '2026-12-20',
          name: 'Copa',
        ),
      );
      final view = GoalView.of(roundTrip(s), course(), today);
      expect(view.objectiveChoice.date, '2026-12-20');
      expect(view.objectiveChoice.name, 'Copa');
      s = clearObjectiveDraft(s);
      expect(s.objectiveDraft, isNull);
    });

    test('gravar o objetivo limpa a escolha não salva', () {
      final s = applyObjective(
        saveObjectiveDraft(
          base(),
          const ObjectiveDraft(kind: ObjectiveKind.improve),
        ),
        improve,
      );
      expect(s.objectiveDraft, isNull);
    });

    test('cópia ilegível vira nula sem derrubar o estado', () {
      final raw = base().toJson()..['undoSlot'] = {'kind': 'xyz'};
      expect(TrainingState.fromJson(raw).undoSlot, isNull);
    });
  });
}
