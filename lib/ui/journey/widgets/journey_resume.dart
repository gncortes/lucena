import 'package:flutter/material.dart';

import '../../../config/view_models/saved_game.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';
import '../../free_board/widgets/saved_game_sheet.dart';

/// Só a partida do mesmo desafio pode substituir o caminho de jogar por retomar.
Future<SavedGame?> savedJourneyGame(
  BuildContext context,
  Challenge challenge,
) async {
  final saved = await readSavedGame(context);
  if (saved == null || GameRules.endOf(saved.position) != null) return null;
  final snapshot = saved.snapshot;
  final mode = snapshot.mode;
  if (mode.challengeId != challenge.id ||
      mode.isSpeedrun ||
      mode.fromLink ||
      snapshot.startFen != challenge.position.fen ||
      mode.positionId != challenge.position.id ||
      mode.opponent != challenge.opponent.kind ||
      mode.level != challenge.opponent.level ||
      mode.goal != challenge.goal) {
    return null;
  }
  return saved;
}

Future<bool> confirmJourneyRestart(BuildContext context) async {
  final l10n = context.l10n;
  return await showLucenaSheet<bool>(
        context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: l10n.journeyRestartTitle,
              hint: l10n.journeyRestartHint,
            ),
            ActionsFooter(
              stacked: true,
              margin: AppSpacing.xl,
              children: [
                FilledButton(
                  key: JourneyKeys.restartConfirm,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.journeyRestart),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.journeyKeepGame),
                ),
              ],
            ),
          ],
        ),
      ) ??
      false;
}
