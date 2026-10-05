import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/board_settings.dart';
import '../l10n/l10n.dart';
import 'board_settings_ui.dart';

/// Tabuleiro de amostra, que muda junto com as escolhas de aparência.
class BoardPreview extends StatelessWidget {
  const BoardPreview({
    required this.size,
    required this.board,
    this.boardKey,
    super.key,
  });

  final double size;
  final BoardSettings board;

  /// Key do tabuleiro em si, para os testes lerem a aparência dele.
  final Key? boardKey;

  // Posição da amostra: depois de 1. e4 e5 2. Cf3 Cc6 3. Bc4.
  static const _fen =
      'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3';
  static const _lastMove = NormalMove(from: Square.f1, to: Square.c4);

  @override
  Widget build(BuildContext context) {
    // O tabuleiro não espelha em idiomas da direita para a esquerda.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: StaticChessboard(
        key: boardKey,
        size: size,
        orientation: Side.white,
        fen: _fen,
        lastMove: _lastMove,
        settings: StaticChessboardSettings.fromBoardSettings(
          board.chessground.copyWith(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}

/// Título de um grupo de opções de aparência.
class AppearanceSectionTitle extends StatelessWidget {
  const AppearanceSectionTitle(
    this.text, {
    this.value,
    this.valueKey,
    super.key,
  });

  final String text;

  /// O nome da opção escolhida, no fim da linha.
  final String? value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = this.value;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          if (value != null)
            Text(
              value,
              key: valueKey,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// As cores de tabuleiro numa fileira que rola para o lado.
class BoardColorsCarousel extends StatelessWidget {
  const BoardColorsCarousel({
    required this.selected,
    required this.onSelected,
    required this.keyOf,
    super.key,
  });

  final BoardColors selected;
  final ValueChanged<BoardColors> onSelected;
  final Key Function(BoardColors colors) keyOf;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Carousel(
      children: [
        for (final colors in BoardColors.values)
          _Option(
            key: keyOf(colors),
            label: colors.label(l10n),
            selected: selected == colors,
            onTap: () => onSelected(colors),
            child: _ColorsSwatch(colors: colors),
          ),
      ],
    );
  }
}

/// Os conjuntos de peças numa fileira que rola para o lado, cada um sobre uma
/// casa do tabuleiro [colors].
class PieceStyleCarousel extends StatelessWidget {
  const PieceStyleCarousel({
    required this.selected,
    required this.colors,
    required this.onSelected,
    required this.keyOf,
    super.key,
  });

  final PieceStyle selected;
  final BoardColors colors;
  final ValueChanged<PieceStyle> onSelected;
  final Key Function(PieceStyle pieces) keyOf;

  @override
  Widget build(BuildContext context) {
    return _Carousel(
      children: [
        for (final pieces in PieceStyle.values)
          _Option(
            key: keyOf(pieces),
            label: pieces.label,
            selected: selected == pieces,
            onTap: () => onSelected(pieces),
            child: _PiecesSample(pieces: pieces, colors: colors),
          ),
      ],
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
