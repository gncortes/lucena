import 'package:flutter/material.dart';

import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Um cartão de escolha única, com ícone, título, texto e o rádio no fim:
/// os de "O que você quer fazer?" e "Seu nível".
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppShape.medium),
      side: selected
          ? BorderSide(color: colors.primary, width: 2)
          : BorderSide(color: colors.outlineVariant),
    );
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? colors.primaryContainer
            : colors.surfaceContainerLowest,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Icon(icon, size: AppIconSize.large, color: colors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.cardTitle),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
