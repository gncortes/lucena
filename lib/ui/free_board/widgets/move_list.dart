import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/widgets/figurine.dart';

/// Lista de lances em tabela, como no chess.com: uma linha por lance completo
/// (número, brancas, pretas), com as linhas alternadas e o último lance em
/// destaque. Na notação figurina (♘f3) a letra da peça vira o desenho dela,
/// que vale em qualquer idioma; na notação por letras, vira a letra do idioma
/// do app (Cf3).
class MoveList extends StatefulWidget {
  const MoveList({
    required this.moves,
    required this.firstMoveNumber,
    required this.firstSide,
    this.height = minHeight,
    this.pieceLetters,
    super.key,
  });

  static const _rowHeight = 36.0;

  /// A menor altura da lista (três linhas), para a tela reservar o espaço.
  static const minHeight = _rowHeight * 3;

  /// A altura da lista: os lances que não cabem rolam dentro dela.
  final double height;

  /// Lances em notação algébrica (`e4`, `Nf3`, `O-O`).
  final List<String> moves;

  /// Número do primeiro lance (1 numa partida do início).
  final int firstMoveNumber;

  /// Quem fez o primeiro lance da lista.
  final Side firstSide;

  /// A letra de cada peça no idioma do app, pela letra da notação algébrica
  /// (`N` → `C`). Nulo: os lances aparecem com o desenho da peça.
  final Map<String, String>? pieceLetters;

  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
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
    // Sem lances, a lista só guarda o lugar: nenhuma instrução na tela.
    if (widget.moves.isEmpty) {
      return SizedBox(key: FreeBoardKeys.noMoves, height: widget.height);
    }

    // A notação de xadrez é sempre da esquerda para a direita.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: widget.height,
        child: SingleChildScrollView(
          key: FreeBoardKeys.moveList,
          controller: _scroll,
          child: Column(
            children: [
              for (var row = 0; row < _rowCount; row++) _row(theme, row),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, int row) {
    return Container(
      height: MoveList._rowHeight,
      // Linhas alternadas, para o olho seguir o lance de um lado ao outro.
      color: row.isOdd
          ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${widget.firstMoveNumber + row}.',
              strutStyle: moveStrut,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: _cell(row * 2 - _offset)),
          Expanded(child: _cell(row * 2 + 1 - _offset)),
        ],
      ),
    );
  }

  /// A célula do lance de índice [index]; vazia se ele ainda não foi jogado.
  Widget _cell(int index) {
    if (index >= widget.moves.length) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      // Só acontece na primeira linha, quando as pretas começam.
      child: index < 0
          ? const _MoveCell(san: '…', isLast: false)
          : _MoveCell(
              key: FreeBoardKeys.move(index),
              san: widget.moves[index],
              isLast: index == widget.moves.length - 1,
              pieceLetters: widget.pieceLetters,
            ),
    );
  }
}

/// Altura de linha fixa: o figurino é maior que as letras, mas as linhas com
/// e sem figurino ficam com a mesma altura e a mesma linha de base.
const moveStrut = StrutStyle(fontSize: 16, height: 1.5, forceStrutHeight: true);

class _MoveCell extends StatelessWidget {
  const _MoveCell({
    required this.san,
    required this.isLast,
    this.pieceLetters,
    super.key,
  });

  final String san;
  final bool isLast;
  final Map<String, String>? pieceLetters;

  // O traço do desenho é fino: maior que as letras, ele pesa como elas.
  static const _figurineScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: isLast ? theme.colorScheme.onSecondaryContainer : null,
    );
    final figurineStyle = TextStyle(
      fontFamily: Figurine.fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: (style?.fontSize ?? 16) * _figurineScale,
    );
    final pieceLetters = this.pieceLetters;
    // O lance com as letras do idioma, para o leitor de tela e para a notação
    // por letras.
    final spoken = pieceLetters == null
        ? san
        : san.split('').map((char) => pieceLetters[char] ?? char).join();
    return Semantics(
      // Cada lance é um item próprio para o leitor de tela, com a letra da peça.
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              if (pieceLetters != null)
                TextSpan(text: spoken)
              else
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
