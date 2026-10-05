import 'package:flutter/material.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../domain/use_cases/game_feedback.dart';
import '../../achievements/widgets/achievement_ui.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../view_models/game_reporter.dart';

/// Depois da partida: o que o jogador conquistou
/// ("Primeira vitória contra a Zuri", "Novo recorde").
class ReportPanel extends StatelessWidget {
  const ReportPanel({required this.report, super.key});

  final GameReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final achievements = {for (final a in report.achievements) a.id: a};
    if (report.feedback.isEmpty) return const SizedBox.shrink();
    final messages = [
      for (final (index, item) in report.feedback.indexed)
        if (item.kind != FeedbackKind.achievement) (index, item),
    ];
    final unlocked = [
      for (final (index, item) in report.feedback.indexed)
        if (item.kind == FeedbackKind.achievement) (index, item),
    ];
    return Padding(
      key: FreeBoardKeys.report,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Primeira vitória contra o Tito", recordes: em destaque, sem
          // caixa.
          for (final (index, item) in messages)
            _Message(
              key: FreeBoardKeys.feedback(index),
              text: feedbackText(l10n, item, achievements, report.characters),
            ),
          // As conquistas em cartões, com a medalha, entrando uma depois da
          // outra.
          if (unlocked.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 10, 4, 6),
              child: Text(
                l10n.achievementUnlocked,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final (order, (index, item)) in unlocked.indexed)
              _AchievementCard(
                key: FreeBoardKeys.feedback(index),
                order: order,
                achievement: achievements[item.achievementId],
                // O texto completo fica para o leitor de tela e os testes.
                spoken: feedbackText(
                  l10n,
                  item,
                  achievements,
                  report.characters,
                ),
                characters: report.characters,
              ),
          ],
        ],
      ),
    );
  }
}

/// A mensagem de evolução, em palavras.
String feedbackText(
  AppLocalizations l10n,
  GameFeedback item,
  Map<String, Achievement> achievements, [
  List<Character> characters = const [],
]) {
  final stockfish = OpponentKind.stockfish.label(l10n);
  return switch (item.kind) {
    FeedbackKind.firstWinAgainstLevel => l10n.feedbackFirstWin(
      levelName(l10n, characters, item.level),
    ),
    FeedbackKind.firstWinAgainstStockfish => l10n.feedbackFirstWin(stockfish),
    FeedbackKind.rungCompleted => l10n.feedbackRungCompleted(
      rungLabel(l10n, item.rungId, characters),
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
          : levelName(l10n, characters, item.level),
    ),
    FeedbackKind.achievement => l10n.feedbackAchievement(
      achievements[item.achievementId]?.title(l10n, characters) ?? '',
    ),
  };
}

/// Uma mensagem de evolução, com o confete.
class _Message extends StatelessWidget {
  const _Message({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma conquista nova: a medalha dourada, o nome e o que ela pede.
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.order,
    required this.achievement,
    required this.spoken,
    required this.characters,
    super.key,
  });

  /// A posição entre as conquistas novas: cada uma entra um pouco depois.
  final int order;
  final Achievement? achievement;
  final String spoken;
  final List<Character> characters;

  static const _gold = Color(0xFFF2B33D);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final achievement = this.achievement;
    final instant = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: instant
          ? Duration.zero
          : Duration(milliseconds: 450 + 150 * order),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: Semantics(
        container: true,
        label: spoken,
        excludeSemantics: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD976), _gold],
                  ),
                ),
                child: Icon(
                  achievement?.iconData ?? Icons.emoji_events,
                  color: const Color(0xFF5A3C00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement?.title(l10n, characters) ?? spoken,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (achievement != null)
                      Text(
                        achievement.description(l10n, characters),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
