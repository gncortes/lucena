import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../core/keys/lesson_end_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/teacher_speech.dart';
import 'lesson_end_parts.dart';

/// Oferta da demonstração depois do capítulo (H-LIC-51, canvas
/// `FimDemoOferta`). Quem decide se ela aparece é o `DemoOfferCubit`; a tela
/// de venda é da frente Venda e abre por nome em [onSeeCourse].
class DemoOfferScreen extends StatelessWidget {
  const DemoOfferScreen({
    required this.chapterNumber,
    required this.exerciseTitle,
    required this.correct,
    required this.total,
    required this.teacher,
    required this.onSeeCourse,
    required this.onNotNow,
    super.key,
  });

  final int chapterNumber, correct, total;
  final String exerciseTitle;
  final Character teacher;
  final VoidCallback onSeeCourse, onNotNow;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: LessonEndKeys.offer,
      appBar: LessonEndClose(
        buttonKey: LessonEndKeys.offerClose,
        onClose: onNotNow,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              const LessonEndBadge(icon: Icons.workspace_premium),
              const SizedBox(height: 12),
              Text(
                l.licaoOfertaTitle(chapterNumber),
                textAlign: TextAlign.center,
                style: endTitleStyle(context),
              ),
              const SizedBox(height: 4),
              Text(
                l.licaoOfertaResultado(exerciseTitle, correct, total),
                textAlign: TextAlign.center,
                style: endSubtitleStyle(context),
              ),
              const SizedBox(height: 20),
              TeacherSpeech(
                showSpeedBadge: false,
                canvasTrainingBalloon: true,
                teacher: teacher,
                avatarSize: 56,
                text: l.licaoOfertaFala,
                speechContext: SpeechContext.teaching,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppShape.card),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CanvasSymbols.editCalendar,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.licaoOfertaCardTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.licaoOfertaCardBody,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionsFooter(
        stacked: true,
        children: [
          BusyButton(
            buttonKey: LessonEndKeys.offerAction,
            label: l.licaoOfertaAcao,
            onPressed: onSeeCourse,
          ),
          BusyButton(
            buttonKey: LessonEndKeys.offerNotNow,
            style: BusyButtonStyle.text,
            label: l.licaoAgoraNao,
            onPressed: onNotNow,
          ),
        ],
      ),
    );
  }
}
