import 'package:flutter/material.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../domain/use_cases/game_feedback.dart';
import '../../achievements/widgets/achievement_ui.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../view_models/game_reporter.dart';

/// Depois da partida: quanto o rating mudou e o que o jogador conquistou
/// ("Você venceu o Maia 2600 pela primeira vez", "Novo recorde").
class ReportPanel extends StatelessWidget {
  const ReportPanel({required this.report, super.key});

  final GameReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final before = report.before;
    final after = report.after;
    final achievements = {for (final a in report.achievements) a.id: a};
    final rows = <Widget>[
      if (before != null && after != null)
        _Row(
          key: FreeBoardKeys.ratingChange,
          icon: after.rounded >= before.rounded
              ? Icons.trending_up
              : Icons.trending_down,
          text: l10n.reportRating(
            after.rounded,
            _signed(after.rounded - before.rounded),
          ),
        ),
      for (final (index, item) in report.feedback.indexed)
        _Row(
          key: FreeBoardKeys.feedback(index),
          icon: item.kind == FeedbackKind.achievement
              ? achievements[item.achievementId]?.iconData ?? Icons.emoji_events
              : Icons.celebration_outlined,
          text: feedbackText(l10n, item, achievements),
          highlight: true,
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      key: FreeBoardKeys.report,
      constraints: const BoxConstraints(maxHeight: 132),
      child: Material(
        color: colors.surfaceContainerLow,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(children: rows),
        ),
      ),
    );
  }

  static String _signed(int change) => change > 0 ? '+$change' : '$change';
}

/// A mensagem de evolução, em palavras.
String feedbackText(
  AppLocalizations l10n,
  GameFeedback item,
  Map<String, Achievement> achievements,
) {
  final stockfish = OpponentKind.stockfish.label(l10n);
  return switch (item.kind) {
    FeedbackKind.firstWinAgainstLevel => l10n.feedbackFirstWin(
      OpponentKind.maia.label(l10n, level: item.level),
    ),
    FeedbackKind.firstWinAgainstStockfish => l10n.feedbackFirstWin(stockfish),
    FeedbackKind.rungCompleted => l10n.feedbackRungCompleted(
      rungLabel(l10n, item.rungId),
    ),
    FeedbackKind.journeyCompleted => l10n.journeyFinished,
    FeedbackKind.newSpeedrunRecord => l10n.feedbackNewRecord(
      RunTimeFormat.format(item.time ?? Duration.zero),
    ),
    FeedbackKind.speedrunImproved => l10n.feedbackImproved(
      RunTimeFormat.format(item.improvedBy ?? Duration.zero),
    ),
    FeedbackKind.stageRecord => l10n.feedbackStageRecord(
      item.rungId == OpponentKind.stockfish.code
          ? stockfish
          : OpponentKind.maia.label(l10n, level: item.level),
    ),
    FeedbackKind.achievement => l10n.feedbackAchievement(
      achievements[item.achievementId]?.title(l10n) ?? '',
    ),
  };
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.text,
    this.highlight = false,
    super.key,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: highlight ? color : null,
                fontWeight: highlight ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
