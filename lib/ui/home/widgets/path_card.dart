import 'package:flutter/material.dart';

/// Um caminho da tela inicial: o que dá para fazer no app, com o nome e uma
/// linha dizendo o que acontece ali.
class PathCard extends StatelessWidget {
  const PathCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.highlighted = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  /// O caminho indicado para o jogador agora: ganha a cor de destaque.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = highlighted
        ? colors.primaryContainer
        : colors.surfaceContainerHigh;
    final foreground = highlighted
        ? colors.onPrimaryContainer
        : colors.onSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: highlighted
                      ? colors.primary
                      : colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: highlighted
                      ? colors.onPrimary
                      : colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: highlighted
                            ? foreground.withValues(alpha: 0.85)
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: highlighted ? foreground : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
