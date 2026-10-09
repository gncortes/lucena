import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
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

  /// A fala curta do Viktor, conforme onde o aluno está: o convite para a
  /// primeira parte, onde parou, o teste final ou o final de verdade.
  String? _speech() {
    final texts = state.texts;
    final intro = texts.say('endgames.lesson.intro');
    if (state.passed) return texts.say('endgames.lesson.passed');
    if (state.allSolved) return texts.say('endgames.lesson.failed');
    if (state.allPartsDone) return texts.say('endgames.lesson.test') ?? intro;
    if (state.partsDone.isNotEmpty) {
      return texts.say('endgames.lesson.middle') ?? intro;
    }
    return intro;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final viktor = state.viktor;
    final texts = state.texts;
    final parts = lesson.lesson.sections;
    final done = state.partsDone;
    final recommended = state.recommendedPart;
    return Stack(
      children: [
        ListView(
          key: EndgameLessonKeys.list,
          padding: scrollPadding(
            context,
            left: AppSpacing.screen,
            top: AppSpacing.sm,
            right: AppSpacing.screen,
            bottom: _continueHeight + AppSpacing.lg,
          ),
          children: [
            Text(
              // O módulo e a posição nele ("Mates básicos · 1 de 4"): o
              // número na trilha inteira diz pouco.
              l10n.endgameModulePlace(
                texts.say('endgames.module.${lesson.module}') ?? lesson.module,
                state.moduleNumber,
                state.moduleCount,
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              texts.lessonTitle(lesson.id),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // O progresso das etapas; as estrelas e a meta ficam no teste.
            Text(
              l10n.endgameStagesDone(done.length, parts.length),
              key: EndgameLessonKeys.progressLine,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (viktor != null) ...[
              const SizedBox(height: AppSpacing.md),
              TeacherSpeech(
                speechContext: SpeechContext.teaching,
                teacher: viktor,
                text: _speech(),
                emotion: state.passed ? Emotion.happy : Emotion.calm,
                avatarSize: 48,
                bubbleKey: EndgameLessonKeys.speech,
                speaks: true,
              ),
            ],
            _Section(title: l10n.endgameLessonPartLesson),
            if (state.allPartsDone)
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.endgameLessonDone,
                      key: EndgameLessonKeys.lessonDone,
                    ),
                  ),
                  TextButton(
                    key: EndgameLessonKeys.lessonButton,
                    onPressed: () => context.push(
                      Routes.endgameLessonSteps(
                        lesson.id,
                        part: lesson.lesson.parts.isEmpty
                            ? null
                            : parts.first.id,
                      ),
                    ),
                    child: Text(l10n.endgameLessonReview),
                  ),
                ],
              ),
            for (final (index, part) in parts.indexed)
              _PartTile(
                lesson: lesson,
                state: state,
                part: part,
                number: index + 1,
                done: done.contains(part.id),
                recommended: recommended?.id == part.id,
              ),
            _Section(title: l10n.endgameFinalTest),
            _FinalTest(state: state, lesson: lesson),
            _Section(title: l10n.endgameChallengeTitle),
            _FinalCard(state: state, lesson: lesson),
          ],
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: _ContinueBar(state: state, lesson: lesson),
        ),
      ],
    );
  }
}

