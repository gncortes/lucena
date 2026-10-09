import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/use_cases/placement_roadmap.dart';
import '../../placement/widgets/placement_prompt.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/endgames_cubit.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// A trilha das aulas de finais: o Viktor recebe o aluno e os módulos
/// listam as aulas, cada uma com a nota (as estrelas) já alcançada.
class EndgamesScreen extends StatelessWidget {
  const EndgamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: EndgamesKeys.screen,
      appBar: AppBar(title: Text(l10n.endgamesTitle)),
      body: BlocBuilder<EndgamesCubit, EndgamesState>(
        builder: (context, state) {
          if (!state.ready) return const SizedBox.shrink();
          final next = state.next;
          final viktor = state.viktor;
          final texts = state.texts;
          final greeting = next == null && state.total > 0
              ? texts.say('endgames.allPassed')
              : state.passed == 0
              ? texts.say('endgames.welcome')
              : texts.say('endgames.welcomeBack', state.passed);
          return ListView(
            padding: scrollPadding(
              context,
              left: 16,
              top: 8,
              right: 16,
              bottom: 32,
            ),
            children: [
              if (viktor != null)
                TeacherSpeech(
                  speechContext: SpeechContext.teaching,
                  teacher: viktor,
                  text: greeting,
                  avatarSize: 56,
                ),
              const SizedBox(height: 16),
              _Overview(state: state),
              // Com o teste feito, o cartão do próximo final faz as vezes
              // do botão.
              if (next != null && state.roadmap?.nextEndgame == null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: EndgamesKeys.continueButton,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    state.passed > 0 ||
                            state.status(next) != EndgameLessonStatus.open
                        ? l10n.schoolContinue(texts.lessonTitle(next))
                        : l10n.schoolStart,
                  ),
                  onPressed: () => context.push(Routes.endgameLesson(next)),
                ),
              ],
              if (!state.tested) ...[
                const SizedBox(height: 12),
                _TestCard(
                  onTap: () async {
                    final cubit = context.read<EndgamesCubit>();
                    final language = Localizations.localeOf(context)
                        .languageCode;
                    final used = await context.push<bool>(
                      Routes.placementFrom('endgames'),
                    );
                    if (used == true) await cubit.load(language);
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                // Com o teste feito: o roteiro ("Para você") ou a trilha
                // inteira para praticar ("Todos").
                SegmentedButton<bool>(
                  key: EndgamesKeys.filter,
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(
                        l10n.endgamesForYou,
                        key: EndgamesKeys.forYou,
                      ),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.endgamesAll, key: EndgamesKeys.all),
                    ),
                  ],
                  selected: {state.showAll},
                  onSelectionChanged: (selected) =>
                      context.read<EndgamesCubit>().setShowAll(selected.first),
                ),
                // As aulas concluídas continuam na lista; quem quiser, as
                // esconde.
                if (!state.showAll && state.doneLessons.isNotEmpty)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilterChip(
                      key: EndgamesKeys.hideDone,
                      label: Text(l10n.endgamesHideDone),
                      selected: state.hideDone,
                      onSelected: (hide) =>
                          context.read<EndgamesCubit>().setHideDone(hide),
                    ),
                  ),
              ],
              if (state.forYou)
                ..._forYou(context, state)
              else ...[
                if (state.roadmap?.nextEndgame != null) ...[
                  const SizedBox(height: 12),
                  _NextEndgames(state: state),
                ],
                for (final (index, module) in state.trail.modules.indexed)
                  _ModuleSection(index: index, module: module, state: state),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// "Para você": as aulas do roteiro, na ordem; as que ainda não existem,
/// como "em breve".
List<Widget> _forYou(BuildContext context, EndgamesState state) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final steps = state.roadmap!.endgameSteps;
  final showsDone = !state.hideDone && state.doneLessons.isNotEmpty;
  if (steps.isEmpty && !showsDone) {
    return [
      const SizedBox(height: 16),
      Text(
        l10n.endgamesForYouEmpty,
        key: EndgamesKeys.forYouEmpty,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    ];
  }
  return [
    const SizedBox(height: 12),
    // As concluídas primeiro, na ordem da trilha, já marcadas como feitas.
    if (showsDone)
      for (final lesson in state.doneLessons)
        _LessonTile(lesson: lesson, state: state),
    for (final step in steps)
      if (state.trail.lesson(step.lessonId) case final lesson? when !step.soon)
        _LessonTile(lesson: lesson, state: state)
      else
        Card(
          key: EndgamesKeys.lesson(step.lessonId),
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: colors.surfaceContainerLow,
          child: ListTile(
            enabled: false,
            leading: const CircleAvatar(child: Icon(Icons.upcoming_rounded)),
            title: Text(skillName(l10n, step.node)),
            trailing: Text(l10n.placementSoon),
          ),
        ),
  ];
}

class _Overview extends StatelessWidget {
  const _Overview({required this.state});

  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.total;
    return Row(
      key: EndgamesKeys.overview,
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total == 0 ? 0 : state.passed / total),
            duration: AppMotion.screen,
            curve: AppMotion.enter,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius: BorderRadius.circular(AppShape.small),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          context.l10n.endgamesPassedCount(state.passed, total),
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({
    required this.index,
    required this.module,
    required this.state,
  });

  final int index;
  final EndgameModule module;
  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final passed = module.lessons
        .where(
          (lesson) => state.status(lesson.id) == EndgameLessonStatus.passed,
        )
        .length;
    return Column(
      key: EndgamesKeys.module(module.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppShape.large),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.schoolModule(index + 1),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      state.texts.say('endgames.module.${module.id}') ??
                          module.id,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$passed/${module.lessons.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (final lesson in module.lessons)
          _LessonTile(lesson: lesson, state: state),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.state});

  final EndgameLesson lesson;
  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = state.status(lesson.id);
    final isNext = state.next == lesson.id;
    final texts = state.texts;
    final (score, max) = state.score(lesson.id);
    final (background, foreground, icon) = switch (status) {
      EndgameLessonStatus.passed => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.check_circle_rounded,
      ),
      EndgameLessonStatus.started => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.star_half_rounded,
      ),
      EndgameLessonStatus.open => (
        isNext ? colors.primary : colors.surfaceContainerHighest,
        isNext ? colors.onPrimary : colors.onSurfaceVariant,
        Icons.play_arrow_rounded,
      ),
    };
    return Semantics(
      button: true,
      label: l10n.endgamesLessonLabel(
        texts.lessonTitle(lesson.id),
        status.name,
      ),
      excludeSemantics: true,
      child: Card(
        key: EndgamesKeys.lesson(lesson.id),
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: isNext
            ? colors.surfaceContainerHigh
            : colors.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => context.push(Routes.endgameLesson(lesson.id)),
          leading: CircleAvatar(
            backgroundColor: background,
            child: Icon(icon, color: foreground),
          ),
          title: Text(
            texts.lessonTitle(lesson.id),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isNext ? FontWeight.w700 : null,
            ),
          ),
          // O resumo inteiro: é ele que diz o que a aula ensina. Embaixo, o
          // selo do teste de nível.
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(texts.lessonSummary(lesson.id) ?? ''),
              // Só o "já domina": a recomendada já vem em primeiro.
              if (state.badge(lesson.id) == EndgameBadge.mastered) ...[
                const SizedBox(height: 4),
                _Badge(key: EndgamesKeys.badge(lesson.id)),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 18,
                color: score > 0 ? const Color(0xfff2b705) : colors.outline,
              ),
              const SizedBox(width: 2),
              Text(
                '$score/$max',
                key: EndgamesKeys.lessonScore(lesson.id),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O selo "Já domina" de uma aula, pelo teste.
class _Badge extends StatelessWidget {
  const _Badge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 14,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.placementMastered,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Descubra quais finais você já domina", para quem não fez o teste.
class _TestCard extends StatelessWidget {
  const _TestCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(AppShape.large),
      child: InkWell(
        key: EndgamesKeys.placementTest,
        borderRadius: BorderRadius.circular(AppShape.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
          child: Row(
            children: [
              Icon(Icons.quiz_outlined, color: colors.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.endgamesTestPrompt,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: colors.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Seu próximo final" e os seguintes do roteiro (os que ainda não existem
/// aparecem como "em breve").
class _NextEndgames extends StatelessWidget {
  const _NextEndgames({required this.state});

  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final roadmap = state.roadmap!;
    final next = roadmap.nextEndgame!;
    final following = roadmap.followingEndgames();
    String title(RoadmapStep step) => step.soon
        ? skillName(l10n, step.node)
        : state.texts.lessonTitle(step.lessonId);
    return Card.filled(
      key: EndgamesKeys.nextEndgame,
      color: colors.primaryContainer,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: next.soon
            ? null
            : () => context.push(Routes.endgameLesson(next.lessonId)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.endgamesNextTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title(next),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (next.soon)
                    Text(
                      l10n.placementSoon,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      child: const Icon(Icons.play_arrow_rounded),
                    ),
                ],
              ),
              if (following.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.endgamesThenTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                for (final (index, step) in following.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '${index + 2}.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title(step),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (step.soon)
                          Text(
                            l10n.placementSoon,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
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
