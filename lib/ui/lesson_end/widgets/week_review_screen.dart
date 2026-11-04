import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/training/lesson_end.dart';
import '../../core/keys/lesson_end_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/teacher_speech.dart';

/// Revisão da semana (H-LIC-52, canvas `RevisaoSemana`) e, no dia do torneio,
/// "Dia do torneio" (`DiaTorneio`), na mesma rota.
class WeekReviewScreen extends StatelessWidget {
  const WeekReviewScreen({
    required this.review,
    required this.teacher,
    required this.onOpen,
    required this.onStart,
    required this.onBack,
    super.key,
  });

  final WeekReview review;
  final Character teacher;

  /// Abre uma rota (teste do capítulo ou posição de aquecimento).
  final void Function(String path) onOpen;

  /// Começa a revisão pelo primeiro item.
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) =>
      review.isTournamentDay ? _tournament(context) : _review(context);

  AppBar _bar(BuildContext context, String title) => AppBar(
    toolbarHeight: 64,
    leading: IconButton(
      icon: const Icon(CanvasSymbols.arrowBack),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onBack,
    ),
    title: Text(title),
    centerTitle: false,
  );

  Widget _review(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final onContainer = theme.colorScheme.onPrimaryContainer;
    final tournament = review.tournament;
    return Scaffold(
      key: LessonEndKeys.review,
      appBar: _bar(context, l.licaoRevisaoTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.licaoRevisaoSemana(
                      review.week,
                      review.weekCount,
                      review.periodLabel,
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (tournament != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      tournament.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        height: 28 / 20,
                        fontWeight: FontWeight.w700,
                        color: onContainer,
                      ),
                    ),
                    Text(
                      l.licaoRevisaoDias(tournament.daysLeft),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l.licaoRevisaoIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            for (final item in review.items) ...[
              KeyedSubtree(
                key: ValueKey('${LessonEndKeys.reviewItem}.${item.path}'),
                child: LucenaCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => onOpen(item.path),
                  child: Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.chapter,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              l.licaoRevisaoItem(item.correct, item.total),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(CanvasSymbols.chevronRight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      bottomNavigationBar: ActionsFooter(
        children: [
          BusyButton(
            buttonKey: LessonEndKeys.reviewStart,
            label: l.licaoRevisaoComecar,
            onPressed: review.items.isEmpty ? null : onStart,
          ),
        ],
      ),
    );
  }

  Widget _tournament(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final tournament = review.tournament!;
    return Scaffold(
      key: LessonEndKeys.tournament,
      appBar: _bar(context, l.licaoTorneioTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            LucenaCard(
              child: Row(
                children: [
                  Icon(Icons.stadium, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l.licaoTorneioHoje(tournament.dateLabel),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TeacherSpeech(
              showSpeedBadge: false,
              canvasTrainingBalloon: true,
              teacher: teacher,
              avatarSize: 56,
              text: l.licaoTorneioFala(tournament.name),
              speechContext: SpeechContext.teaching,
            ),
            const SizedBox(height: 16),
            Text(
              l.licaoTorneioAquecer,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 12,
                height: 20 / 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            for (final (i, w) in review.warmups.indexed) ...[
              KeyedSubtree(
                key: ValueKey('${LessonEndKeys.tournamentPosition}.$i'),
                child: LucenaCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => onOpen(w.path),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.grid_view),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.licaoTorneioPosicao(i + 1),
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              l.licaoTorneioPosicaoInfo(w.chapter, w.side),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      bottomNavigationBar: ActionsFooter(
        stacked: true,
        children: [
          BusyButton(
            buttonKey: LessonEndKeys.tournamentWarmup,
            label: l.licaoTorneioAquecerAcao,
            onPressed: onStart,
          ),
          BusyButton(
            buttonKey: LessonEndKeys.tournamentNotNow,
            style: BusyButtonStyle.text,
            label: l.licaoAgoraNao,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}
