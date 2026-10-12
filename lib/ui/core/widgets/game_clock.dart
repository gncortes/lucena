import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../board/board_settings_ui.dart';
import '../theme/app_shape.dart';
import 'game_entrance.dart';
import 'time_display.dart';

/// Um jogador numa fileira de relógio: o retrato (o peão do lado), o nome e,
/// na ponta, o relógio ou de quem é a vez. Só apresentação: quem usa dá os
/// dados prontos (a partida e o às cegas).
class PlayerEntry {
  const PlayerEntry({
    required this.side,
    required this.name,
    this.time,
    this.running = false,
    this.clockKey,
    this.timeKey,
    this.turnLabel,
    this.turnKey,
    this.portrait,
  });

  final Side side;
  final String name;

  /// O tempo do relógio. Nulo: partida sem relógio.
  final Duration? time;
  final bool running;
  final Key? clockKey;
  final Key? timeKey;

  /// Sem relógio, a etiqueta de quem joga ("Sua vez"). Nula: nada.
  final String? turnLabel;
  final Key? turnKey;

  /// Retrato do personagem, quando existe; os demais jogadores usam o peão.
  final Widget? portrait;
}

/// Uma fileira de jogadores com os seus relógios: a de um lado só (retrato,
/// nome e o relógio na ponta) ou a dos dois juntos, espelhados (os retratos
/// nas pontas e os relógios no meio).
class PlayersRow extends StatelessWidget {
  const PlayersRow({
    required this.players,
    required this.board,
    this.enterClocks = false,
    this.compactClocks = false,
    super.key,
  });

  /// Altura da fileira, para a tela reservar o espaço do tabuleiro.
  static const height = 56.0;

  final List<PlayerEntry> players;

  /// A aparência escolhida: o retrato de cada lado é o peão dele, numa casa
  /// do tabuleiro.
  final BoardSettings board;

  /// Os relógios dão um pop na entrada da tela (a da partida).
  final bool enterClocks;

  /// Dois relógios junto do tabuleiro em telas pequenas.
  final bool compactClocks;

  @override
  Widget build(BuildContext context) {
    // Relógios juntos: um único retrato do adversário e seu nome, sem
    // repetir a foto numa faixa separada. Relógios compactos deixam o nome
    // legível mesmo em 360 dp; os demais chamadores mantêm a apresentação.
    if (players.length == 2 &&
        players.any((player) => player.portrait != null)) {
      final character = players.firstWhere((player) => player.portrait != null);
      return SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Semantics(
            container: true,
            label: character.name,
            child: Row(
              children: [
                character.portrait!,
                const SizedBox(width: 12),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      character.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                for (final (index, player) in players.indexed) ...[
                  if (index > 0) const SizedBox(width: 8),
                  if (player.time != null)
                    Semantics(
                      label: player.name,
                      child: _entering(
                        GameClock(
                          key: player.clockKey,
                          timeKey: player.timeKey,
                          side: player.side,
                          time: player.time!,
                          running: player.running,
                          width: 96,
                        ),
                      ),
                    )
                  else if (player.turnLabel != null)
                    TurnBadge(
                      label: player.turnLabel!,
                      labelKey: player.turnKey,
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    final single = players.length == 1;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (index, player) in players.indexed)
              if (single)
                Expanded(child: _player(context, player, showName: true))
              else
                _player(context, player, showName: false, mirrored: index == 1),
          ],
        ),
      ),
    );
  }

  Widget _entering(Widget clock) => enterClocks
      ? GameEntrance(part: GameEntrancePart.clock, child: clock)
      : clock;

  Widget _player(
    BuildContext context,
    PlayerEntry player, {
    required bool showName,
    bool mirrored = false,
  }) {
    final theme = Theme.of(context);
    final time = player.time;
    final turn = player.turnLabel;
    final children = [
      player.portrait ?? PlayerPortrait(side: player.side, board: board),
      const SizedBox(width: 12),
      if (showName)
        Expanded(
          child: ExcludeSemantics(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      if (time != null)
        _entering(
          GameClock(
            key: player.clockKey,
            timeKey: player.timeKey,
            side: player.side,
            time: time,
            running: player.running,
            width: compactClocks ? 96 : GameClock._width,
          ),
        )
      else if (turn != null)
        TurnBadge(label: turn, labelKey: player.turnKey),
    ];
    return Semantics(
      container: true,
      label: player.name,
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
class PlayerPortrait extends StatelessWidget {
  const PlayerPortrait({required this.side, required this.board, super.key});

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
        borderRadius: BorderRadius.circular(AppShape.small),
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

/// De quem é a vez, numa etiqueta na ponta da linha de quem joga.
class TurnBadge extends StatelessWidget {
  const TurnBadge({required this.label, this.labelKey, super.key});

  final String label;
  final Key? labelKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      child: Text(
        label,
        key: labelKey,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// O relógio de um lado (T51, A1: o mesmo na partida e no às cegas): uma
/// caixa compacta com o tempo alinhado à direita. A
/// caixa tem a cor do lado (clara para as brancas, escura para as pretas); a
/// de quem está na vez ganha contorno e o ícone, sem mudar a cor do lado.
class GameClock extends StatelessWidget {
  const GameClock({
    this.timeKey,
    required this.side,
    required this.time,
    required this.running,
    this.width = _width,
    super.key,
  });

  final Side side;
  final Duration time;
  final double width;

  /// A key do texto do tempo, para os testes lerem.
  final Key? timeKey;

  /// O relógio que está correndo.
  final bool running;

  static const _width = 124.0;
  static const _height = 44.0;
  static const _light = Color(0xFFFFFFFF);
  static const _dark = Color(0xFF262421);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = ClockFormat.format(time);
    final foreground = side == Side.white ? _dark : _light;
    // O adaptador conserva a geometria da faixa e os décimos do relógio;
    // o componente comum possui caixa, borda, ícone e cores por lado.
    return SizedBox(
      width: width,
      height: _height,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TimeDisplay(
          value: value,
          semanticsLabel: value,
          type: TimeDisplayType.clock,
          state: running ? TimeDisplayState.active : TimeDisplayState.normal,
          side: side,
          width: width,
          valueWidget: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: ClockText(
              value,
              key: timeKey,
              style: theme.textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O tempo do relógio com os décimos menores, como no Lichess (`0:05.7`).
class ClockText extends StatelessWidget {
  const ClockText(this.text, {this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final dot = text.lastIndexOf('.');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: dot < 0 ? text : text.substring(0, dot)),
          if (dot >= 0)
            TextSpan(
              text: text.substring(dot),
              style: TextStyle(fontSize: (style?.fontSize ?? 22) * 0.7),
            ),
        ],
      ),
      maxLines: 1,
      style: style,
    );
  }
}
