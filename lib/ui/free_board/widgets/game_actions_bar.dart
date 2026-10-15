import 'package:flutter/material.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import 'character_bar.dart';

/// As ações da partida ficam na borda inferior, fora das faixas dos jogadores.
class GameActionsBar extends StatelessWidget {
  const GameActionsBar({
    required this.training,
    this.onResign,
    this.onDraw,
    this.onFlip,
    this.onClock,
    this.onNewGame,
    this.showSound = false,
    super.key,
  });

  final bool training;
  final VoidCallback? onResign;
  final VoidCallback? onDraw;
  final VoidCallback? onFlip;
  final VoidCallback? onClock;
  final VoidCallback? onNewGame;
  final bool showSound;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: FreeBoardKeys.actionsBar,
      color: colors.surfaceContainerLow,
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              if (training) ...[
                _action(
                  context,
                  FreeBoardKeys.resignButton,
                  Icons.flag_outlined,
                  l10n.gameResign,
                  onResign,
                ),
                _action(
                  context,
                  FreeBoardKeys.drawButton,
                  Icons.handshake_outlined,
                  l10n.freeBoardDraw,
                  onDraw,
                ),
              ] else ...[
                _action(
                  context,
                  FreeBoardKeys.flipButton,
                  Icons.swap_vert,
                  l10n.freeBoardFlip,
                  onFlip,
                ),
                _action(
                  context,
                  FreeBoardKeys.clockButton,
                  Icons.av_timer_outlined,
                  l10n.freeBoardClock,
                  onClock,
                ),
                _action(
                  context,
                  FreeBoardKeys.newGameButton,
                  Icons.add,
                  l10n.freeBoardNewGame,
                  onNewGame,
                ),
              ],
              if (showSound)
                const Expanded(child: Center(child: CharacterSoundButton())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context,
    Key key,
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) => Expanded(
    child: SizedBox(
      height: 56,
      child: TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
