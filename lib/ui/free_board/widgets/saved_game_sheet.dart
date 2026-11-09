import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/saved_game.dart';
import '../../../domain/models/saved_game.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/sheet_header.dart';

export '../../../domain/models/saved_game.dart';

/// O tabuleiro livre e a partida em andamento usam o mesmo lugar. Com uma
/// partida guardada (lances ou relógio), pergunta antes se o jogador volta a
/// ela ou começa um tabuleiro novo (decisão 1 do Gabriel, PropV1Decisao01b,
/// forma a). Fechar a folha sem escolher não abre nada.
Future<void> openFreeBoard(
  BuildContext context, {
  bool preserveOrigin = false,
}) async {
  Future<void> open(String route) async {
    if (preserveOrigin) {
      await context.push(route);
    } else {
      context.go(route);
    }
  }

  final saved = await readSavedGame(context);
  if (!context.mounted) return;
  if (saved == null) {
    await open(Routes.freeBoard);
    return;
  }
  final keep = await showSavedGameSheet(context, saved);
  if (!context.mounted || keep == null) return;
  // A partida nova grava por cima da guardada.
  await open(
    keep ? Routes.freeBoard : Routes.freeBoardAt(GameRules.initial.fen),
  );
}

/// A folha da partida guardada: verdadeiro volta a ela, falso começa um
/// tabuleiro novo, nulo fecha sem escolher.
Future<bool?> showSavedGameSheet(
  BuildContext context,
  SavedGame saved,
) => showLucenaSheet<bool>(
  context,
  sheetKey: FreeBoardKeys.savedGameSheet,
  builder: (context) {
    final l10n = context.l10n;
    const size = Size.fromHeight(kButtonHeight);
    final text = AppButtonText.footer(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.savedGameTitle, hint: l10n.savedGameHint),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [
                  _SavedGameCard(saved),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: FreeBoardKeys.savedGameContinue,
                    style: FilledButton.styleFrom(
                      minimumSize: size,
                      textStyle: text,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => Navigator.of(context).pop(true),
                    label: Text(
                      l10n.savedGameContinue,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  OutlinedButton.icon(
                    key: FreeBoardKeys.savedGameNew,
                    style: OutlinedButton.styleFrom(
                      minimumSize: size,
                      textStyle: text,
                    ),
                    icon: const Icon(Icons.add),
                    onPressed: () => Navigator.of(context).pop(false),
                    label: Text(l10n.savedGameNew, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);

// O cartão da partida: minitabuleiro, adversário, modo e onde parou.
class _SavedGameCard extends StatelessWidget {
  const _SavedGameCard(this.saved);

  static const _board = 96.0;

  final SavedGame saved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final snapshot = saved.snapshot;
    final mode = snapshot.mode;
    final character = saved.character;
    final opponent = switch (mode.opponent) {
      OpponentKind.maia when character != null => l10n.characterNameLevel(
        character.name,
        mode.level ?? character.level,
      ),
      _ => mode.opponent.label(l10n, level: mode.level),
    };
    final parts = mode.positionId?.split('.');
    final endgame = parts != null && parts.length > 1
        ? endgameName(l10n, parts[1])
        : null;
    final kind = mode.isSpeedrun
        ? l10n.speedrunTitle
        : mode.challengeId != null
        ? l10n.journeyTitle
        : mode.goal != null
        ? l10n.homeTrain
        : l10n.freeBoardTitle;
    final side = mode.opponent.isMachine ? mode.userSide ?? Side.white : null;
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Container(
      key: FreeBoardKeys.savedGameCard,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          PositionBoard(
            fen: saved.position.fen,
            size: _board,
            orientation: snapshot.orientation,
            lastMove: saved.lastMove,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Row(
                  spacing: AppSpacing.sm,
                  children: [
                    if (character != null)
                      CharacterAvatar(
                        character: character,
                        size: CharacterAvatar.mini,
                      )
                    else
                      Icon(
                        mode.opponent.icon,
                        size: AppIconSize.button,
                        color: colors.onSurfaceVariant,
                      ),
                    Expanded(
                      child: Text(opponent, style: theme.textTheme.titleSmall),
                    ),
                  ],
                ),
                Text(
                  endgame == null ? kind : l10n.savedGameMode(kind, endgame),
                  style: secondary,
                ),
                Text(
                  l10n.savedGamePlace(
                    side?.name ?? 'none',
                    saved.position.fullmoves,
                  ),
                  style: secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
