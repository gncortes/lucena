import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/goal/tournament_record.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/training_goal/view_models/training_goal_cubit.dart';
import 'package:lucena/ui/training_goal/widgets/training_tournaments_screen.dart';
import 'package:lucena/ui/training_goal/widgets/training_week_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/motion_expectations.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../domain/use_cases/training/goal/goal_rules_test.dart' show course;

/// H-ANI-17: Meus torneios (PropV2DestinoMeusTorneios) e a Semana
/// (PropV2DestinoSemana) entram linha a linha na primeira carga. Sem
/// animações, tudo pronto.
void main() {
  TrainingResources comBanco() {
    final base = course(chapters: 30);
    return TrainingResources(
      lessons: base.lessons,
      banks: {
        for (final l in base.lessons)
          l.id: [
            TrainingExercise(
              id: '${l.id}.e1',
              stars: 1,
              fen: GameRules.initial.fen,
              solution: const ['e2e4'],
              mock: true,
            ),
          ],
      },
    );
  }

  Future<TrainingGoalCubit> cubitPronto() async {
    final repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: comBanco()},
    );
    final now = FakeNow(DateTime(2026, 11, 4, 10));
    final cubit = TrainingGoalCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: now,
      afterSave: (_) async {},
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    for (var i = 1; i <= 3; i++) {
      now.advance(const Duration(minutes: 1));
      expect(
        await cubit.register(
          TournamentDraft(
            name: 'Aberto $i',
            date: '2026-10-0$i',
            points: '3',
            rounds: '5',
          ),
        ),
        isTrue,
      );
    }
    expect(
      await cubit.setObjective(
        kind: ObjectiveKind.tournament,
        date: '2027-01-10',
      ),
      isTrue,
    );
    expect(await cubit.chooseTest(), isTrue);
    for (var i = 0; i < 40; i++) {
      if (cubit.state.view!.state.diagnostic!.testComplete) break;
      await cubit.answerTest(false);
    }
    expect(await cubit.finish(), isTrue);
    return cubit;
  }

  Future<void> abre(
    WidgetTester tester,
    TrainingGoalCubit cubit,
    Widget tela, {
    required bool reduzido,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(412, 917),
            disableAnimations: reduzido,
          ),
          child: BlocProvider.value(value: cubit, child: tela),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> confereOrdem(
    WidgetTester tester, {
    required Key primeiraLinha,
    required bool reduzido,
  }) async {
    expect(
      find.descendant(
        of: find.byKey(MotionKeys.itemDaLista(0)),
        matching: find.byKey(primeiraLinha),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 40));
    final primeira = opacidadeDaParte(
      tester,
      find.byKey(MotionKeys.itemDaLista(0)),
    );
    final segunda = opacidadeDaParte(
      tester,
      find.byKey(MotionKeys.itemDaLista(1)),
    );
    if (reduzido) {
      expect(primeira, 1);
      expect(segunda, 1);
    } else {
      expect(segunda, lessThan(primeira));
    }
    await tester.pumpAndSettle();
    expect(opacidadeDaParte(tester, find.byKey(MotionKeys.itemDaLista(1))), 1);
  }

  for (final reduzido in [false, true]) {
    testWidgets('H-ANI-17: Meus torneios entram em ordem (reduzido: '
        '$reduzido)', (tester) async {
      late TrainingGoalCubit cubit;
      await tester.runAsync(() async => cubit = await cubitPronto());
      await abre(
        tester,
        cubit,
        TrainingTournamentsScreen(onBack: () {}, onRegister: () {}),
        reduzido: reduzido,
      );
      final maisRecente = cubit.state.view!.tournaments.reduce(
        (a, b) => a.date.compareTo(b.date) >= 0 ? a : b,
      );
      await confereOrdem(
        tester,
        primeiraLinha: TrainingGoalKeys.tournamentRow(maisRecente.id),
        reduzido: reduzido,
      );
    });

    testWidgets('H-ANI-17: os capítulos da Semana entram em ordem '
        '(reduzido: $reduzido)', (tester) async {
      late TrainingGoalCubit cubit;
      await tester.runAsync(() async => cubit = await cubitPronto());
      final semana = cubit.state.view!.plan!.weeks.indexWhere(
        (w) => w.chapterIds.length >= 2,
      );
      expect(semana, isNonNegative);
      await abre(
        tester,
        cubit,
        TrainingWeekScreen(week: semana, onBack: () {}, onChapter: (_) {}),
        reduzido: reduzido,
      );
      final primeiro = cubit.state.view!.plan!.weeks[semana].chapterIds.first;
      await confereOrdem(
        tester,
        primeiraLinha: TrainingGoalKeys.weekChapter(primeiro),
        reduzido: reduzido,
      );
    });
  }
}
