import 'package:flutter/material.dart';

import '../../home/widgets/path_card.dart';
import '../keys/next_steps_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';

/// Uma opção do bloco [NextSteps].
class NextStep {
  const NextStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.badge,
  });

  final String id;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final String? badge;
}

/// O bloco "E agora?" (canvas V2 · Ligações): o mesmo no fim de todo fluxo,
/// com o título e as opções de cada um, nos cartões dos caminhos.
class NextSteps extends StatelessWidget {
  const NextSteps({required this.title, required this.steps, super.key});

  final String title;
  final List<NextStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: NextStepsKeys.block,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final step in steps)
          PathCard(
            key: NextStepsKeys.option(step.id),
            icon: step.icon,
            title: step.title,
            body: step.body,
            badge: step.badge,
            onTap: step.onTap,
          ),
      ],
    );
  }
}

/// "Em breve no Lucena": quantos finais há hoje e o que vem aí.
class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: NextStepsKeys.comingSoon,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          Icon(Icons.upcoming, color: colors.onTertiaryContainer),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  l10n.comingSoonTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.comingSoonBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onTertiaryContainer,
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

/// A nota de que o que o jogador faz fica salvo e ajusta as sugestões.
class DataNote extends StatelessWidget {
  const DataNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      key: NextStepsKeys.dataNote,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Icon(Icons.insights, size: AppIconSize.button, color: color),
          Expanded(
            child: Text(
              context.l10n.dataNote,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
