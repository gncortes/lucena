import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/endgames_cubit.dart';

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
                TeacherSpeech(teacher: viktor, text: greeting, avatarSize: 72),
              const SizedBox(height: 16),
              _Overview(state: state),
              if (next != null) ...[
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
              for (final (index, module) in state.trail.modules.indexed)
                _ModuleSection(index: index, module: module, state: state),
            ],
          );
        },
      ),
    );
  }
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
          subtitle: Text(
            texts.lessonSummary(lesson.id) ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
