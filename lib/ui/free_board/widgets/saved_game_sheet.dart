import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/game_snapshot.dart';
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

/// A partida guardada como o aviso a mostra: onde parou e contra quem.
typedef SavedGame = ({
  GameSnapshot snapshot,
  Position position,
  Move? lastMove,
  Character? character,
});

/// O tabuleiro livre e a partida em andamento usam o mesmo lugar. Com uma
/// partida guardada (lances ou relógio), pergunta antes se o jogador volta a
/// ela ou começa um tabuleiro novo (decisão 1 do Gabriel, PropV1Decisao01b,
/// forma a). Fechar a folha sem escolher não abre nada.
Future<void> openFreeBoard(BuildContext context) async {
  final saved = await _savedGame(context);
  if (!context.mounted) return;
  if (saved == null) {
    context.go(Routes.freeBoard);
    return;
  }
  final keep = await showSavedGameSheet(context, saved);
  if (!context.mounted || keep == null) return;
  // A partida nova grava por cima da guardada.
  context.go(
    keep ? Routes.freeBoard : Routes.freeBoardAt(GameRules.initial.fen),
  );
}

// Sem os repositórios à mão (telas testadas sozinhas), não há partida.
Future<SavedGame?> _savedGame(BuildContext context) async {
  final OngoingGameRepository games;
  final CharacterRepository characters;
  try {
    games = context.read<OngoingGameRepository>();
    characters = context.read<CharacterRepository>();
  } on ProviderNotFoundException {
    return null;
  }
  return loadSavedGame(games, characters);
}

/// A partida guardada, se houver algo a perder nela; nulo se não houver.
Future<SavedGame?> loadSavedGame(
  OngoingGameRepository games,
  CharacterRepository characters,
) async {
  final snapshot = await games.load();
  if (snapshot == null) return null;
  if (snapshot.moves.isEmpty && snapshot.clock == null) return null;
  var position = GameRules.fromFen(snapshot.startFen);
  if (position == null) return null;
  Move? lastMove;
  for (final uci in snapshot.moves) {
    final move = Move.parse(uci);
    final played = move == null ? null : GameRules.play(position!, move);
    if (played == null) break;
    position = played.position;
    lastMove = move;
  }
  final mode = snapshot.mode;
  final character = switch (mode.opponent) {
    OpponentKind.maia => (await characters.characters()).forLevel(mode.level),
    OpponentKind.stockfish => Character.stockfish,
    OpponentKind.twoPlayers => null,
  };
  return (
    snapshot: snapshot,
    position: position!,
    lastMove: lastMove,
    character: character,
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
