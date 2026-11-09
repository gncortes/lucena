import 'package:flutter/material.dart';

import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// O cartão azul de destaque (canvas DSeuJogo "Seu estilo" e DPilaresEslava,
/// oferta): fundo `secondaryContainer`, raio [AppShape.large], padding
/// [AppSpacing.lg], ícone e título no alto e o conteúdo embaixo. Com [onTap],
/// o cartão inteiro abre.
class CartaoDestaque extends StatelessWidget {
  const CartaoDestaque({
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
    final cores = theme.colorScheme;
    final corpo = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: cores.onSecondaryContainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: AppIconSize.notice, color: cores.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppWeight.medium,
                      color: cores.onSecondaryContainer,
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
      color: cores.secondaryContainer,
      borderRadius: BorderRadius.circular(AppShape.large),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? corpo : InkWell(onTap: onTap, child: corpo),
    );
  }
}
