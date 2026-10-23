import 'package:flutter/material.dart';

import '../../../domain/use_cases/race_diagnosis.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/info_chip.dart';

/// O diagnóstico da Corrida (canvas V2 · Ligações, L5 e L6 com a variante B):
/// antes de [RaceDiagnosis.neededRuns] Corridas, a barra de quantas faltam;
/// depois, o ponto mais fraco em destaque, os outros fracos numa linha e os
/// que vão bem em chips verdes.
class RaceDiagnosisCard extends StatelessWidget {
  const RaceDiagnosisCard({required this.diagnosis, super.key});

  final RaceDiagnosis diagnosis;

  @override
  Widget build(BuildContext context) => Card(
    key: RaceKeys.diagnosis,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: diagnosis.ready
          ? _Ready(diagnosis: diagnosis)
          : _Progress(diagnosis: diagnosis),
    ),
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.diagnosis});

  final RaceDiagnosis diagnosis;

  static const _barHeight = 8.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const total = RaceDiagnosis.neededRuns;
    // Com as Corridas feitas mas sem problemas bastantes de nenhuma família,
    // ainda falta uma.
    final done = diagnosis.runs.clamp(0, total - 1);
    return Column(
      key: RaceKeys.diagnosisProgress,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            Icon(Icons.troubleshoot, color: colors.primary),
            Expanded(
              child: Text(
                l10n.raceDiagnosisTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.raceDiagnosisProgress(done, total),
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
          l10n.raceDiagnosisMissing(total - done),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.diagnosis});

  final RaceDiagnosis diagnosis;

  static const _iconBox = 44.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final weakest = diagnosis.weakest;
    final others = diagnosis.weak.skip(1).toList();
    final green = ChangeColors.of(context, up: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        if (weakest == null)
          Row(
            key: RaceKeys.diagnosisNoWeak,
            spacing: AppSpacing.sm,
            children: [
              Icon(Icons.check_circle, color: green),
              Expanded(
                child: Text(
                  l10n.raceDiagnosisNoWeak,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          )
        else
          Container(
            key: RaceKeys.diagnosisWeakest,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(AppShape.medium),
            ),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Container(
                  width: _iconBox,
                  height: _iconBox,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppShape.medium),
                  ),
                  child: Icon(Icons.priority_high, color: colors.error),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        l10n.raceDiagnosisWeakest,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        categoryName(l10n, weakest.category),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onErrorContainer,
                        ),
                      ),
                      Text(
                        l10n.raceDiagnosisErrors(weakest.errors, weakest.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (others.isNotEmpty)
          Text.rich(
            key: RaceKeys.diagnosisAlsoWeak,
            TextSpan(
              children: [
                TextSpan(
                  text: l10n.raceDiagnosisAlsoWeak,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      ' ${[for (final score in others) l10n.raceDiagnosisAlsoItem(categoryName(l10n, score.category), score.errors, score.total)].join(', ')}',
                ),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
        if (diagnosis.good.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.raceDiagnosisGood,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              for (final score in diagnosis.good)
                InfoChip(
                  key: RaceKeys.diagnosisGood(score.category),
                  icon: Icons.check,
                  label: categoryName(l10n, score.category),
                  compact: true,
                  background: green.withValues(alpha: 0.16),
                  foreground: green,
                ),
            ],
          ),
        Text(
          l10n.raceDiagnosisFooter(diagnosis.runs),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
