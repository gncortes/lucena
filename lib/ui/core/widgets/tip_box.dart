import 'package:flutter/material.dart';

import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';

/// A dica em caixa (canvas `CompAviso`, tipo dica): fundo
/// `secondaryContainer`, ícone e texto pequeno.
class TipBox extends StatelessWidget {
  const TipBox({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info,
            size: AppIconSize.button,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
