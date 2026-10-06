import 'package:flutter/material.dart';

/// As estrelas de um exercício: as ganhas cheias, as outras vazias. Sem
/// [earned], todas em contorno (ainda por resolver).
class StarsRow extends StatelessWidget {
  const StarsRow({required this.total, this.earned, this.size = 20, super.key});

  final int total;
  final int? earned;
  final double size;

  static const color = Color(0xfff2b705);

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
