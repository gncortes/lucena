import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/survey.dart';
import '../../../domain/models/training/lesson_end.dart';
import '../../core/keys/lesson_end_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../survey/widgets/survey_invite_card.dart';
import 'lesson_end_parts.dart';

/// Curso concluído, o diploma (H-LIC-53, canvas `CursoConcluido`): confete,
/// o diploma com o nome do aluno, a fala do Viktor, o convite da Opinião e
/// "Ver as metas" / "Ver o catálogo". Sem nome, o diploma não é gerado.
class CourseCompletedScreen extends StatelessWidget {
  const CourseCompletedScreen({
    required this.completion,
    required this.teacher,
    required this.onGoals,
    required this.onCatalog,
    this.onShare,
    required this.onClose,
    super.key,
  });

  final CourseCompletion completion;
  final Character teacher;
  final VoidCallback onGoals, onCatalog, onClose;

  /// Sem compartilhamento ligado, o botão não aparece.
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: LessonEndKeys.completed,
      appBar: LessonEndClose(
        buttonKey: LessonEndKeys.completedClose,
        onClose: onClose,
        actions: [
          if (onShare != null)
            IconButton(
              key: LessonEndKeys.completedShare,
              icon: const Icon(Icons.share),
              tooltip: l.licaoCursoConcluidoCompartilhar,
              onPressed: onShare,
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Text(
                    l.licaoCursoConcluidoTitle(completion.courseName),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      height: 36 / 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Diploma(
                    key: LessonEndKeys.completedDiploma,
                    completion: completion,
                  ),
                  const SizedBox(height: 16),
                  TeacherSpeech(
                    showSpeedBadge: false,
                    canvasTrainingBalloon: true,
                    teacher: teacher,
                    avatarSize: 56,
                    text: l.licaoCursoConcluidoFala,
                    speechContext: SpeechContext.teaching,
                  ),
                  const SizedBox(height: 12),
                  const SurveyInviteCard(
                    kind: SurveyKind.pilares,
                    source: SurveyInviteSource.pilaresDiploma,
                  ),
                ],
              ),
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: Celebration())),
        ],
      ),
      bottomNavigationBar: ActionsFooter(
        stacked: true,
        children: [
          BusyButton(
            buttonKey: LessonEndKeys.completedGoals,
            icon: CanvasSymbols.taskAlt,
            label: l.licaoCursoConcluidoMetas,
            onPressed: onGoals,
          ),
          BusyButton(
            buttonKey: LessonEndKeys.completedCatalog,
            style: BusyButtonStyle.outlined,
            label: l.licaoCursoConcluidoCatalogo,
            onPressed: onCatalog,
          ),
        ],
      ),
    );
  }
}

class _Diploma extends StatelessWidget {
  const _Diploma({required this.completion, super.key});
  final CourseCompletion completion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Column(
        children: [
          Text(
            l.licaoDiplomaMarcaPilares,
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            completion.studentName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.licaoCursoConcluidoTexto(completion.chapters, completion.lessons),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '${completion.dateLabel} · ${completion.teacherName}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
