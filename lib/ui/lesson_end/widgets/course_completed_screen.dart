import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/survey.dart';
import '../../../domain/models/training/lesson_end.dart';
import '../../core/keys/lesson_end_keys.dart';
import '../../core/share/share_button.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/diploma_card.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/widgets/about_screen.dart';
import '../../survey/widgets/survey_invite_card.dart';
import 'lesson_end_parts.dart';

/// Curso concluído, o diploma (H-LIC-53, canvas `CursoConcluido`): confete,
/// o diploma com o nome do aluno, a fala do Viktor, o convite da Opinião e
/// "Ver as metas" / "Ver o catálogo". Sem nome, o diploma não é gerado.
class CourseCompletedScreen extends StatefulWidget {
  const CourseCompletedScreen({
    required this.completion,
    required this.teacher,
    required this.onGoals,
    required this.onCatalog,
    required this.onClose,
    super.key,
  });

  final CourseCompletion completion;
  final Character teacher;
  final VoidCallback onGoals, onCatalog, onClose;

  @override
  State<CourseCompletedScreen> createState() => _CourseCompletedScreenState();
}

class _CourseCompletedScreenState extends State<CourseCompletedScreen> {
  // O diploma que vira imagem ao compartilhar.
  final _diploma = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final completion = widget.completion;
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      key: LessonEndKeys.completed,
      appBar: LessonEndClose(
        buttonKey: LessonEndKeys.completedClose,
        onClose: widget.onClose,
        actions: [
          ShareIconButton(
            key: LessonEndKeys.completedShare,
            boundary: _diploma,
            tooltip: l.licaoCursoConcluidoCompartilhar,
            footer: 'Lucena · ${l.homeTagline}',
            fileName: 'lucena-pilares.png',
            text: l.licaoCursoConcluidoShareText(
              AboutScreen.websiteFor(language).toString(),
            ),
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
                  RepaintBoundary(
                    key: _diploma,
                    child: ColoredBox(
                      color: theme.scaffoldBackgroundColor,
                      child: KeyedSubtree(
                        key: LessonEndKeys.completedDiploma,
                        child: DiplomaCard(
                          brand: l.licaoDiplomaMarcaPilares,
                          name: completion.studentName,
                          text: l.licaoCursoConcluidoTexto(
                            completion.chapters,
                            completion.lessons,
                          ),
                          date: completion.dateLabel,
                          teacher: completion.teacherName,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TeacherSpeech(
                    showSpeedBadge: false,
                    canvasTrainingBalloon: true,
                    teacher: widget.teacher,
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
            onPressed: widget.onGoals,
          ),
          BusyButton(
            buttonKey: LessonEndKeys.completedCatalog,
            style: BusyButtonStyle.outlined,
            label: l.licaoCursoConcluidoCatalogo,
            onPressed: widget.onCatalog,
          ),
        ],
      ),
    );
  }
}
