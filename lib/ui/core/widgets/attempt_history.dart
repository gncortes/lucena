import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../l10n/l10n.dart';
import '../opponent/opponent_ui.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_spacing.dart';
import 'goal_style.dart';

/// Partidas agrupadas por mês, da mais recente para a mais antiga, com o
/// título de cada mês.
class AttemptHistory extends StatelessWidget {
  const AttemptHistory({
    required this.attempts,
    required this.monthKey,
    required this.attemptKey,
    super.key,
  });

  /// Da mais recente para a mais antiga.
  final List<Attempt> attempts;
  final Key Function(int index) monthKey;
  final Key Function(int index) attemptKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final month = DateFormat.yMMMM(locale);
    final date = DateFormat.MMMd(locale).add_Hm();
    final children = <Widget>[];
    String? currentMonth;
    var months = 0;
    for (final (index, attempt) in attempts.indexed) {
      final playedAt = attempt.playedAt.toLocal();
      final label = month.format(playedAt);
      if (label != currentMonth) {
        currentMonth = label;
        children.add(
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              label,
              key: monthKey(months++),
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.primary,
              ),
            ),
          ),
        );
      }
      final (color, icon, result) = switch (attempt.outcome) {
        AttemptOutcome.win => (
          ChangeColors.of(context, up: true),
          Icons.emoji_events_rounded,
          l10n.attemptWin,
        ),
        AttemptOutcome.draw => (
          colors.onSurfaceVariant,
          Icons.handshake_rounded,
          l10n.attemptDraw,
        ),
        AttemptOutcome.loss => (
          ChangeColors.of(context, up: false),
          Icons.sentiment_dissatisfied_rounded,
          l10n.attemptLoss,
        ),
      };
      final clock = attempt.userClock;
      children.add(
        Card(
          key: attemptKey(index),
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // O resultado em destaque, na cor dele.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: AppIconSize.standard),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                        ),
                      ),
                      Text(
                        l10n.attemptDetails(
                          attempt.opponent.label(
                            l10n,
                            level: attempt.opponentLevel,
                          ),
                          date.format(playedAt),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (clock != null)
                  Text(
                    l10n.attemptClock(ClockFormat.format(clock)),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  attempt.fulfilled
                      ? Icons.check_circle
                      : Icons.cancel_outlined,
                  size: AppIconSize.button,
                  color: ChangeColors.of(context, up: attempt.fulfilled),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
