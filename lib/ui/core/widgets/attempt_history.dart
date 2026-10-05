import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/attempt.dart';
import '../l10n/l10n.dart';
import '../opponent/opponent_ui.dart';

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
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
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
      children.add(
        ListTile(
          key: attemptKey(index),
          dense: true,
          leading: Icon(
            attempt.fulfilled ? Icons.check_circle : Icons.cancel_outlined,
            color: attempt.fulfilled ? colors.primary : colors.error,
          ),
          title: Text(switch (attempt.outcome) {
            AttemptOutcome.win => l10n.attemptWin,
            AttemptOutcome.draw => l10n.attemptDraw,
            AttemptOutcome.loss => l10n.attemptLoss,
          }),
          subtitle: Text(
            l10n.attemptDetails(
              attempt.opponent.label(l10n, level: attempt.opponentLevel),
              date.format(playedAt),
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
