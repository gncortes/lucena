import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/widgets/figurine.dart';

/// Lista de lances numa faixa horizontal logo abaixo do tabuleiro, como no
/// chess.com e no Lichess: o número do lance e os lances das brancas e das
/// pretas em seguida, rolando para o lado. Na notação figurina (♘f3) a letra
/// da peça vira o desenho dela, que vale em qualquer idioma; na notação por
/// letras, vira a letra do idioma do app (Cf3).
class MoveList extends StatefulWidget {
  const MoveList({
    required this.moves,
    required this.firstMoveNumber,
    required this.firstSide,
    this.pieceLetters,
    super.key,
  });

  /// Altura da faixa, para a tela reservar o espaço.
  static const height = 44.0;

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

  @override
  void didUpdateWidget(MoveList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moves.length == oldWidget.moves.length) return;
    // Lance novo: a faixa rola até ele.
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
    // Sem lances, a faixa só guarda o lugar: nenhuma instrução na tela.
    if (widget.moves.isEmpty) {
      return const SizedBox(
        key: FreeBoardKeys.noMoves,
        height: MoveList.height,
      );
    }

    final numberStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final items = <Widget>[];
    for (var index = -_offset; index < widget.moves.length; index++) {
      final ply = index + _offset;
      // O número antes do lance das brancas (ou do primeiro, das pretas).
      if (ply.isEven) {
        final number = widget.firstMoveNumber + ply ~/ 2;
        items.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: Text(
              index < 0 ? '$number…' : '$number.',
              strutStyle: moveStrut,
              style: numberStyle,
            ),
          ),
        );
      }
      if (index < 0) continue;
      items.add(
        _MoveCell(
          key: FreeBoardKeys.move(index),
          san: widget.moves[index],
          isLast: index == widget.moves.length - 1,
          pieceLetters: widget.pieceLetters,
        ),
      );
    }

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items,
          ),
        ),
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
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
