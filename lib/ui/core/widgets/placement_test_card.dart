import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

/// O convite para o teste de nível ("Já sabe jogar? Faça o teste..."), para
/// quem ainda não fez: o mesmo cartão na Escola e nos Finais. [label] é o
/// texto do convite e [tapKey] fica no toque.
class PlacementTestCard extends StatelessWidget {
  const PlacementTestCard({
    required this.label,
    required this.onTap,
    required this.tapKey,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Key tapKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: InkWell(
        key: tapKey,
        borderRadius: BorderRadius.circular(AppShape.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(Icons.quiz_outlined, color: colors.onSecondaryContainer),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: colors.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
