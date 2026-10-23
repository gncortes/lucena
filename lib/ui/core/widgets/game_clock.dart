import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
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
    this.isTurn = false,
    this.turnKey,
    this.portrait,
    this.detail,
    this.detailKey,
  });

  final Side side;
  final String name;

  /// O tempo do relógio. Nulo: partida sem relógio.
  final Duration? time;
  final bool running;
  final Key? clockKey;
  final Key? timeKey;

  /// Sem relógio, é a vez deste lado: o retrato leva o anel primário de 2 px
  /// (T73, D1; CompJogador, `marcaVez=anel`). Com relógio, quem marca a vez é
  /// o relógio aceso.
  final bool isTurn;

  /// A key do anel da vez, para os testes lerem.
  final Key? turnKey;

  /// Retrato do personagem, quando existe; os demais jogadores usam o peão.
  final Widget? portrait;

  /// A linha embaixo do nome (`Nível 1000`, o rating do jogador). Só aparece
  /// na fileira [PlayersRow.detailed].
  final String? detail;
  final Key? detailKey;
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
    this.detailed = false,
    super.key,
  });

  /// Altura da fileira, para a tela reservar o espaço do tabuleiro.
  static const height = 56.0;

  /// Altura da fileira com a linha de detalhe: retrato 44 com 12 em cima e
  /// embaixo (CompJogador, `padding: 12px 16px`).
  static const detailedHeight = 68.0;

  final List<PlayerEntry> players;

  /// A aparência escolhida: o retrato de cada lado é o peão dele, numa casa
  /// do tabuleiro.
  final BoardSettings board;

  /// Os relógios dão um pop na entrada da tela (a da partida).
  final bool enterClocks;

  /// Dois relógios junto do tabuleiro em telas pequenas.
  final bool compactClocks;

  /// A variante da partida V2 (CompJogador): 68 de altura, margem 16 e a
  /// linha de detalhe embaixo do nome. Desligada, a fileira de 56 de antes.
  final bool detailed;

  double get _height => detailed ? detailedHeight : height;
  double get _margin => detailed ? 16 : 12;

  @override
  Widget build(BuildContext context) {
    // Relógios juntos: um único retrato do adversário e seu nome, sem
    // repetir a foto numa faixa separada. Relógios compactos deixam o nome
    // legível mesmo em 360 dp; os demais chamadores mantêm a apresentação.
    if (players.length == 2 &&
        players.any((player) => player.portrait != null)) {
      final character = players.firstWhere((player) => player.portrait != null);
      return SizedBox(
        height: _height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _margin),
          child: Semantics(
            container: true,
            label: character.name,
            child: Row(
              children: [
                _withRing(character.portrait!, character),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ExcludeSemantics(
                    child: _nameAndDetail(
                      context,
                      character,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                for (final (index, player) in players.indexed) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
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
      height: _height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _margin),
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

  /// O nome e, na variante [detailed], a linha de detalhe embaixo, em
  /// `onSurfaceVariant`. As duas linhas cortam com reticências; com fonte
  /// grande, a escala para no que cabe na altura da fileira (o relógio e o
  /// tabuleiro não mudam de lugar).
  Widget _nameAndDetail(
    BuildContext context,
    PlayerEntry player, {
    required TextOverflow overflow,
  }) {
    final theme = Theme.of(context);
    final nameStyle = context.cardTitle;
    final name = Text(
      player.name,
      maxLines: 1,
      overflow: overflow,
      softWrap: false,
      style: nameStyle,
    );
    final detail = player.detail;
    if (!detailed || detail == null || detail.isEmpty) return name;
    final detailStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    double line(TextStyle? style) =>
        (style?.fontSize ?? 14) * (style?.height ?? 1.2);
    final maxScale = detailedHeight / (line(nameStyle) + line(detailStyle));
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          name,
          Text(
            detail,
            key: player.detailKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: detailStyle,
          ),
        ],
      ),
    );
  }

  /// O anel da vez no retrato (sem relógio): 2 px primário, por cima do
  /// retrato, sem mudar o tamanho dele.
  Widget _withRing(Widget portrait, PlayerEntry player) {
    if (player.time != null || !player.isTurn) return portrait;
    return Builder(
      builder: (context) => DecoratedBox(
        key: player.turnKey,
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppShape.small),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: ringWidth,
          ),
        ),
        child: portrait,
      ),
    );
  }

  /// Espessura do anel da vez.
  static const ringWidth = 2.0;

  Widget _entering(Widget clock) => enterClocks
      ? GameEntrance(part: GameEntrancePart.clock, child: clock)
      : clock;

  Widget _player(
    BuildContext context,
    PlayerEntry player, {
    required bool showName,
    bool mirrored = false,
  }) {
    final time = player.time;
    final children = [
      _withRing(
        player.portrait ?? PlayerPortrait(side: player.side, board: board),
        player,
      ),
      const SizedBox(width: AppSpacing.md),
      if (showName)
        Expanded(
          child: ExcludeSemantics(
            child: _nameAndDetail(
              context,
              player,
              overflow: detailed ? TextOverflow.ellipsis : TextOverflow.fade,
            ),
          ),
        ),
      if (showName && detailed && time != null)
        const SizedBox(width: AppSpacing.md),
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
        ),
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

/// O retrato do lado sem personagem: ícone de pessoa sobre primaryContainer,
/// como no CompJogador do canvas.
class PlayerPortrait extends StatelessWidget {
  const PlayerPortrait({required this.side, required this.board, super.key});

  final Side side;
  final BoardSettings board;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // CompJogador do canvas: quadrado primaryContainer com o icone de pessoa.
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppShape.small),
      ),
      child: ExcludeSemantics(
        child: Icon(
          Icons.person,
          size: _size * 0.64,
          color: colors.onPrimaryContainer,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = ClockFormat.format(time);
    // Parado vale mais que pouco tempo: o relógio que não corre não pede
    // pressa. Correndo, abaixo de `ClockEngine.lowTime` fica em alerta.
    final state = !running
        ? TimeDisplayState.paused
        : time < ClockEngine.lowTime
        ? TimeDisplayState.low
        : TimeDisplayState.active;
    final foreground = TimeDisplay.clockColors(
      theme.colorScheme,
      side,
      state,
    ).$2;
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
          state: state,
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
                fontWeight: AppWeight.strong,
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
