import 'package:flutter/material.dart';

import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';

/// A folha "Como funciona" da Corrida (canvas SugP2CorridaIntroBFolha): as
/// quatro regras completas (o tempo vem da duração escolhida) e o "Entendi".
/// Abre pelo (i) da barra, na moldura única das folhas do app.
Future<void> showRaceHowSheet(BuildContext context, {required int minutes}) {
  return showLucenaSheet<void>(
    context,
    builder: (context) => _RaceHowSheet(minutes: minutes),
  );
}

class _RaceHowSheet extends StatelessWidget {
  const _RaceHowSheet({required this.minutes});

  /// A duração escolhida na abertura.
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: RaceKeys.howSheet,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.raceHowTitle),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Rule(
                  icon: Icons.timer,
                  title: l10n.raceRuleTimeTitle(minutes),
                  body: l10n.raceRuleTimeBody,
                ),
                _Rule(
                  icon: Icons.trending_up,
                  title: l10n.raceRuleHarderTitle,
                  body: l10n.raceRuleHarderBody,
                ),
                _Rule(
                  icon: Icons.close,
                  title: l10n.raceRuleErrorsTitle,
                  body: l10n.raceRuleErrorsBody,
                ),
                _Rule(
                  icon: Icons.bolt,
                  title: l10n.raceRuleShortestTitle,
                  body: l10n.raceRuleShortestBody,
                ),
              ],
            ),
          ),
        ),
        ActionsFooter(
          margin: AppSpacing.xl,
          children: [
            FilledButton(
              key: RaceKeys.howGotIt,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.raceHowGotIt),
            ),
          ],
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.medium),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(
                  icon,
                  size: AppIconSize.button,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
