import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/widgets/character_avatar.dart';
import '../view_models/free_board_state.dart';
import '../view_models/talk_cubit.dart';

/// Uma fileira de jogadores com os seus relógios: a de um lado só (retrato,
/// nome e o relógio na ponta) ou a dos dois juntos, brancas primeiro.
class ClockRow extends StatelessWidget {
  const ClockRow({
    required this.sides,
    required this.state,
    required this.board,
    this.talk,
    super.key,
  });

  /// Altura da fileira, para a tela reservar o espaço do tabuleiro.
  static const height = 64.0;

  final List<Side> sides;
  final FreeBoardState state;

  /// A aparência escolhida: o retrato de cada lado é o peão dele, numa casa
  /// do tabuleiro.
  final BoardSettings board;

  /// O personagem do adversário: o retrato e o nome dele no lado da máquina.
  final TalkState? talk;

  @override
  Widget build(BuildContext context) {
    final single = sides.length == 1;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (index, side) in sides.indexed)
              if (single)
                Expanded(child: _player(context, side, showName: true))
              else
                // Com os dois juntos, o segundo fica espelhado: os retratos
                // nas pontas e os relógios no meio.
                _player(context, side, showName: false, mirrored: index == 1),
          ],
        ),
      ),
    );
  }

  Widget _player(
    BuildContext context,
    Side side, {
    required bool showName,
    bool mirrored = false,
  }) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final mode = state.mode;
    // O lado da máquina leva o nome dela (`Maia 1400`, `Stockfish`).
    final character = side == mode.machineSide ? talk?.character : null;
    final name = character != null
        ? character.name
        : side == mode.machineSide
        ? mode.opponent.label(l10n, level: mode.level)
        : side == Side.white
        ? l10n.sideWhite
        : l10n.sideBlack;
    final children = [
      if (character != null)
        CharacterAvatar(character: character)
      else
        _Portrait(side: side, board: board),
      const SizedBox(width: 12),
      if (showName)
        Expanded(
          child: ExcludeSemantics(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      _ClockBox(
        key: FreeBoardKeys.clock(side),
        side: side,
        time: state.timeOf(side),
        running: state.clock?.running == side,
      ),
    ];
    return Semantics(
      container: true,
      label: name,
      child: Row(
        mainAxisSize: showName ? MainAxisSize.max : MainAxisSize.min,
        children: mirrored ? children.reversed.toList() : children,
      ),
    );
  }
}

/// O retrato do lado: o peão dele, no conjunto de peças escolhido, sobre uma
/// casa escura do tabuleiro (onde as peças das duas cores aparecem bem, no
/// tema claro e no escuro).
class _Portrait extends StatelessWidget {
  const _Portrait({required this.side, required this.board});

  final Side side;
  final BoardSettings board;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    final pawn = side == Side.white ? PieceKind.whitePawn : PieceKind.blackPawn;
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: board.colors.scheme.darkSquare,
        borderRadius: BorderRadius.circular(6),
      ),
      // A imagem da peça já vem centralizada no próprio quadro.
      child: ExcludeSemantics(
        child: Image(
          image: board.pieces.assets[pawn]!,
          width: _size * 0.8,
          height: _size * 0.8,
        ),
      ),
    );
  }
}

/// O relógio de um lado: uma caixa compacta com o tempo alinhado à direita. A
/// caixa tem a cor do lado (clara para as brancas, escura para as pretas); a
/// de quem está na vez fica acesa, com o ícone de relógio, e a outra apagada.
class _ClockBox extends StatelessWidget {
  const _ClockBox({
    required this.side,
    required this.time,
    required this.running,
    super.key,
  });

  final Side side;
  final Duration time;

  /// O relógio que está correndo.
  final bool running;

  static const _width = 124.0;
  static const _height = 44.0;
  static const _light = Color(0xFFFFFFFF);
  static const _dark = Color(0xFF262421);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLow = time < ClockEngine.lowTime;
    final (background, foreground) = switch ((running && isLow, side)) {
      // Pouco tempo na vez de jogar: a caixa fica vermelha.
      (true, _) => (colors.error, colors.onError),
      (false, Side.white) => (_light, _dark),
      (false, Side.black) => (_dark, _light),
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: running ? 1 : 0.55,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _width,
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.outlineVariant),
        ),
        // Os números do relógio são sempre da esquerda para a direita.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: running ? 1 : 0,
                child: Icon(Icons.timer_outlined, size: 18, color: foreground),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    ClockFormat.format(time),
                    key: FreeBoardKeys.clockTime(side),
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      // Algarismos da mesma largura: o texto não treme ao
                      // contar.
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
