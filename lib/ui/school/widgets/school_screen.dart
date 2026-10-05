import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/lesson.dart';
import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/school_cubit.dart';
import '../../core/widgets/scroll_padding.dart';

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
                TeacherSpeech(teacher: viktor, text: greeting, avatarSize: 72),
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
                    state.ongoing != null || state.done > 0
                        ? l10n.schoolContinue(texts.lessonTitle(next))
                        : l10n.schoolStart,
                  ),
                  onPressed: () => context.go(Routes.lesson(next)),
                ),
              ],
              for (final (index, module) in state.course.modules.indexed)
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
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
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
            borderRadius: BorderRadius.circular(16),
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
        Icons.check_rounded,
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
          borderRadius: BorderRadius.circular(40),
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
                    duration: const Duration(milliseconds: 300),
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
