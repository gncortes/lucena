import 'package:flutter/material.dart';

import '../motion/opcao_selecionavel.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Um cartão de escolha única, com ícone, título, texto e o rádio no fim:
/// os de "O que você quer fazer?" e "Seu nível". A casca (fundo, borda,
/// rádio e a troca de 200 ms) é a [OpcaoSelecionavel] (H-ANI-30).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  /// Sem ícone, o texto começa na borda (o cartão do Chess.com).
  final IconData? icon;
  final String title;
  final String body;
  final bool selected;

  /// Nulo: a opção não marca (ex.: o teste sem o conteúdo baixado).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return OpcaoSelecionavel(
      selecionada: selected,
      aoTocar: onTap,
      child: Row(
        children: [
          if (icon case final icon?) ...[
            Icon(icon, size: AppIconSize.large, color: colors.primary),
            const SizedBox(width: AppSpacing.md),
          ],
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
        ],
      ),
    );
  }
}
