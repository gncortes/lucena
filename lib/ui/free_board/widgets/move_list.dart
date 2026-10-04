import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/figurine.dart';

/// Lista de lances em notação figurina (♘f3): a letra da peça vira o desenho
/// dela, que vale em qualquer idioma. Uma linha por lance completo: número,
/// brancas, pretas.
class MoveList extends StatefulWidget {
  const MoveList({
    required this.moves,
    required this.firstMoveNumber,
    required this.firstSide,
    super.key,
  });

  /// Lances em notação algébrica (`e4`, `Nf3`, `O-O`).
  final List<String> moves;

  /// Número do primeiro lance (1 numa partida do início).
  final int firstMoveNumber;

  /// Quem fez o primeiro lance da lista.
  final Side firstSide;

  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
  static const _rowHeight = 40.0;

  final _scroll = ScrollController();

  // Com as pretas começando, o primeiro lance ocupa a coluna das pretas.
  int get _offset => widget.firstSide == Side.black ? 1 : 0;

  int get _rowCount => (widget.moves.length + _offset + 1) ~/ 2;

  @override
  void didUpdateWidget(MoveList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moves.length == oldWidget.moves.length) return;
    // Lance novo: a lista rola até ele.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.moves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.freeBoardNoMoves,
            key: FreeBoardKeys.noMoves,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // A notação de xadrez é sempre da esquerda para a direita.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        key: FreeBoardKeys.moveList,
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemExtent: _rowHeight,
        itemCount: _rowCount,
        itemBuilder: (context, row) => _row(theme, row),
      ),
    );
  }

  Widget _row(ThemeData theme, int row) {
    final number = '${widget.firstMoveNumber + row}';
    return Row(
      // Número e lances na mesma linha de base.
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            number,
            textAlign: TextAlign.center,
            strutStyle: moveStrut,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: _cell(row * 2 - _offset)),
        Expanded(child: _cell(row * 2 + 1 - _offset)),
      ],
    );
  }

  /// A célula do lance de índice [index]; vazia se ele ainda não foi jogado.
  Widget _cell(int index) {
    if (index >= widget.moves.length) return const SizedBox.shrink();
    // Só acontece na primeira linha, quando as pretas começam.
    if (index < 0) return const _MoveCell(san: '…', isLast: false);
    return _MoveCell(
      key: FreeBoardKeys.move(index),
      san: widget.moves[index],
      isLast: index == widget.moves.length - 1,
    );
  }
}

/// Altura de linha fixa: o figurino é maior que as letras, mas as linhas com
/// e sem figurino ficam com a mesma altura e a mesma linha de base.
const moveStrut = StrutStyle(fontSize: 16, height: 1.5, forceStrutHeight: true);

class _MoveCell extends StatelessWidget {
  const _MoveCell({required this.san, required this.isLast, super.key});

  final String san;
  final bool isLast;

  // O traço do desenho é fino: maior que as letras, ele pesa como elas.
  static const _figurineScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: isLast ? theme.colorScheme.onSecondaryContainer : null,
    );
    final figurineStyle = TextStyle(
      fontFamily: Figurine.fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: (style?.fontSize ?? 16) * _figurineScale,
    );
    return Semantics(
      // Cada lance é um item próprio para o leitor de tela, com a letra da peça.
      container: true,
      label: san,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isLast
              ? theme.colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        // O figurino é um caractere: tem a cor e a linha de base do texto.
        child: Text.rich(
          TextSpan(
            children: [
              for (final char in san.split(''))
                if (Figurine.ofLetter[char] case final figurine?)
                  TextSpan(text: figurine, style: figurineStyle)
                else
                  TextSpan(text: char),
            ],
          ),
          style: style,
          strutStyle: moveStrut,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}
