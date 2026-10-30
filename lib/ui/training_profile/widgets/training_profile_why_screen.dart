import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/keys/training_profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/empty_state.dart';

/// Authored Canvas explanation. Other openings have no authored explanation yet.
class TrainingProfileWhyScreen extends StatelessWidget {
  const TrainingProfileWhyScreen({
    required this.onClose,
    this.openingName,
    super.key,
  });
  final VoidCallback onClose;
  final String? openingName;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      key: TrainingProfileKeys.why,
      appBar: LucenaAppBar(
        toolbarHeight: 64,
        centerTitle: true,
        title: Text(
          openingName == null
              ? t.trainingProfileWhyLondonTitle
              : t.trainingProfileWhyTitle(openingName!),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          key: TrainingProfileKeys.whyClose,
          onPressed: onClose,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(CanvasSymbols.close),
        ),
      ),
      body: SafeArea(
        top: false,
        child: openingName != null
            ? Center(
                child: EmptyState(
                  icon: CanvasSymbols.autoStories,
                  message: t.trainingProfilePresentationUnavailable,
                ),
              )
            : ListView(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => PositionBoard(
                      boardKey: TrainingProfileKeys.whyBoard,
                      fen: 'rnbqkb1r/ppp1pppp/5n2/3p4/3P1B2/5N2/PPP1PPPP/RN1QKB1R b KQkq - 1 3',
                      size: constraints.maxWidth,
                      orientation: Side.white,
                      coordinates: true,
                      radius: 0,
                      // Canvas illustration highlight; not a move-history assertion.
                      lastMove: Move.parse('c1f4'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Text(
                          t.trainingProfileWhyLondonPlan,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(height: 1.5, letterSpacing: 0),
                        ),
                        Text(
                          t.trainingProfileWhyLondonStats,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(height: 1.5, letterSpacing: 0),
                        ),
                        Text(
                          t.trainingProfileWhyLondonLink,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                height: 20 / 14,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
