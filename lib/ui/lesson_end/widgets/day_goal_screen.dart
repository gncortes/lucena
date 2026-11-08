import 'package:flutter/material.dart';

import '../../core/motion/barra_que_enche.dart';
import '../../core/motion/entrada_de_resultado.dart';

import '../../../domain/models/training/lesson_end.dart';
import '../../core/keys/lesson_end_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_card.dart';
import 'lesson_end_parts.dart';

/// "Meta de hoje cumprida" no fim da última lição do dia (H-LIC-50, canvas
/// `PropV2LicaoFimMetaDia`): o cartão do plano, os capítulos concluídos e,
/// se o teste do capítulo ainda falta, "Fazer o teste agora".
class DayGoalScreen extends StatelessWidget {
  const DayGoalScreen({
    required this.summary,
    required this.onBack,
    this.onTest,
    super.key,
  });

  final DayGoalSummary summary;
  final VoidCallback onBack;

  /// Só aparece com o teste pendente.
  final VoidCallback? onTest;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final rowStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0,
    );
    Widget row(IconData icon, String text, {bool strong = false}) => Row(
      children: [
        Icon(icon, size: AppIconSize.button, color: strong ? primary : null),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: rowStyle?.copyWith(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      key: LessonEndKeys.dayGoal,
      appBar: LessonEndClose(
        buttonKey: LessonEndKeys.dayGoalClose,
        onClose: onBack,
      ),
      // H-ANI-25: selo, título, semana, o cartão do plano e os botões por
      // último.
      body: EntradaDeResultado(
        id:
            'meta-dia-${summary.week}-${summary.currentChapter}-'
            '${summary.lessonsDone}',
        estrela: const LessonEndBadge(icon: CanvasSymbols.taskAlt),
        titulo: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            l.licaoMetaDiaTitle,
            textAlign: TextAlign.center,
            style: endTitleStyle(context),
          ),
        ),
        subtitulo: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l.licaoMetaDiaSemana(
              summary.week,
              summary.weekCount,
              summary.daysLeft,
            ),
            textAlign: TextAlign.center,
            style: endSubtitleStyle(context),
          ),
        ),
        placar: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: KeyedSubtree(
            key: LessonEndKeys.dayGoalProgress,
            child: LucenaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  row(Icons.my_location, summary.currentChapter, strong: true),
                  const SizedBox(height: 8),
                  row(
                    CanvasSymbols.radioButtonUnchecked,
                    summary.testPending
                        ? l.licaoMetaDiaLicoesTeste(
                            summary.lessonsDone,
                            summary.lessonsTotal,
                          )
                        : l.licaoMetaDiaLicoes(
                            summary.lessonsDone,
                            summary.lessonsTotal,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final (i, f) in summary.chapterProgress.indexed)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                            // H-ANI-13: enche de 0 na entrada.
                            child: BarraQueEnche(
                              valor: f.clamp(0, 1).toDouble(),
                              altura: 6,
                              cor: f >= 1
                                  ? AppColors.trainingDayCorrect
                                  : primary,
                              corDoTrilho: AppColors.cardOutline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.licaoMetaDiaCapitulos(
                      summary.chaptersDone,
                      summary.chapterProgress.length,
                    ),
                    style: rowStyle?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        botoes: ActionsFooter(
          stacked: true,
          children: [
            BusyButton(
              buttonKey: LessonEndKeys.dayGoalBack,
              icon: CanvasSymbols.taskAlt,
              label: l.licaoVoltarMetas,
              onPressed: onBack,
            ),
            if (summary.testPending && onTest != null)
              BusyButton(
                buttonKey: LessonEndKeys.dayGoalTest,
                style: BusyButtonStyle.outlined,
                label: l.licaoMetaDiaTesteAgora,
                onPressed: onTest,
              ),
          ],
        ),
        montar: montarFimComBotoes,
      ),
    );
  }
}
