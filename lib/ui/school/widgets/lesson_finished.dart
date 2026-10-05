import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/lesson_cubit.dart';
import 'lesson_screen.dart';

/// O fim da aula: a medalha entrando, o Viktor comentando e o caminho
/// seguinte. Na última aula, a formatura.
class LessonFinished extends StatelessWidget {
  const LessonFinished({required this.state, super.key});

  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final viktor = state.viktor;
    final lesson = state.lesson!;
    final next = state.nextLesson;
    final graduation = state.courseFinished;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  graduation ? Icons.workspace_premium : Icons.check_rounded,
                  size: 60,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              graduation
                  ? l10n.lessonGraduationTitle
                  : l10n.lessonDoneTitle(state.texts.lessonTitle(lesson.id)),
              key: graduation ? SchoolKeys.graduated : null,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            if (viktor != null)
              TeacherSpeech(
                teacher: viktor,
                text: state.speech,
                emotion: Emotion.happy,
                avatarSize: 72,
                bubbleKey: LessonKeys.speech,
              ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  if (graduation)
                    FilledButton.icon(
                      key: LessonKeys.journeyButton,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(220, 52),
                      ),
                      icon: const Icon(Icons.flag_rounded),
                      label: Text(l10n.lessonToJourney),
                      onPressed: () => context.go(Routes.journey),
                    )
                  else if (next != null)
                    FilledButton.icon(
                      key: LessonKeys.nextLessonButton,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(220, 52),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        l10n.lessonNext(state.texts.lessonTitle(next)),
                      ),
                      onPressed: () => openLesson(context, next),
                    ),
                  OutlinedButton(
                    key: LessonKeys.trailButton,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(220, 48),
                    ),
                    onPressed: () => context.go(Routes.school),
                    child: Text(l10n.lessonBackToSchool),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
