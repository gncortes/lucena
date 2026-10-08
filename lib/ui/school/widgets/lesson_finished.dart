import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/character.dart';
import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/lesson_cubit.dart';
import 'graduation_view.dart';
import 'lesson_screen.dart';
import '../../core/theme/app_motion.dart';

/// A aula depois da qual o Viktor convida para jogar no Lichess.
const lichessInviteLesson = 'tricks.principles';

/// O convite para criar conta no Lichess e jogar contra pessoas: o link
/// abre fora do app.
class LichessInvite extends StatelessWidget {
  const LichessInvite({super.key});

  static final url = Uri.parse('https://lichess.org/signup');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      key: LessonKeys.lichessInvite,
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: colors.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.lichessInviteTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.lichessInviteBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              key: LessonKeys.lichessButton,
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.lichessInviteButton),
              onPressed: () =>
                  launchUrl(url, mode: LaunchMode.externalApplication),
            ),
          ],
        ),
      ),
    );
  }
}

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
    // A formatura tem a sua tela.
    if (graduation) return GraduationView(state: state);
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: AppMotion.celebrate,
                  curve: AppMotion.bounce,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      graduation
                          ? Icons.workspace_premium
                          : Icons.check_circle_rounded,
                      size: 60,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  graduation
                      ? l10n.lessonGraduationTitle
                      : l10n.lessonDoneTitle(
                          state.texts.lessonTitle(lesson.id),
                        ),
                  key: graduation ? SchoolKeys.graduated : null,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                if (viktor != null)
                  TeacherSpeech(
                    speechContext: SpeechContext.teaching,
                    teacher: viktor,
                    text: state.speech,
                    emotion: Emotion.happy,
                    avatarSize: 56,
                    bubbleKey: LessonKeys.speech,
                  ),
                // Depois dos truques (e na formatura): jogar contra pessoas
                // no Lichess, e voltar para os finais.
                if (lesson.id == lichessInviteLesson) ...[
                  const SizedBox(height: 20),
                  const LichessInvite(),
                ],
                const SizedBox(height: 32),
                // Os botões na mesma largura do balão e do resto da tela.
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      if (state.endgame)
                        FilledButton.icon(
                          key: LessonKeys.exercisesButton,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(220, 52),
                          ),
                          icon: const Icon(Icons.star_rounded),
                          label: Text(l10n.lessonToExercises),
                          onPressed: () => context.pop(),
                        ),
                      if (next != null)
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
                      if (!state.endgame)
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
        ),
        // Cada aula concluída ganha um pouco de confete.
        const Positioned.fill(child: Celebration(key: LessonKeys.celebration)),
      ],
    );
  }
}
