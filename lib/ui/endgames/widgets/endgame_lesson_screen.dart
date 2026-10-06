import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/endgame_lesson_cubit.dart';
import 'endgame_ui.dart';
import 'stars_row.dart';

/// Uma aula de final em três partes: a lição, os exercícios com as estrelas
/// e, liberado pela nota, o final de verdade (speedrun ou treino).
class EndgameLessonScreen extends StatelessWidget {
  const EndgameLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<EndgameLessonCubit, EndgameLessonState>(
      builder: (context, state) {
        final lesson = state.lesson;
        return Scaffold(
          key: EndgameLessonKeys.screen,
          // O número e o título da aula, que pode ser longo, vêm no corpo.
          appBar: AppBar(
            actions: [
              if (lesson != null)
                IconButton(
                  key: EndgameLessonKeys.infoButton,
                  icon: const Icon(Icons.info_outline),
                  tooltip: l10n.endgameInfoTooltip,
                  onPressed: () => context.push(Routes.endgameInfo(lesson.id)),
                ),
            ],
          ),
          body: !state.ready
              ? const SizedBox.shrink()
              : state.missing || lesson == null
              ? Center(
                  child: Text(
                    l10n.lessonMissing,
                    key: EndgameLessonKeys.missing,
                  ),
                )
              : _Body(state: state, lesson: lesson),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.lesson});

  final EndgameLessonState state;
  final EndgameLesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final viktor = state.viktor;
    final texts = state.texts;
    final speech = state.passed
        ? texts.say('endgames.lesson.passed')
        : state.allSolved
        ? texts.say('endgames.lesson.failed')
        : texts.say('endgames.lesson.intro');
    return ListView(
      padding: scrollPadding(context, left: 16, top: 8, right: 16, bottom: 32),
      children: [
        Text(
          l10n.lessonNumber(state.lessonNumber, state.lessonCount),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texts.lessonTitle(lesson.id),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (viktor != null)
          TeacherSpeech(
            teacher: viktor,
            text: speech,
            emotion: state.passed ? Emotion.happy : Emotion.calm,
            avatarSize: 64,
            bubbleKey: EndgameLessonKeys.speech,
          ),
        const SizedBox(height: 8),
        Text(
          texts.lessonSummary(lesson.id) ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _Part(number: 1, title: l10n.endgameLessonPartLesson),
        _LessonCard(state: state, lesson: lesson),
        _Part(number: 2, title: l10n.endgameLessonPartExercises),
        _ExercisesCard(state: state, lesson: lesson),
        _Part(number: 3, title: l10n.endgameLessonPartFinal),
        _FinalCard(state: state, lesson: lesson),
      ],
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 24, 4, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.primary,
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.state, required this.lesson});

  final EndgameLessonState state;
  final EndgameLesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final done = state.progress.lessonDone;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.menu_book_outlined,
                    color: done ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      done
                          ? l10n.endgameLessonDone
                          : l10n.lessonStep(1, lesson.lesson.steps.length),
                      key: done ? EndgameLessonKeys.lessonDone : null,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              key: EndgameLessonKeys.lessonButton,
              onPressed: () =>
                  context.push(Routes.endgameLessonSteps(lesson.id)),
              child: Text(
                done
                    ? l10n.endgameLessonReview
                    : state.lessonOngoing
                    ? l10n.endgameLessonContinue
                    : l10n.endgameLessonStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisesCard extends StatelessWidget {
  const _ExercisesCard({required this.state, required this.lesson});

  final EndgameLessonState state;
  final EndgameLesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final next = state.nextExercise;
    final cubit = context.read<EndgameLessonCubit>();
    return Column(
      key: EndgameLessonKeys.exercises,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, exercise) in lesson.exercises.indexed)
          _ExerciseTile(
            index: index,
            exercise: exercise,
            earned: state.starsOf(exercise.id),
            isNext: next?.id == exercise.id,
          ),
        const SizedBox(height: 8),
        // A nota: as estrelas ganhas sobre o total, e o mínimo.
        Card(
          key: EndgameLessonKeys.score,
          margin: EdgeInsets.zero,
          color: state.allSolved
              ? (state.passed ? colors.primaryContainer : colors.errorContainer)
              : colors.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.allSolved)
                  Text(
                    state.passed
                        ? l10n.endgamePassedTitle
                        : l10n.endgameFailedTitle,
                    key: state.passed
                        ? EndgameLessonKeys.passed
                        : EndgameLessonKeys.failed,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(l10n.endgameScore(state.score, state.maxScore)),
                Text(
                  '${l10n.endgameScoreMinimum(state.passScore)} · '
                  '${l10n.endgameExercisesSolved(state.solved, state.exerciseCount)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (next != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          state.solved == 0
                              ? l10n.endgameExercisesStart
                              : l10n.endgameExercisesContinue,
                        ),
                        onPressed: () => context.push(
                          Routes.endgameExercise(lesson.id, next.id),
                        ),
                      ),
                    if (state.solved > 0)
                      OutlinedButton.icon(
                        key: EndgameLessonKeys.redoButton,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.endgameRedoExercises),
                        onPressed: cubit.redoExercises,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.index,
    required this.exercise,
    required this.earned,
    required this.isNext,
  });

  final int index;
  final Exercise exercise;
  final int? earned;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final lessonId = context.read<EndgameLessonCubit>().state.lesson!.id;
    return Card(
      key: EndgameLessonKeys.exercise(exercise.id),
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: isNext ? colors.surfaceContainerHigh : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        dense: true,
        onTap: () =>
            context.push(Routes.endgameExercise(lessonId, exercise.id)),
        leading: SizedBox(
          width: 44,
          height: 44,
          child: PositionBoard(
            fen: exercise.fen,
            size: 44,
            radius: 4,
            heroTag: exerciseHeroTag(lessonId, exercise.id),
          ),
        ),
        title: Text(l10n.endgameExerciseTitle(index + 1)),
        subtitle: Text(l10n.endgameStars(exercise.stars)),
        trailing: Semantics(
          label: earned == null
              ? l10n.endgameStars(exercise.stars)
              : l10n.endgameEarnedStars(earned!, exercise.stars),
          excludeSemantics: true,
          child: StarsRow(
            key: EndgameLessonKeys.exerciseStars(exercise.id),
            total: exercise.stars,
            earned: earned,
          ),
        ),
      ),
    );
  }
}

