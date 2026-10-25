import 'package:flutter/material.dart';

import '../../theme/app_button.dart';
import '../../theme/app_shape.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';

/// O cartão "continuar" do topo da tela do curso (canvas `CompProximoFinal`
/// estilo=continuar): onde o aluno está, o título do capítulo ou da lição, o
/// resumo e o botão de largura total.
class CourseContinueCard extends StatelessWidget {
  const CourseContinueCard({
    required this.label,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
    this.summary,
    this.buttonKey,
    super.key,
  });

  /// "Parte I · capítulo 5", "Finais de peão · capítulo 2 de 3".
  final String label;
  final String title;
  final String? summary;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summary = this.summary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              // CompProximoFinal continuar: 20/26 em 700.
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                height: 26 / 20,
                fontWeight: AppWeight.strong,
              ),
            ),
            if (summary != null && summary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: kButtonHeightCompact,
              child: FilledButton.icon(
                key: buttonKey,
                onPressed: onPressed,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
