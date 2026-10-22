import 'dart:math';

import '../../../domain/models/ads_state.dart';
import '../../core/ads/lesson_gate.dart';

import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/placement_roadmap.dart';
import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shadow.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/school_cubit.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/placement_test_card.dart';

/// A Escola do Viktor: ele recebe o aluno, e a trilha mostra os módulos com
/// as aulas em caminho (feitas, liberadas e bloqueadas).
class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  final _currentLesson = GlobalKey();
  String? _scrolledLesson;

  void _revealCurrent(String? lesson) {
    if (lesson == null || lesson == _scrolledLesson) return;
    _scrolledLesson = lesson;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scrolledLesson != lesson) return;
      final target = _currentLesson.currentContext;
      final box = target?.findRenderObject();
      // Embaixo de outra tela (o app reabriu num desafio), a lista não foi
      // desenhada: não há o que rolar.
      if (target != null && box is RenderBox && box.hasSize) {
        Scrollable.ensureVisible(target, alignment: 0.4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: SchoolKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.schoolTitle)),
      body: BlocBuilder<SchoolCubit, SchoolState>(
        builder: (context, state) {
          if (!state.ready) return const SizedBox.shrink();
          final next = state.next;
          _revealCurrent(next);
          final viktor = state.viktor;
          final texts = state.texts;
          final greeting = state.graduated
              ? texts.say('school.graduated')
              : state.done == 0 &&
                    state.ongoing == null &&
                    state.skipped.isNotEmpty &&
                    next != null
              // Pelo teste: o Viktor já diz por onde começar.
              ? l10n.schoolPlacedSpeech(texts.lessonTitle(next))
              : state.done == 0 && state.ongoing == null
              ? texts.say('school.welcome')
              : texts.say('school.welcomeBack', state.done);
          return SingleChildScrollView(
            key: SchoolKeys.scroll,
            padding: scrollPadding(
              context,
              left: 16,
              top: 8,
              right: 16,
              bottom: 32,
            ),
            // Todas as âncoras estão montadas: a aula atual pode estar em
            // um módulo distante, fora da primeira janela visível.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (viktor != null)
                  TeacherSpeech(
                    speechContext: SpeechContext.teaching,
                    teacher: viktor,
                    text: greeting,
                    avatarSize: CharacterAvatar.speech,
                  ),
                // Sem a contagem de aulas: o iniciante não vê quanto falta.
                if (next != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    key: SchoolKeys.continueButton,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(kButtonHeight),
                      textStyle: AppButtonText.footer(context),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      state.ongoing != null ||
                              state.done > 0 ||
                              state.skipped.isNotEmpty
                          ? l10n.schoolContinue(texts.lessonTitle(next))
                          : l10n.schoolStart,
                    ),
                    onPressed: () => LessonGate.open(
                      context,
                      lessonId: next,
                      kind: LessonKind.school,
                      open: () => context.go(Routes.lessonScript(next)),
                    ),
                  ),
                ],
                if (state.graduated) ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonalIcon(
                    key: SchoolKeys.endgamesButton,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(kButtonHeight),
                      textStyle: AppButtonText.footer(context),
                    ),
                    icon: const Icon(Icons.auto_stories_outlined),
                    label: Text(l10n.endgamesTitle),
                    onPressed: () => context.push(Routes.endgames),
                  ),
                ],
                if (!state.tested && !state.graduated) ...[
                  const SizedBox(height: AppSpacing.md),
                  PlacementTestCard(
                    label: context.l10n.schoolTestPrompt,
                    tapKey: SchoolKeys.placementTest,
                    onTap: () async {
                      final cubit = context.read<SchoolCubit>();
                      final language = Localizations.localeOf(context)
                          .languageCode;
                      final used = await context.push<bool>(
                        Routes.placementFrom('school'),
                      );
                      if (used == true) await cubit.load(language);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _ChallengesCard(),
                if (state.skipped.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SkippedGroup(state: state),
                ],
                for (final (index, module) in state.course.modules.indexed)
                  _ModuleSection(
                    index: index,
                    module: module,
                    state: state,
                    currentLesson: _currentLesson,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({
    required this.index,
    required this.module,
    required this.state,
    required this.currentLesson,
  });

  final GlobalKey currentLesson;
  final int index;
  final CourseModule module;
  final SchoolState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      key: SchoolKeys.module(module.id),
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
                        context.l10n.schoolModule(index + 1),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        state.texts.moduleTitle(module.id),
                        style: context.cardTitle?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final (position, lesson) in module.lessons.indexed)
          KeyedSubtree(
            key: state.next == lesson.id ? currentLesson : null,
            child: _LessonNode(
              lesson: lesson,
              state: state,
              // O caminho serpenteia de um lado para o outro.
              offset: sin(position * pi / 2.5) * 0.55,
            ),
          ),
      ],
    );
  }
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.lesson,
    required this.state,
    required this.offset,
  });

  final Lesson lesson;
  final SchoolState state;

  /// De -1 (começo da linha) a 1 (fim da linha).
  final double offset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = state.status(lesson.id);
    final isNext = state.next == lesson.id;
    final texts = state.texts;
    final (background, foreground, icon) = switch (status) {
      LessonStatus.completed => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.check_circle_rounded,
      ),
      LessonStatus.open => (
        isNext ? colors.primary : colors.secondaryContainer,
        isNext ? colors.onPrimary : colors.onSecondaryContainer,
        Icons.play_arrow_rounded,
      ),
      LessonStatus.locked => (
        colors.surfaceContainerHighest,
        colors.outline,
        Icons.lock_outline,
      ),
      LessonStatus.skippedByTest => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.verified_outlined,
      ),
    };
    void open() {
      if (status == LessonStatus.locked) {
        final blocker = state.blockedBy(lesson.id);
        showLucenaSnackBar(
          context,
          l10n.schoolLocked(blocker == null ? '' : texts.lessonTitle(blocker)),
        );
        return;
      }
      LessonGate.open(
        context,
        lessonId: lesson.id,
        kind: LessonKind.school,
        open: () => context.go(Routes.lessonScript(lesson.id)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional(offset, 0),
        child: InkWell(
          key: SchoolKeys.lesson(lesson.id),
          borderRadius: BorderRadius.circular(AppShape.full),
          onTap: open,
          child: Semantics(
            button: true,
            label: l10n.schoolLessonLabel(
              texts.lessonTitle(lesson.id),
              status.name,
            ),
            excludeSemantics: true,
            child: SizedBox(
              width: 200,
              child: Column(
                children: [
                  AnimatedScale(
                    scale: isNext ? 1.1 : 1,
                    duration: AppMotion.component,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: background,
                        shape: BoxShape.circle,
                        boxShadow: [if (isNext) AppShadow.glow(colors)],
                      ),
                      child: Icon(
                        icon,
                        color: foreground,
                        size: AppIconSize.large,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    texts.lessonTitle(lesson.id),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: status == LessonStatus.locked
                          ? colors.outline
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// As aulas que o teste mostrou que o jogador já sabe, num cartão
/// recolhido: "Rever as aulas anteriores" abre a lista, cada aula com o
/// motivo (acertou no teste ou pelo nível) e podendo ser feita.
class _SkippedGroup extends StatelessWidget {
  const _SkippedGroup({required this.state});

  final SchoolState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<SchoolCubit>();
    final lessons = [
      for (final lesson in state.course.lessons)
        if (state.skipped[lesson.id] case final reason?) (lesson, reason),
    ];
    return Card(
      key: SchoolKeys.skippedGroup,
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: AppMotion.of(context).component,
        curve: AppMotion.move,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: colors.onPrimary,
                      size: AppIconSize.standard,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.schoolKnownTitle,
                                style: context.cardTitle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Quantas aulas.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppShape.full,
                                ),
                              ),
                              child: Text(
                                '${lessons.length}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.schoolKnownBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.showSkipped) ...[
                const SizedBox(height: AppSpacing.md),
                for (final (lesson, reason) in lessons)
                  _KnownLesson(
                    key: SchoolKeys.skippedLesson(lesson.id),
                    title: state.texts.lessonTitle(lesson.id),
                    reason: reason,
                    onTap: () => LessonGate.open(
                      context,
                      lessonId: lesson.id,
                      kind: LessonKind.school,
                      open: () => context.go(Routes.lessonScript(lesson.id)),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                key: SchoolKeys.reviewSkipped,
                onPressed: cubit.toggleSkipped,
                icon: AnimatedRotation(
                  turns: state.showSkipped ? 0.5 : 0,
                  duration: AppMotion.of(context).state,
                  child: const Icon(Icons.expand_more_rounded),
                ),
                label: Text(
                  state.showSkipped
                      ? l10n.schoolHideSkipped
                      : l10n.schoolReviewSkipped,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma aula que o jogador já sabe: o título e o motivo, num selo.
class _KnownLesson extends StatelessWidget {
  const _KnownLesson({
    required this.title,
    required this.reason,
    required this.onTap,
    super.key,
  });

  final String title;
  final SkipReason reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final confirmed = reason == SkipReason.confirmed;
    return InkWell(
      borderRadius: BorderRadius.circular(AppShape.small),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              confirmed
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              size: AppIconSize.button,
              color: colors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    confirmed
                        ? l10n.schoolSkippedConfirmed
                        : l10n.schoolSkippedLikely,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.play_arrow_rounded,
              size: AppIconSize.button,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// A entrada dos desafios das estrelas: pegar as estrelas com cada peça
/// contra o relógio. As seis peças em figurino convidam a jogar.
class _ChallengesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: InkWell(
        key: SchoolKeys.challengesButton,
        borderRadius: BorderRadius.circular(AppShape.large),
        onTap: () => context.push(Routes.starChallenges),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.goldColor,
                  size: AppIconSize.large,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.starChallengesTitle,
                      style: context.cardTitle?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.starChallengesBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '♖ ♗ ♘ ♕ ♔ ♙',
                      style: TextStyle(
                        fontFamily: Figurine.fontFamily,
                        fontSize: 22,
                        letterSpacing: 2,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: colors.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
