import 'package:flutter/material.dart';

import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';

/// Um caminho da tela inicial: o que dá para fazer no app, com o nome e uma
/// linha dizendo o que acontece ali.
class PathCard extends StatelessWidget {
  const PathCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppShape.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppShape.medium),
                ),
                child: Icon(icon, color: colors.onSecondaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.cardTitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
