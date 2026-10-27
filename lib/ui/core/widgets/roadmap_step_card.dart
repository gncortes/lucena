import 'package:flutter/material.dart';

import '../theme/app_icon_size.dart';
import '../theme/app_spacing.dart';

/// Um passo de roteiro (canvas `CompPassoRoteiro`): o número num círculo (o
/// primeiro em destaque), o título, a linha de apoio e o ícone do tipo de
/// aula. O "Seu roteiro" do teste de nível e os passos da aula gratuita do
/// link de campanha (T84).
class RoadmapStepCard extends StatelessWidget {
  const RoadmapStepCard({
    required this.index,
    required this.title,
    required this.icon,
    this.subtitle,
    super.key,
  });

  /// A posição do passo, a partir de 0: o 0 fica em destaque.
  final int index;
  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final first = index == 0;
    final subtitle = this.subtitle;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: first
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              foregroundColor: first
                  ? colors.onPrimary
                  : colors.onSurfaceVariant,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: first ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              icon,
              size: AppIconSize.button,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
