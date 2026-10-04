import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/board_settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../settings/view_models/settings_cubit.dart';

/// Cores, peças e coordenadas do tabuleiro, com uma amostra que muda na hora.
class BoardAppearanceScreen extends StatelessWidget {
  const BoardAppearanceScreen({super.key});

  // Posição da amostra: depois de 1. e4 e5 2. Cf3 Cc6 3. Bc4.
  static const _previewFen =
      'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3';
  static const _previewLastMove = NormalMove(from: Square.f1, to: Square.c4);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return Scaffold(
      key: BoardSettingsKeys.appearanceScreen,
      appBar: AppBar(title: Text(l10n.settingsBoardAppearance)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // A amostra fica fixa no alto; as opções rolam embaixo dela.
            final previewSize = math.min(
              constraints.maxWidth - 48,
              constraints.maxHeight * 0.42,
            );
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _Preview(
                    size: previewSize,
                    fen: _previewFen,
                    lastMove: _previewLastMove,
                    board: board,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _SectionTitle(l10n.boardColors),
                      _Carousel(
                        children: [
                          for (final colors in BoardColors.values)
                            _Option(
                              key: BoardSettingsKeys.colorsOption(colors),
                              label: colors.label(l10n),
                              selected: board.colors == colors,
                              onTap: () => cubit.setBoard(
                                board.copyWith(colors: colors),
                              ),
                              child: _ColorsSwatch(colors: colors),
                            ),
                        ],
                      ),
                      _SectionTitle(l10n.boardPieces),
                      _Carousel(
                        children: [
                          for (final pieces in PieceStyle.values)
                            _Option(
                              key: BoardSettingsKeys.piecesOption(pieces),
                              label: pieces.label,
                              selected: board.pieces == pieces,
                              onTap: () => cubit.setBoard(
                                board.copyWith(pieces: pieces),
                              ),
                              child: _PiecesSample(
                                pieces: pieces,
                                colors: board.colors,
                              ),
                            ),
                        ],
                      ),
                      SwitchListTile(
                        key: BoardSettingsKeys.coordinatesSwitch,
                        secondary: const Icon(Icons.grid_on_outlined),
                        title: Text(l10n.boardCoordinates),
                        value: board.coordinates,
                        onChanged: (value) =>
                            cubit.setBoard(board.copyWith(coordinates: value)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: OutlinedButton.icon(
                          key: BoardSettingsKeys.resetButton,
                          icon: const Icon(Icons.restart_alt),
                          label: Text(l10n.boardRestoreDefault),
                          onPressed: cubit.resetBoardAppearance,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.size,
    required this.fen,
    required this.lastMove,
    required this.board,
  });

  final double size;
  final String fen;
  final Move lastMove;
  final BoardSettings board;

  @override
  Widget build(BuildContext context) {
    // O tabuleiro não espelha em idiomas da direita para a esquerda.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: StaticChessboard(
        key: BoardSettingsKeys.preview,
        size: size,
        orientation: Side.white,
        fen: fen,
        lastMove: lastMove,
        settings: StaticChessboardSettings.fromBoardSettings(
          board.chessground.copyWith(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Fileira de opções que rola para o lado.
class _Carousel extends StatelessWidget {
  const _Carousel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Uma opção da fileira: a amostra num quadrado e o nome embaixo. A escolhida
/// ganha a borda e a marca.
class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  static const _size = 64.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: _size + 12,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _size + 8,
                      height: _size + 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 3,
                          color: selected ? scheme.primary : Colors.transparent,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: SizedBox.square(dimension: _size, child: child),
                    ),
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : null,
                    color: selected ? scheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quatro casas com as cores do tabuleiro.
class _ColorsSwatch extends StatelessWidget {
  const _ColorsSwatch({required this.colors});

  final BoardColors colors;

  @override
  Widget build(BuildContext context) {
    final scheme = colors.scheme;
    Widget square(Color color) => Expanded(child: ColoredBox(color: color));
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [square(scheme.lightSquare), square(scheme.darkSquare)],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [square(scheme.darkSquare), square(scheme.lightSquare)],
          ),
        ),
      ],
    );
  }
}

/// O cavalo branco do conjunto, sobre uma casa escura do tabuleiro escolhido.
class _PiecesSample extends StatelessWidget {
  const _PiecesSample({required this.pieces, required this.colors});

  final PieceStyle pieces;
  final BoardColors colors;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.scheme.darkSquare,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image(image: pieces.assets[PieceKind.whiteKnight]!),
      ),
    );
  }
}
