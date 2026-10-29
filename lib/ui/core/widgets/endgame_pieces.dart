import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

/// As peças de um tipo de final, sem nome: as do jogador (em branco) e o rei,
/// o ×, as do adversário (em preto) e o rei. A peça repetida leva o número
/// estilizado antes dela, na casa de uma peça (`2♖`). Com [mineSlots], o lado
/// do jogador tem largura fixa e encosta à direita: o × e os reis ficam na
/// mesma coluna em todas as linhas. O nome vai para o leitor de tela por
/// quem usa (o canvas é `filtro_finais.py`).
class EndgamePieces extends StatelessWidget {
  const EndgamePieces({
    required this.mine,
    required this.theirs,
    required this.pieces,
    this.mineSlots,
    super.key,
  });

  /// O lado da cada peça e do número (30×30) e o espaço entre eles.
  static const slot = 30.0;
  static const gap = 2.0;

  /// A coluna do ×.
  static const crossWidth = 28.0;

  /// Peças sem o rei, na ordem dama, torre, bispo, cavalo, peão.
  final List<Role> mine;
  final List<Role> theirs;
  final PieceAssets pieces;

  /// Quantas casas o lado do jogador ocupa (ver [slots]).
  final int? mineSlots;

  /// Quantas casas um lado ocupa, com o rei (o número conta como uma casa).
  static int slots(List<Role> roles) =>
      _groups(roles).fold(1, (total, group) => total + (group.$2 > 1 ? 2 : 1));

  static List<(Role, int)> _groups(List<Role> roles) {
    final groups = <(Role, int)>[];
    for (final role in roles) {
      if (groups.isNotEmpty && groups.last.$1 == role) {
        groups.last = (role, groups.last.$2 + 1);
      } else {
        groups.add((role, 1));
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fixed = mineSlots;
    final mineRow = _side(mine, Side.white);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fixed == null)
          mineRow
        else
          SizedBox(
            width: fixed * (slot + gap) - gap,
            child: Align(alignment: Alignment.centerRight, child: mineRow),
          ),
        SizedBox(
          width: crossWidth,
          child: Text(
            '×',
            textAlign: TextAlign.center,
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
          ),
        ),
        _side(theirs, Side.black),
      ],
    );
  }

  Widget _side(List<Role> roles, Side side) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: gap,
    children: [
      for (final (role, count) in _groups(roles)) ...[
        if (count > 1) _Numeral(count: count, white: side == Side.white),
        _piece(Piece(color: side, role: role)),
      ],
      _piece(Piece(color: side, role: Role.king)),
    ],
  );

  Widget _piece(Piece piece) =>
      Image(image: pieces[piece.kind]!, width: slot, height: slot);
}

/// O número da peça repetida, no traço dela: branco com contorno ou preto
/// cheio. A fonte serifada do sistema, sem escala (a casa é fixa).
class _Numeral extends StatelessWidget {
  const _Numeral({required this.count, required this.white});

  final int count;
  final bool white;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = colors.onSurface;
    const style = TextStyle(
      fontFamily: 'serif',
      fontSize: 31,
      fontWeight: FontWeight.w900,
      height: 1,
    );
    Text text(TextStyle style) => Text(
      '$count',
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
      style: style,
    );
    return SizedBox.square(
      dimension: EndgamePieces.slot,
      child: Center(
        child: white
            ? Stack(
                alignment: Alignment.center,
                children: [
                  text(
                    style.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3.2
                        ..strokeJoin = StrokeJoin.round
                        ..color = ink,
                    ),
                  ),
                  text(style.copyWith(color: colors.surfaceContainerLowest)),
                ],
              )
            : text(style.copyWith(color: ink)),
      ),
    );
  }
}
