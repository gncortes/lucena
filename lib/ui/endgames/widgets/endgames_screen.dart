import '../../../domain/models/survey.dart';
import '../../survey/widgets/survey_invite_card.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_chip.dart';

import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/use_cases/placement_roadmap.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../../../routing/routes.dart';
import '../../core/widgets/placement_test_card.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/endgames_cubit.dart';
import 'endgames_filters.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/empty_state.dart';

/// A trilha das aulas de finais: o Viktor recebe o aluno e os módulos
/// listam as aulas, cada uma com a nota (as estrelas) já alcançada.
class EndgamesScreen extends StatelessWidget {
  const EndgamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: EndgamesKeys.screen,
      appBar: LucenaAppBar(
        title: Text(l10n.endgamesTitle),
        actions: [
          // Os filtros valem para a trilha inteira, não para o roteiro.
          BlocBuilder<EndgamesCubit, EndgamesState>(
            buildWhen: (before, after) =>
                before.ready != after.ready || before.forYou != after.forYou,
            builder: (context, state) => state.ready && !state.forYou
                ? const EndgamesFilterButton()
                : const SizedBox.shrink(),
          ),
        ],
      ),
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
                  avatarSize: CharacterAvatar.speech,
                ),
              const SizedBox(height: AppSpacing.lg),
              _Overview(state: state),
              // Com o teste feito, o cartão do próximo final faz as vezes
              // do botão.
              if (next != null && state.roadmap?.nextEndgame == null) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: EndgamesKeys.continueButton,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonHeight),
                    textStyle: AppButtonText.footer(context),
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
                const SizedBox(height: AppSpacing.md),
                PlacementTestCard(
                  label: context.l10n.endgamesTestPrompt,
                  tapKey: EndgamesKeys.placementTest,
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
                const SizedBox(height: AppSpacing.lg),
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
                      materialTapTargetSize: AppChip.tapTarget,
                      visualDensity: AppChip.density,
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
                  const SizedBox(height: AppSpacing.md),
                  _NextEndgames(state: state),
                ],
                if (!state.filter.isEmpty) EndgamesActiveFilters(state: state),
                for (final section in state.sections)
                  _Section(section: section, state: state),
                if (state.filteredLessons.isEmpty && state.total > 0)
                  const EndgamesFiltersEmpty(),
              ],
              // O convite "Sua opinião", depois do último tile.
              const SizedBox(height: AppSpacing.lg),
              const SurveyInviteCard(
                kind: SurveyKind.endgames,
                source: SurveyInviteSource.trail,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "Para você": as aulas do roteiro, na ordem.
List<Widget> _forYou(BuildContext context, EndgamesState state) {
  final l10n = context.l10n;
  final steps = state.roadmap!.endgameSteps;
  final showsDone = !state.hideDone && state.doneLessons.isNotEmpty;
  if (steps.isEmpty && !showsDone) {
    return [
      EmptyState(
        style: EmptyStateStyle.text,
        message: l10n.endgamesForYouEmpty,
        messageKey: EndgamesKeys.forYouEmpty,
      ),
    ];
  }
  return [
    const SizedBox(height: AppSpacing.md),
    // As concluídas primeiro, na ordem da trilha, já marcadas como feitas.
    if (showsDone)
      for (final lesson in state.doneLessons)
        _LessonTile(lesson: lesson, state: state),
    for (final step in steps)
      if (state.trail.lesson(step.lessonId) case final lesson?)
        _LessonTile(lesson: lesson, state: state),
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
          child: AnimatedProgress(value: total == 0 ? 0 : state.passed / total),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          context.l10n.endgamesPassedCount(state.passed, total),
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}

/// Uma seção da lista: um módulo da trilha ou uma faixa de dificuldade.
class _Section extends StatelessWidget {
  const _Section({required this.section, required this.state});

  final EndgameSection section;
  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final module = section.module;
    final level = section.level;
    final lessons = section.lessons;
    final (label, title) = module != null
        ? (
            l10n.schoolModule(section.number),
            state.texts.plain('endgames.module.${module.id}') ?? module.id,
          )
        : (
            l10n.endgamesFilterLevel,
            level == null
                ? l10n.endgamesLevelNone
                : l10n.endgamesLevelSection(
                    level.name(l10n),
                    level.range(l10n),
                  ),
          );
    final passed = lessons
        .where(
          (lesson) => state.status(lesson.id) == EndgameLessonStatus.passed,
        )
        .length;
    return Column(
      key: module != null
          ? EndgamesKeys.module(module.id)
          : EndgamesKeys.level(level == null ? 'none' : EnumName(level).name),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        title,
                        style: context.cardTitle?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$passed/${lessons.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final lesson in lessons) _LessonTile(lesson: lesson, state: state),
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
        colors.primary,
        colors.onPrimary,
        Icons.check_rounded,
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
        margin: const EdgeInsets.only(bottom: AppSpacing.betweenCards),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => context.push(Routes.endgameLesson(lesson.id)),
          leading: CircleAvatar(
            backgroundColor: background,
            child: Icon(icon, color: foreground),
          ),
          title: Text(
            texts.lessonTitle(lesson.id),
            style: isNext
                ? theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppWeight.strong,
                  )
                : theme.textTheme.titleSmall,
          ),
          // O resumo inteiro: é ele que diz o que a aula ensina. Embaixo, o
          // selo do teste de nível.
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(texts.lessonSummary(lesson.id) ?? ''),
              // A revisão do conteúdo: reprovada (será refeita) ou ainda
              // em revisão.
              if (lesson.failed || lesson.inReview) ...[
                const SizedBox(height: AppSpacing.xs),
                _ReviewTag(
                  key: EndgamesKeys.reviewTag(lesson.id),
                  failed: lesson.failed,
                ),
              ],
              // Só o "já domina": a recomendada já vem em primeiro.
              if (state.badge(lesson.id) == EndgameBadge.mastered) ...[
                const SizedBox(height: AppSpacing.xs),
                _Badge(key: EndgamesKeys.badge(lesson.id)),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: AppIconSize.button,
                color: score > 0 ? AppColors.goldColor : colors.outline,
              ),
              const SizedBox(width: AppSpacing.xs),
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

/// O selo da revisão do conteúdo: ✕ "Reprovada" (a aula será refeita) ou
/// "Em revisão".
class _ReviewTag extends StatelessWidget {
  const _ReviewTag({required this.failed, super.key});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InfoChip(
      icon: failed ? Icons.close_rounded : Icons.rate_review_outlined,
      label: failed
          ? context.l10n.endgamesTagFailed
          : context.l10n.endgamesTagInReview,
      background: failed ? colors.errorContainer : colors.secondaryContainer,
      foreground: failed
          ? colors.onErrorContainer
          : colors.onSecondaryContainer,
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
    return InfoChip(
      icon: Icons.verified_rounded,
      label: context.l10n.placementMastered,
      background: colors.secondaryContainer,
      foreground: colors.onSecondaryContainer,
    );
  }
}

/// "Seu próximo final" e os seguintes do roteiro.
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
    String title(RoadmapStep step) => state.texts.lessonTitle(step.lessonId);
    return Card(
      key: EndgamesKeys.nextEndgame,
      color: colors.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.endgameLesson(next.lessonId)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.endgamesNextTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(child: Text(title(next), style: context.cardTitle)),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    child: const Icon(Icons.play_arrow_rounded),
                  ),
                ],
              ),
              if (following.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.endgamesThenTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final (index, step) in following.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${index + 2}.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            title(step),
                            style: theme.textTheme.bodyMedium,
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
