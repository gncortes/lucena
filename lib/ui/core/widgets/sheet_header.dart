import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

/// O cabeçalho de toda folha (E1.08, D20; canvas `CompCabecalhoFolha`): margem
/// 24 dos lados, título em `titleLarge`, 24 até a dica e 16 até o conteúdo.
/// Com [trailing] (uma ação em texto, como "Limpar"), a direita fica 12,
/// pelo alvo de toque do botão. A alça e o ✕ são da moldura da folha.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    required this.title,
    this.hint,
    this.trailing,
    this.titleMaxLines,
    this.leading,
    super.key,
  });

  final String title;

  /// Antes do título (o retrato de quem fala, por exemplo).
  final Widget? leading;

  /// Limite de linhas do título (a página externa traz títulos longos).
  final int? titleMaxLines;
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = this.hint;
    return Padding(
      key: SheetKeys.header,
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        0,
        trailing == null ? AppSpacing.xl : AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Com o retrato ao lado, o texto de apoio fica junto do título.
              spacing: leading == null ? AppSpacing.xl : AppSpacing.xs,
              children: [
                Text(
                  title,
                  key: SheetKeys.title,
                  maxLines: titleMaxLines,
                  overflow: titleMaxLines == null
                      ? null
                      : TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                if (hint != null)
                  Text(
                    hint,
                    key: SheetKeys.hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A alça da folha: 32×4, no tom do texto secundário a 40%. Uma só para a
/// moldura padrão, a folha da lição e a do Viktor.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: AppSheet.handleSize.width,
    height: AppSheet.handleSize.height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurfaceVariant
          .withValues(alpha: .4),
      borderRadius: BorderRadius.circular(AppShape.hairline),
    ),
  );
}
