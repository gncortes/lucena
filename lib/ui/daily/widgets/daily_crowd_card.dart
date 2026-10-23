import 'package:flutter/material.dart';

import '../../../domain/models/crowd_stat.dart';
import '../../core/keys/daily_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';

/// O "quantos acertaram" do final do dia (E1.24, canvas
/// `PropV1RetencaoOntem`). No próprio dia: "Quantos acertaram? Amanhã.",
/// nunca um número. Num dia que passou: o número com a barra, ou "Poucas
/// pessoas jogaram ontem" abaixo de [CrowdStat.minTotal]; sem o número (não
/// saiu, sem rede), o cartão some.
class DailyCrowdCard extends StatelessWidget {
  const DailyCrowdCard({
    this.past = false,
    this.stat,
    this.gotItRight = false,
    super.key,
  });

  final bool past;
  final CrowdStat? stat;

  /// "Você está entre eles." quando cumpriu o objetivo.
  final bool gotItRight;

  @override
  Widget build(BuildContext context) {
    final stat = this.stat;
    if (past && stat == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final bold = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final Widget body;
    if (stat == null) {
      body = _Lines(
        title: Text(l10n.crowdTomorrowTitle, style: bold),
        text: Text(l10n.crowdTomorrowText, style: secondary),
      );
    } else if (!stat.enough) {
      body = _Lines(
        title: Text(
          l10n.crowdFewYesterday,
          key: DailyKeys.crowdFew,
          style: bold,
        ),
        text: Text(l10n.crowdFewText, style: secondary),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l10n.crowdPercent(stat.percent),
                  key: DailyKeys.crowdPercent,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(l10n.crowdPlayers(stat.total), style: secondary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppShape.full),
            child: LinearProgressIndicator(
              key: DailyKeys.crowdBar,
              value: stat.percent / 100,
              minHeight: 10,
              color: colors.primary,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          if (gotItRight) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.crowdYouAre,
              key: DailyKeys.crowdYouAre,
              style: secondary,
            ),
          ],
        ],
      );
    }
    return DecoratedBox(
      key: DailyKeys.crowdCard,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.groups, color: colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.title, required this.text});

  final Widget title;
  final Widget text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [title, text],
  );
}
