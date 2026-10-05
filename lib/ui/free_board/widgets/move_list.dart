import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/widgets/figurine.dart';

/// Os lances numa faixa que rola para o lado, como no chess.com: o número e
/// os dois lances de cada jogada, com o lance que está no tabuleiro em
/// destaque. Tocar num lance mostra a posição daquele momento. Na notação
/// figurina (♘f3) a letra da peça vira o desenho dela, que vale em qualquer
/// idioma; na notação por letras, vira a letra do idioma do app (Cf3).
class MoveList extends StatefulWidget {
  const MoveList({
    required this.moves,
    required this.firstMoveNumber,
    required this.firstSide,
    this.selected,
    this.onSelected,
    this.pieceLetters,
    super.key,
  });

  /// A altura da faixa.
  static const height = 44.0;

  /// Lances em notação algébrica (`e4`, `Nf3`, `O-O`).
  final List<String> moves;

  /// Número do primeiro lance (1 numa partida do início).
  final int firstMoveNumber;

  /// Quem fez o primeiro lance da lista.
  final Side firstSide;

  /// O índice do lance que está no tabuleiro. Nulo: o último; -1: nenhum (a
  /// posição de início).
  final int? selected;

  /// Tocaram no lance de índice dado.
  final ValueChanged<int>? onSelected;

  /// A letra de cada peça no idioma do app, pela letra da notação algébrica
  /// (`N` → `C`). Nulo: os lances aparecem com o desenho da peça.
  final Map<String, String>? pieceLetters;

  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
  final _scroll = ScrollController();

  // Uma por lance, para trazer o lance em destaque para a vista.
  final _cells = <GlobalKey>[];

  // Com as pretas começando, o primeiro lance é o segundo da jogada.
  int get _offset => widget.firstSide == Side.black ? 1 : 0;

  int get _selected => widget.selected ?? widget.moves.length - 1;

  @override
  void didUpdateWidget(MoveList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.selected ?? oldWidget.moves.length - 1;
    if (widget.moves.length == oldWidget.moves.length && before == _selected) {
      return;
    }
    // Lance novo ou outro lance em destaque: a faixa rola até ele.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal() {
    if (!mounted || !_scroll.hasClients) return;
    final selected = _selected;
    if (selected < 0) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }
    final context = selected < _cells.length
        ? _cells[selected].currentContext
        : null;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sem lances, a faixa só guarda o lugar: nenhuma instrução na tela.
    if (widget.moves.isEmpty) {
      return const SizedBox(
        key: FreeBoardKeys.noMoves,
        height: MoveList.height,
      );
    }
    while (_cells.length < widget.moves.length) {
      _cells.add(GlobalKey());
    }
    final number = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurfaceVariant,
    );
    // A notação de xadrez é sempre da esquerda para a direita.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: MoveList.height,
        child: SingleChildScrollView(
          key: FreeBoardKeys.moveList,
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (final (index, san) in widget.moves.indexed) ...[
                // O número antes do lance das brancas (e do primeiro, quando
                // as pretas começam, com as reticências).
                if ((index + _offset).isEven || index == 0)
                  Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 4 : 12),
                    child: Text(
                      '${widget.firstMoveNumber + (index + _offset) ~/ 2}.'
                      '${(index + _offset).isOdd ? '..' : ''}',
                      strutStyle: moveStrut,
                      style: number,
                    ),
                  ),
                KeyedSubtree(
                  key: _cells[index],
                  child: _MoveCell(
                    key: FreeBoardKeys.move(index),
                    san: san,
                    selected: index == _selected,
                    pieceLetters: widget.pieceLetters,
                    onTap: widget.onSelected == null
                        ? null
                        : () => widget.onSelected!(index),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Altura de linha fixa: o figurino é maior que as letras, mas os lances com
/// e sem figurino ficam com a mesma altura e a mesma linha de base.
const moveStrut = StrutStyle(fontSize: 16, height: 1.5, forceStrutHeight: true);

class _MoveCell extends StatelessWidget {
  const _MoveCell({
    required this.san,
    required this.selected,
    this.pieceLetters,
    this.onTap,
    super.key,
  });

  final String san;
  final bool selected;
  final Map<String, String>? pieceLetters;
  final VoidCallback? onTap;

  // O traço do desenho é fino: maior que as letras, ele pesa como elas.
  static const _figurineScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: selected ? theme.colorScheme.onSecondaryContainer : null,
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
      button: onTap != null,
      selected: selected,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          // A área de toque passa da marca do lance.
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: selected
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
        ),
      ),
    );
  }
}
