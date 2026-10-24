import 'package:flutter/material.dart';

import '../../home/widgets/path_card.dart';
import '../keys/next_steps_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import 'lucena_sheet.dart';
import 'sheet_header.dart';

/// Uma opção do bloco [NextSteps].
class NextStep {
  const NextStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.recommended = false,
  });

  final String id;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  /// Leva o selo "Recomendado", o único do bloco.
  final bool recommended;
}

/// O bloco "Próximos passos" (canvas V2 · Ligações, `proximos`): o mesmo no
/// fim de todo fluxo; só as opções mudam. Cada opção é um [PathCard]: o ícone
/// no quadrado azul claro, o título, a descrição e a seta.
class NextSteps extends StatelessWidget {
  const NextSteps({required this.steps, super.key});

  final List<NextStep> steps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      key: NextStepsKeys.block,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text(
          l10n.nextStepsTitle,
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
            badge: step.recommended ? l10n.nextStepsRecommended : null,
            onTap: step.onTap,
          ),
      ],
    );
  }
}

/// A linha discreta "Como o Lucena usa seus resultados" (canvas `nota_dados`),
/// em todo fim de fluxo: abre a folha [showResultsInfo].
class ResultsInfoLine extends StatelessWidget {
  const ResultsInfoLine({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppShape.medium);
    return Material(
      key: NextStepsKeys.resultsInfo,
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onTap: () => showResultsInfo(context),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: ConstrainedBox(
            // O alvo de toque mínimo (canvas: 10 + 20 + 10 = 40 dp).
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  Icon(
                    Icons.insights,
                    size: AppIconSize.button,
                    color: colors.primary,
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.resultsInfoLine,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: AppIconSize.button,
                    color: colors.onSurfaceVariant,
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

/// A folha "Seus resultados contam" (canvas `PropV2LigaSobreDados`): para que
/// servem as Corridas, o que o app tem hoje e o que vem aí, e que tudo fica
/// salvo.
Future<void> showResultsInfo(BuildContext context) => showLucenaSheet<void>(
  context,
  sheetKey: NextStepsKeys.resultsSheet,
  closeKey: NextStepsKeys.resultsSheetClose,
  builder: (context) => const ResultsInfoSheet(),
);

/// O corpo da folha [showResultsInfo].
class ResultsInfoSheet extends StatelessWidget {
  const ResultsInfoSheet({super.key});

  /// Espaço entre os itens (canvas: `gap: 18px`).
  static const _itemGap = 18.0;

  /// Entre o ícone e o texto (canvas: `gap: 14px`).
  static const _iconGap = 14.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final items = [
      (Icons.timer, l10n.resultsInfoRace),
      (Icons.school, l10n.resultsInfoCourses),
      (Icons.insights, l10n.resultsInfoSaved),
    ];
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.resultsInfoTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: _itemGap,
              children: [
                for (final (index, (icon, text)) in items.indexed)
                  Row(
                    key: NextStepsKeys.resultsItem(index),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: _iconGap,
                    children: [
                      Icon(icon, color: color),
                      Expanded(
                        child: Text(text, style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
