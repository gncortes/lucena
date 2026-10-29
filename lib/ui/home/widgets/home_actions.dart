import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_training_repository.dart'
    as course_training;
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/character.dart';
import '../../../domain/use_cases/training/home_course_card.dart';
import '../../../routing/routes.dart';
import '../../../routing/training_launch.dart';
import '../../../routing/training_goal_destination.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/l10n/l10n.dart';
import '../../journey/view_models/journey_cubit.dart';
import '../../journey/widgets/journey_resume.dart';
import '../../journey/widgets/journey_ui.dart';
import '../../race/widgets/race_warm_up_screen.dart';
import '../../race/widgets/race_warm_up_sheet.dart';
import '../../training_exercise/view_models/training_exercise_cubit.dart';
import '../../training_opening/view_models/training_opening_cubit.dart';
import '../view_models/home_cubit.dart';

Future<void> openTrainingCourse(
  BuildContext context,
  HomeTraining training, {
  Character? teacher,
}) async {
  final card = training.card;
  final course = training.config.course;
  final router = GoRouter.of(context);
  final line = training.openingLine;
  final exercise = training.exercise;
  final lesson = training.resources.lessons
      .where((l) => l.id == card.ref)
      .firstOrNull;
  final launch = teacher == null
      ? null
      : TrainingLaunch(
          title: lesson?.title ?? context.l10n.trainingOpeningsTitle,
          teacher: teacher,
          lessonPreview: training.lessonPreview,
          challenge: training.challenge,
          speedrun: training.speedrun,
          exercisePreview: exercise == null
              ? null
              : TrainingExerciseState(
                  phase: TrainingExercisePhase.playing,
                  exercise: exercise,
                  goal: card.goal,
                  fen: exercise.fen,
                  lastMove: exercise.lastMove,
                ),
          openingPreview: line == null
              ? null
              : TrainingOpeningState(
                  saved: training.state,
                  resources: training.resources,
                  lessonId: card.ref,
                  line: line,
                  cursor: line.initialCursor,
                  shown: line.initialCursor,
                ),
        );
  try {
    await context.read<course_training.TrainingRepository>().update(
      course,
      (s) => s.copyWith(
        tab:
            card.destination == HomeCourseDestination.lesson ||
                card.destination == HomeCourseDestination.lessonTab
            ? CourseGuideTab.lesson
            : CourseGuideTab.goals,
      ),
    );
    if (!context.mounted) return;
    unawaited(router.push('${Routes.training(course.name)}?origem=home'));
    if (card.destination == HomeCourseDestination.lessonTab) {
      return;
    }
    if (card.destination == HomeCourseDestination.trecho) {
      unawaited(router.push('${Routes.training(course.name)}/openings'));
    }
    final destination = switch (card.destination) {
      HomeCourseDestination.lesson => trainingLessonDestination(
        lesson!,
        origin: 'treino_home',
      ),
      HomeCourseDestination.exercise =>
        Uri.parse(Routes.trainingExercise(course.name, card.ref))
            .replace(queryParameters: {'goal': card.goal!.key, 'home': '1'})
            .toString(),
      HomeCourseDestination.trecho =>
        '${Routes.trainingOpening(course.name, card.ref)}?home=1',
      HomeCourseDestination.challenge => trainingChallengeDestination(
        card.goal!,
        course: course.name,
      )!,
      HomeCourseDestination.lessonTab => Routes.training(course.name),
    };
    unawaited(
      router.push(
        destination,
        extra: card.goal?.kind == GoalKind.stars ? null : launch,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.trainingExerciseSaveError)),
      );
    }
  }
}

/// O "Continuar" da Jornada: o desafio da vez de [state]. Antes da partida,
/// oferece o aquecimento com problemas (E1.31); sem a oferta, ou recusada,
/// segue direto para o desafio.
Future<void> continueJourney(BuildContext context, HomeState state) async {
  final current = state.current;
  final challenge = state.next;
  if (current == null || challenge == null) return;
  if (await savedJourneyGame(context, challenge) != null) {
    if (context.mounted) await context.push(Routes.freeBoard);
    return;
  }
  if (!context.mounted) return;
  final l10n = context.l10n;
  final character = state.character;
  final rung = current.rung.id;
  final position = challenge.position.id;
  final journey = JourneyState(challenge: challenge, characters: [?character]);
  final opponent =
      character?.name ?? opponentRefLabel(l10n, current.rung.opponent);
  final level = current.rung.opponent.level;
  final subcategory = challenge.position.subcategory;
  final router = GoRouter.of(context);
  final category = challenge.position.category;
  final choice = await offerRaceWarmUp(
    context,
    opponent: opponent,
    endgame: endgameName(l10n, subcategory),
    subcategory: subcategory,
    category: category,
    character: character,
  );
  if (choice == RaceOfferChoice.skip) {
    unawaited(
      router.push(Routes.journeyChallenge(rung, position), extra: journey),
    );
    return;
  }
  // A tela do desafio entra na pilha por baixo do aquecimento: a partida
  // que sai dele volta para ela, não para a Início.
  unawaited(
    router.push(Routes.journeyChallenge(rung, position), extra: journey),
  );
  unawaited(
    router.push(
      Routes.raceWarmUp,
      extra: RaceWarmUpArgs(
        opponent: opponent,
        character: character,
        level: level,
        subcategory: subcategory,
        category: category,
        // Vai direto à partida do desafio (o mesmo "Jogar" da tela dele:
        // escolhe o ritmo e abre); ela entra no lugar do aquecimento.
        onPlay: (context) =>
            unawaited(playChallenge(context, challenge, replace: true)),
      ),
    ),
  );
}

/// Onde a aula parou e para onde o "Continuar" leva.
extension EndgameSummaryUi on EndgameSummary {
  String where(AppLocalizations l10n) {
    final exercise = exerciseNumber;
    if (exercise != null) {
      return l10n.exerciseTitle(exercise, exerciseCount!);
    }
    final part = partNumber;
    if (part != null) return l10n.homeEndgamePart(part, partCount!);
    return l10n.endgameScore(score, maxScore);
  }

  String get route {
    final exerciseId = openExerciseId;
    if (exerciseId != null) {
      return Routes.endgameExercise(lessonId, exerciseId);
    }
    if (lessonOpen) {
      return Routes.endgameLessonScript(
        lessonId,
        part: partId,
        stage: partStage,
        origin: 'home',
      );
    }
    return Routes.endgameLesson(lessonId, origin: 'home');
  }
}
