import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

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

  /// A altura da barra (56 dos itens e 8 de respiro): a reserva do tabuleiro.
  static const height = 72.0;

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
    return ActionsBar(
      key: FreeBoardKeys.actionsBar,
      children: [
        if (training) ...[
          GameActionButton(
            buttonKey: FreeBoardKeys.resignButton,
            icon: Icons.flag_outlined,
            label: l10n.gameResign,
            onPressed: onResign,
          ),
          GameActionButton(
            buttonKey: FreeBoardKeys.drawButton,
            icon: Icons.handshake_outlined,
            label: l10n.freeBoardDraw,
            onPressed: onDraw,
          ),
        ] else ...[
          GameActionButton(
            buttonKey: FreeBoardKeys.flipButton,
            icon: Icons.swap_vert,
            label: l10n.freeBoardFlip,
            onPressed: onFlip,
          ),
          GameActionButton(
            buttonKey: FreeBoardKeys.clockButton,
            icon: Icons.av_timer_outlined,
            label: l10n.freeBoardClock,
            onPressed: onClock,
          ),
          GameActionButton(
            buttonKey: FreeBoardKeys.newGameButton,
            icon: Icons.add,
            label: l10n.freeBoardNewGame,
            onPressed: onNewGame,
          ),
        ],
        if (showSound)
          const Expanded(
            child: Center(heightFactor: 1, child: CharacterSoundButton()),
          ),
      ],
    );
  }
}

/// A faixa de ações da borda inferior: ícone e rótulo, sem fundo (E1.08, D18).
/// Os filhos são [GameActionButton]. A corrida usa a mesma, com um item só.
class ActionsBar extends StatelessWidget {
  const ActionsBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    child: Row(spacing: AppSpacing.xs, children: children),
  );
}

/// Uma ação da [ActionsBar].
class GameActionButton extends StatelessWidget {
  const GameActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.buttonKey,
    super.key,
  });

  /// A key do botão (a do toque nos testes).
  final Key? buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      // heightFactor: a barra tem a altura dos itens, não a da área.
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: SizedBox(
            height: 56,
            child: TextButton(
              key: buttonKey,
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppShape.large),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: AppIconSize.standard),
                  const SizedBox(height: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