/// A altura do botão "Continuar" fixo embaixo, com a margem.
const _continueHeight = 80.0;

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Uma parte da lição: número, título, resumo, tempo e estado. A
/// recomendada fica em destaque, com "Começar" ou "Continuar"; as outras
/// abrem do mesmo jeito (nada trava).
class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.lesson,
    required this.state,
    required this.part,
    required this.number,
    required this.done,
    required this.recommended,
  });

  final EndgameLesson lesson;
  final EndgameLessonState state;
  final LessonPart part;
  final int number;
  final bool done;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final texts = state.texts;
    final title =
        texts.partTitle(lesson.id, part.id) ?? l10n.endgameLessonPartLesson;
    final summary = texts.partSummary(lesson.id, part.id);
    final ongoing = state.ongoingPart == part.id;
    void open() => context.push(
      Routes.endgameLessonSteps(
        lesson.id,
        part: lesson.lesson.parts.isEmpty ? null : part.id,
      ),
    );
    return Card(
      key: EndgameLessonKeys.part(part.id),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      color: recommended ? colors.primaryContainer : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: EdgeInsets.all(recommended ? AppSpacing.lg : AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: done
                        ? colors.primary
                        : recommended
                        ? colors.onPrimaryContainer
                        : colors.surfaceContainerHighest,
                    child: done
                        ? Icon(
                            Icons.check_circle,
                            size: 16,
                            color: colors.onPrimary,
                          )
                        : Text(
                            '$number',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: recommended
                                  ? colors.primaryContainer
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: recommended ? colors.onPrimaryContainer : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (summary != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 40),
                  child: Text(
                    summary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: recommended
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (recommended) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton(
                    key: EndgameLessonKeys.lessonButton,
                    onPressed: open,
                    child: Text(
                      ongoing ? l10n.lessonContinue : l10n.endgamePartStart,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// O teste final: um cartão com quantos exercícios, a nota mínima e as
/// estrelas sobre o total, e a lista que abre ao toque.
/// Sempre aberto; com todas as partes feitas, já vem aberto e em destaque.
class _FinalTest extends StatefulWidget {
  const _FinalTest({required this.state, required this.lesson});

  final EndgameLessonState state;
  final EndgameLesson lesson;

  @override
  State<_FinalTest> createState() => _FinalTestState();
}

class _FinalTestState extends State<_FinalTest> {
  late bool _open = widget.state.allPartsDone;

  @override
  void didUpdateWidget(_FinalTest old) {
    super.didUpdateWidget(old);
    // Ao terminar as partes, o teste abre sozinho.
    if (!old.state.allPartsDone && widget.state.allPartsDone) _open = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = widget.state;
    final ready = state.allPartsDone;
    final max = state.maxScore;
    final motion = AppMotion.of(context);
    return Card(
      key: EndgameLessonKeys.finalTest,
      margin: EdgeInsets.zero,
      color: ready ? colors.secondaryContainer : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: EndgameLessonKeys.finalTestSummary,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.primary,
                        child: Icon(
                          Icons.quiz_outlined,
                          size: 20,
                          color: colors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.endgameTestCount(state.exerciseCount),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              // Um retorno, sem a conta da nota mínima.
                              state.passed
                                  ? l10n.endgameTestLearned
                                  : state.allSolved
                                  ? l10n.endgameTestAlmost
                                  : l10n.endgameTestPrompt,
                              key: EndgameLessonKeys.testFeedback,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.star_rounded, color: StarsRow.color),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${state.score}/$max',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: motion.state,
                        child: const Icon(Icons.expand_more),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: motion.component,
            curve: AppMotion.move,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!ready)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              l10n.endgameTestAdvice,
                              key: EndgameLessonKeys.testAdvice,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        _ExercisesCard(state: state, lesson: widget.lesson),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// "Continuar", fixo embaixo: leva ao ponto recomendado (a parte, o teste ou
/// o final de verdade).
class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.state, required this.lesson});

  final EndgameLessonState state;
  final EndgameLesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final part = state.recommendedPart;
    final exercise = state.nextExercise;
    final practice = lesson.practice;
    final String label;
    final VoidCallback onPressed;
    if (part != null) {
      label = l10n.endgameContinuePart(
        lesson.lesson.sections.indexOf(part) + 1,
      );
      onPressed = () => context.push(
        Routes.endgameLessonSteps(
          lesson.id,
          part: lesson.lesson.parts.isEmpty ? null : part.id,
        ),
      );
    } else if (exercise != null) {
      label = l10n.endgameContinueTest;
      onPressed = () =>
          context.push(Routes.endgameExercise(lesson.id, exercise.id));
    } else {
      label = l10n.endgameTrain;
      onPressed = () => context.push(
        Routes.setup(
          practice.fen,
          goal: practice.goal.code,
          position: practice.positionId,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [background.withValues(alpha: 0), background],
          stops: const [0, 0.35],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xl,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          child: FilledButton(
            key: EndgameLessonKeys.continueButton,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: onPressed,
            child: Text(label),
          ),
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
                  l10n.endgameExercisesSolved(
                    state.solved,
                    state.exerciseCount,
                  ),
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
                        icon: const Icon(Icons.replay),
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
        onTap: () => context.push(
          Routes.endgameExercise(lessonId, exercise.id),
          extra: exercise.fen,
        ),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: PositionBoard(
            fen: exercise.fen,
            size: 56,
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