/// O passo final: o speedrun do final (com o ritmo) e o treino na posição.
class _FinalCard extends StatefulWidget {
  const _FinalCard({required this.state, required this.lesson});

  final EndgameLessonState state;
  final EndgameLesson lesson;

  @override
  State<_FinalCard> createState() => _FinalCardState();
}

class _FinalCardState extends State<_FinalCard> {
  TimeControl _pace = SpeedrunPaces.standard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = widget.state;
    final lesson = widget.lesson;
    final practice = lesson.practice;
    if (!state.passed) {
      return Card(
        key: EndgameLessonKeys.finalLocked,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: colors.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.endgameFinalLocked,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final speedrun = state.speedrun;
    return Card(
      key: EndgameLessonKeys.finalStep,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PositionBoard(fen: practice.fen, size: 96, radius: 6),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.texts.say('${lesson.id}.practice') ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (speedrun != null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.endgameSpeedrunBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final time in SpeedrunPaces.all)
                    ChoiceChip(
                      key: EndgameLessonKeys.pace(time.code),
                      avatar: Icon(paceIcon(PaceCategory.of(time)), size: 16),
                      showCheckmark: false,
                      label: Text(paceShort(l10n, time)),
                      selected: time == _pace,
                      onSelected: (_) => setState(() => _pace = time),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: EndgameLessonKeys.speedrunButton,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.timer_outlined),
                label: Text(l10n.endgameSpeedrunChallenge),
                onPressed: () => context.push(
                  Routes.speedrun(SpeedrunPaces.idFor(speedrun.id, _pace)),
                ),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: EndgameLessonKeys.trainButton,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.fitness_center),
              label: Text(l10n.endgameTrain),
              onPressed: () => context.push(
                Routes.setup(
                  practice.fen,
                  goal: practice.goal.code,
                  position: practice.positionId,
                ),
              ),
            ),
            if (state.nextLesson case final next?) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: EndgameLessonKeys.nextLessonButton,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l10n.lessonNext(state.texts.lessonTitle(next))),
                onPressed: () =>
                    context.pushReplacement(Routes.endgameLesson(next)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
