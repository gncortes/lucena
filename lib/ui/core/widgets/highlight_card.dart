import 'package:flutter/material.dart';

import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// O cartão azul de destaque (canvas DSeuJogo "Seu estilo" e DPilaresEslava,
/// oferta): fundo `secondaryContainer`, raio [AppShape.large], padding
/// [AppSpacing.lg], ícone e título no alto e o conteúdo embaixo. Com [onTap],
/// o cartão inteiro abre.
class HighlightCard extends StatelessWidget {
  const HighlightCard({
    required this.icon,
    required this.title,
    required this.child,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.onSecondaryContainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: AppIconSize.notice, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppWeight.medium,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(AppShape.large),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}
