import 'package:flutter/material.dart';

import '../../../domain/use_cases/race_diagnosis.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';

/// Antes de [RaceDiagnosis.neededRuns] Corridas (canvas V2 · Ligações, L5):
/// quantas já foram, a barra e quantas faltam para o desempenho por final.
class RaceProgressCard extends StatelessWidget {
  const RaceProgressCard({required this.diagnosis, super.key});

  final RaceDiagnosis diagnosis;

  static const _barHeight = 8.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const total = RaceDiagnosis.neededRuns;
    // Com as Corridas feitas mas sem problemas bastantes de nenhum final,
    // ainda falta uma.
    final done = diagnosis.runs.clamp(0, total - 1);
    return Card(
      key: RaceKeys.diagnosisProgress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Row(
              spacing: AppSpacing.sm,
              children: [
                Icon(Icons.troubleshoot, color: colors.primary),
                Expanded(
                  child: Text(
                    l10n.racePerformanceLine,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  l10n.raceProgressCount(done, total),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Row(
              spacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < total; i++)
                  Expanded(
                    child: Container(
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color: i < done
                            ? colors.primary
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(_barHeight),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              l10n.raceProgressMissing(total - done),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
