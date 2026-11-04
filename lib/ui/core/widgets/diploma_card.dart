import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// O diploma (canvas `CompDiploma`): marca, "Diploma", nome do aluno, o texto
/// do que concluiu, um resumo opcional e, embaixo, data e professor sobre um
/// traço. Quem usa passa os textos já prontos.
class DiplomaCard extends StatelessWidget {
  const DiplomaCard({
    required this.brand,
    required this.name,
    required this.text,
    required this.date,
    required this.teacher,
    this.summary,
    this.nameKey,
    super.key,
  });

  final String brand, name, text, date, teacher;
  final String? summary;
  final Key? nameKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summary = this.summary;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.large),
        side: BorderSide(color: colors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppShape.medium),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: AppIconSize.illustration,
                color: colors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                brand.toUpperCase(),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.graduationDiploma, style: context.bigNumber),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.graduationAwardedTo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                name,
                key: nameKey,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (summary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                spacing: AppSpacing.lg,
                children: [
                  Expanded(
                    child: _SignatureLine(
                      value: date,
                      label: l10n.graduationDate,
                    ),
                  ),
                  Expanded(
                    child: _SignatureLine(
                      value: teacher,
                      label: l10n.graduationTeacher,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.value, required this.label});

  final String value, label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Divider(),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
