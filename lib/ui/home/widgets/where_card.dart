import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/home_layout.dart';
import '../../../domain/models/race.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/position_board.dart';
import '../../endgames/widgets/endgame_ui.dart';
import '../../journey/view_models/journey_cubit.dart';
import '../../race/widgets/race_warm_up_screen.dart';
import '../../race/widgets/race_warm_up_sheet.dart';
import '../../journey/widgets/journey_ui.dart';
import '../../journey/widgets/journey_resume.dart';
import '../view_models/home_cubit.dart';
import '../../core/widgets/animated_progress.dart';

/// "Continuar": o adversário atual da Jornada, o progresso contra ele e o
/// próximo desafio, com o tabuleiro em miniatura.
class WhereCard extends StatelessWidget {
  const WhereCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    // Só aponta para um caminho em destaque na tela inicial.
    switch (state.continuePath) {
      case null:
        return const SizedBox.shrink();
      case HomePath.endgames || HomePath.forYou when state.endgame != null:
        return _EndgameCard(endgame: state.endgame!);
      case HomePath.learn when state.school != null:
        return _SchoolCard(school: state.school!);
      default:
        return _journey(context);
    }
  }

  Widget _journey(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final current = state.current;
    final next = state.next;
    final character = state.character;
    final onColor = colors.onSecondaryContainer;
    final done = current?.completed.length ?? 0;
    final total = current?.rung.challenges.length ?? 0;
    return Card(
      key: HomeKeys.whereCard,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (character != null) ...[
                  // O retrato voa até o cartão do adversário, na tela do
                  // desafio.
                  if (current != null)
                    Hero(
                      tag: opponentHeroTag(current.rung.id),
                      child: CharacterAvatar(
                        character: character,
                        size: CharacterAvatar.speech,
                      ),
                    )
                  else
                    CharacterAvatar(
                      character: character,
                      size: CharacterAvatar.speech,
                    ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (current != null)
                        Text(
                          l10n.journeyNowFacing,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: onColor,
                          ),
                        ),
                      Text(
                        current == null
                            ? l10n.homeWhereDone
                            : character?.name ??
                                  opponentRefLabel(l10n, current.rung.opponent),
                        key: HomeKeys.whereTitle,
                        style: context.bigNumber?.copyWith(color: onColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: AppSpacing.md),
              AnimatedProgress(
                value: total == 0 ? 0 : done / total,
                backgroundColor: colors.surface,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeWhereProgress(done, total),
                style: theme.textTheme.bodySmall?.copyWith(color: onColor),
              ),
            ],
            if (current != null && next != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  PositionBoard(
                    key: HomeKeys.whereBoard,
                    fen: next.position.fen,
                    size: 64,
                    heroTag: challengeBoardTag(next.id),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      endgameName(l10n, next.position.subcategory),
                      key: HomeKeys.whereNext,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    key: HomeKeys.whereContinue,
                    // A tela do desafio abre por cima desta, já com o
                    // desafio pronto: o tabuleiro e o retrato voam até ela.
                    onPressed: () => continueJourney(context, state),
                    child: Text(l10n.homeContinue),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
  final theme = RaceTheme.ofSubcategory(subcategory);
  final choice = await offerRaceWarmUp(
    context,
    opponent: opponent,
    endgame: endgameName(l10n, subcategory),
    theme: theme,
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
        theme: theme,
        // Vai direto à partida do desafio (o mesmo "Jogar" da tela dele:
        // escolhe o ritmo e abre); ela entra no lugar do aquecimento.
        onPlay: (context) =>
            unawaited(playChallenge(context, challenge, replace: true)),
      ),
    ),
  );
}

/// Para o iniciante: as aulas do Viktor vêm antes da Jornada.
class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.school});

  final SchoolSummary school;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final teacher = school.teacher;
    return Card(
      key: HomeKeys.schoolCard,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            if (teacher != null) ...[
              CharacterAvatar(character: teacher, size: CharacterAvatar.player),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeSchool,
                    style: context.cardTitle?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedProgress(
                    value: school.total == 0 ? 0 : school.done / school.total,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.schoolLessonsDone(school.done, school.total),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton(
              key: HomeKeys.schoolContinue,
              onPressed: () => school.ongoingLessonId == null
                  ? context.go(Routes.school)
                  : context.push(Routes.lessonScript(school.ongoingLessonId!)),
              child: Text(l10n.homeContinue),
            ),
          ],
        ),
      ),
    );
  }
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
      );
    }
    return Routes.endgameLesson(lessonId);
  }
}

/// A aula de final em andamento ou a próxima recomendada pelo roteiro.
/// Retoma o ponto salvo ou abre a apresentação da aula ainda não iniciada.
/// Com um exercício da vez, sua miniatura toma o lugar do retrato.
class _EndgameCard extends StatelessWidget {
  const _EndgameCard({required this.endgame});

  final EndgameSummary endgame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final teacher = endgame.teacher;
    final exerciseId = endgame.openExerciseId;
    final fen = endgame.exerciseFen;
    return Card(
      key: HomeKeys.endgameCard,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            if (fen != null && exerciseId != null) ...[
              PositionBoard(
                key: HomeKeys.endgameBoard,
                fen: fen,
                size: 64,
                heroTag: exerciseHeroTag(endgame.lessonId, exerciseId),
              ),
              const SizedBox(width: AppSpacing.md),
            ] else if (teacher != null) ...[
              CharacterAvatar(character: teacher, size: CharacterAvatar.player),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endgame.recommended ? l10n.homeForYou : l10n.homeEndgames,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    endgame.title,
                    key: HomeKeys.endgameTitle,
                    style: context.cardTitle?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  if (!endgame.recommended) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      endgame.where(l10n),
                      key: HomeKeys.endgameWhere,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: endgame.recommended ? 140 : double.infinity,
              ),
              child: FilledButton(
                key: HomeKeys.endgameContinue,
                // A posição vai junto, para a miniatura voar até o tabuleiro.
                onPressed: () => context.push(endgame.route, extra: fen),
                child: Text(
                  endgame.recommended
                      ? l10n.endgameLessonStart
                      : l10n.homeContinue,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
