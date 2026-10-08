import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/placement_roadmap.dart';
import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/school_cubit.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// A Escola do Viktor: ele recebe o aluno, e a trilha mostra os módulos com
/// as aulas em caminho (feitas, liberadas e bloqueadas).
class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: SchoolKeys.screen,
      appBar: AppBar(title: Text(l10n.schoolTitle)),
      body: BlocBuilder<SchoolCubit, SchoolState>(
        builder: (context, state) {
          if (!state.ready) return const SizedBox.shrink();
          final next = state.next;
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
              if (next != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: SchoolKeys.continueButton,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    state.ongoing != null ||
                            state.done > 0 ||
                            state.skipped.isNotEmpty
                        ? l10n.schoolContinue(texts.lessonTitle(next))
                        : l10n.schoolStart,
                  ),
                  onPressed: () => context.go(Routes.lesson(next)),
                ),
              ],
              if (state.graduated) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: SchoolKeys.endgamesButton,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: Text(l10n.endgamesTitle),
                  onPressed: () => context.push(Routes.endgames),
                ),
              ],
              if (!state.tested && !state.graduated) ...[
                const SizedBox(height: 12),
                _TestCard(
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
              const SizedBox(height: 12),
              _ChallengesCard(),
              if (state.skipped.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SkippedGroup(state: state),
              ],
              for (final (index, module) in state.course.modules.indexed)
                // Um módulo todo dispensado sai da trilha (fica no grupo).
                if (module.lessons.any(
                  (lesson) => !state.skipped.containsKey(lesson.id),
                ))
                  _ModuleSection(index: index, module: module, state: state),
            ],
          );
        },
      ),
    );
  }
}

/// Quantas aulas foram feitas, numa barra.
class _Overview extends StatelessWidget {
  const _Overview({required this.state});

  final SchoolState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.total;
    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total == 0 ? 0 : state.done / total),
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
          context.l10n.schoolLessonsDone(state.done, total),
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
  final CourseModule module;
  final SchoolState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final done = module.lessons
        .where((lesson) => state.completed.contains(lesson.id))
        .length;
    return Column(
      key: SchoolKeys.module(module.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
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
                      state.texts.moduleTitle(module.id),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$done/${module.lessons.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final (position, lesson) in module.lessons.indexed)
          if (!state.skipped.containsKey(lesson.id))
            _LessonNode(
              lesson: lesson,
              state: state,
              // O caminho serpenteia de um lado para o outro.
              offset: sin(position * pi / 2.5) * 0.55,
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.schoolLocked(
                  blocker == null ? '' : texts.lessonTitle(blocker),
                ),
              ),
            ),
          );
        return;
      }
      context.go(Routes.lesson(lesson.id));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                        boxShadow: [
                          if (isNext)
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Icon(icon, color: foreground, size: 32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    texts.lessonTitle(lesson.id),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: status == LessonStatus.locked
                          ? colors.outline
                          : null,
                      fontWeight: isNext ? FontWeight.w700 : null,
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

/// "Já sabe jogar? Faça o teste e pule o que já sabe.", para quem ainda
/// não fez o teste de nível.
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
        key: SchoolKeys.placementTest,
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
                  l10n.schoolTestPrompt,
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
    return Card.filled(
      key: SchoolKeys.skippedGroup,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: AppMotion.of(context).component,
        curve: AppMotion.move,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.schoolKnownTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quantas aulas.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
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
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
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
                const SizedBox(height: 12),
                for (final (lesson, reason) in lessons)
                  _KnownLesson(
                    key: SchoolKeys.lesson(lesson.id),
                    title: state.texts.lessonTitle(lesson.id),
                    reason: reason,
                    onTap: () => context.go(Routes.lesson(lesson.id)),
                  ),
              ],
              const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              confirmed
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              size: 20,
              color: colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            const SizedBox(width: 8),
            Text(
              confirmed
                  ? l10n.schoolSkippedConfirmed
                  : l10n.schoolSkippedLikely,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.play_arrow_rounded,
              size: 20,
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
    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(AppShape.large),
      child: InkWell(
        key: SchoolKeys.challengesButton,
        borderRadius: BorderRadius.circular(AppShape.large),
        onTap: () => context.push(Routes.starChallenges),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
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
                  color: Color(0xfff2b705),
                  size: 38,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.starChallengesTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.starChallengesBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
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
              const SizedBox(width: 4),
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
