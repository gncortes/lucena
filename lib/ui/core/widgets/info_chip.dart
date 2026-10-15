import 'package:flutter/material.dart';

import '../theme/app_shape.dart';

/// O chip informativo do app (T73, D15; canvas CatalogoControles seção 4,
/// `CompChip` informativo): pílula de 28 com ícone opcional e uma linha de
/// texto, para ritmo, nível, objetivo e posição. Não é botão. Tem três tons:
/// contorno (padrão), [filled] (cinza cheio) ou cores próprias
/// ([background]/[foreground]).
class InfoChip extends StatelessWidget {
  const InfoChip({
    required this.label,
    this.icon,
    this.filled = false,
    this.background,
    this.foreground,
    super.key,
  });

  /// A altura do artboard; o texto maior só cresce a caixa.
  static const height = 28.0;

  final String label;
  final IconData? icon;
  final bool filled;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tinted = background != null;
    final color =
        foreground ?? (filled ? colors.onSurface : colors.onSurfaceVariant);
    return Container(
      constraints: const BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: background ?? (filled ? colors.surfaceContainerHighest : null),
        border: filled || tinted
            ? null
            : Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (icon != null)
            ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: filled ? 14 : 13,
                fontWeight: filled ? FontWeight.w700 : null,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
