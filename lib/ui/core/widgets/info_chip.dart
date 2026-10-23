import 'package:flutter/material.dart';

import '../keys/core_keys.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';

/// O chip informativo do app (canvas `CompChip` info): caixa de 32 (28 no
/// [compact]) com raio 8, sem borda, ícone opcional e uma linha de texto,
/// para ritmo, nível, objetivo e posição. Não é botão. Os selos coloridos
/// usam a mesma caixa, com [background]/[foreground].
class InfoChip extends StatelessWidget {
  const InfoChip({
    required this.label,
    this.icon,
    this.compact = false,
    this.outlined = false,
    this.background,
    this.foreground,
    super.key,
  });

  static const height = 32.0;
  static const compactHeight = 28.0;

  final String label;
  final IconData? icon;
  final bool compact;

  /// Só o contorno (outline-variant), sem fundo: nível e Maratona do speedrun.
  final bool outlined;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = foreground ?? colors.onSurface;
    return Container(
      key: CoreKeys.infoChip,
      constraints: BoxConstraints(minHeight: compact ? compactHeight : height),
      // 8 do lado do ícone, 16 do outro.
      padding: EdgeInsetsDirectional.only(
        start: icon == null ? 16 : 8,
        end: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: outlined ? null : background ?? colors.surfaceContainer,
        border: outlined ? Border.all(color: colors.outlineVariant) : null,
        borderRadius: BorderRadius.circular(AppShape.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          if (icon != null)
            ExcludeSemantics(
              child: Icon(icon, size: AppIconSize.small, color: color),
            ),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
