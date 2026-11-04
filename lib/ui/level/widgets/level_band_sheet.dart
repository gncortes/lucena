import 'package:flutter/material.dart';

import '../../../domain/models/rating_level.dart';
import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../profile/widgets/rating_level_ui.dart';

/// Abre a folha "Rating aproximado"; devolve a faixa confirmada (ou nulo se
/// a pessoa só fechou). Usada no tour e no Chess.com sem rating.
Future<RatingLevel?> showLevelBandSheet(
  BuildContext context, {
  RatingLevel? initial,
}) => showLucenaSheet<RatingLevel>(
  context,
  sheetKey: LevelKeys.bandSheet,
  builder: (_) => _BandSheet(initial: initial),
);

/// A folha "Rating aproximado" (canvas `CompFolhaEscolha`): quatro faixas e
/// "Confirmar". Só grava em Confirmar; o X e o voltar do sistema só fecham.
class _BandSheet extends StatefulWidget {
  const _BandSheet({required this.initial});

  final RatingLevel? initial;

  @override
  State<_BandSheet> createState() => _BandSheetState();
}

class _BandSheetState extends State<_BandSheet> {
  static const _bands = [
    RatingLevel.beginner,
    RatingLevel.casual,
    RatingLevel.intermediate,
    RatingLevel.advanced,
  ];

  late RatingLevel _selected = widget.initial ?? RatingLevel.casual;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tourBandTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.tourBandHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final band in _bands)
            InkWell(
              key: LevelKeys.bandOption(band),
              onTap: () => setState(() => _selected = band),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: Semantics(
                    selected: _selected == band,
                    inMutuallyExclusiveGroup: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                band.name(l10n),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                band.describe(l10n),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selected == band
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: AppIconSize.standard,
                          color: _selected == band
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ActionsFooter(
            children: [
              FilledButton(
                key: LevelKeys.bandConfirm,
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(l10n.tourBandConfirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
