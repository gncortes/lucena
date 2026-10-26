import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';

/// O cabeçalho de uma parte do curso (canvas `CompBandaModulo` estilo=titulo):
/// o rótulo opcional ("Parte 1"), o título e a contagem "4 de 6" à direita,
/// sem fundo.
class CoursePartHeader extends StatelessWidget {
  const CoursePartHeader({
    required this.title,
    required this.count,
    this.label,
    this.countKey,
    super.key,
  });

  final String? label;
  final String title;
  final String count;
  final Key? countKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = this.label;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: AppSpacing.md,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppWeight.strong,
                  ),
                ),
              ],
            ),
          ),
          Text(
            count,
            key: countKey,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
