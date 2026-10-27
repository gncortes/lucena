import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/l10n/l10n.dart';
import '../../journey/view_models/journey_cubit.dart';
import '../../journey/widgets/journey_resume.dart';
import '../../journey/widgets/journey_ui.dart';
import '../../race/widgets/race_warm_up_screen.dart';
import '../../race/widgets/race_warm_up_sheet.dart';
import '../view_models/home_cubit.dart';

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
