import 'package:flutter/material.dart';

/// As estrelas de um exercício: as ganhas cheias, as outras vazias. Sem
/// [earned], todas em contorno (ainda por resolver).
class StarsRow extends StatelessWidget {
  const StarsRow({required this.total, this.earned, this.size = 20, super.key});

  final int total;
  final int? earned;
  final double size;

  static const color = Color(0xfff2b705);
  static const gold = color;
  static const silver = Color(0xffa8b3bd);
  static const bronze = Color(0xffcd7f32);

  /// A cor de uma estrela pelo que ela vale: dourada (3), prata (2) ou
  /// bronze (1). Nula sem valor.
  static Color? colorFor(int points) => switch (points) {
    >= 3 => gold,
    2 => silver,
    1 => bronze,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final earned = this.earned;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < total; index++)
          Icon(
            earned != null && index < earned
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: earned != null && index < earned ? color : outline,
          ),
      ],
    );
  }
}

/// Uma estrela só, na cor do que o exercício vale agora ([points]): dourada,
/// prata ou bronze; vazia quando não vale mais nada.
class ValueStar extends StatelessWidget {
  const ValueStar({required this.points, this.size = 28, super.key});

  final int points;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = StarsRow.colorFor(points);
    return Icon(
      color == null ? Icons.star_outline_rounded : Icons.star_rounded,
      size: size,
      color: color ?? Theme.of(context).colorScheme.outline,
    );
  }
}
