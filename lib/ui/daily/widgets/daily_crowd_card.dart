import 'package:flutter/material.dart';

import '../../core/keys/daily_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';

/// "Quantos acertaram? Amanhã.": no próprio dia, nunca um número.
class DailyCrowdCard extends StatelessWidget {
  const DailyCrowdCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.crowdTomorrowTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.crowdTomorrowText,
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
    );
  }
}
