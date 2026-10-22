import 'package:flutter/material.dart';

/// O que todo chip de escolha e de filtro leva além do tema (CompChip: 32 de
/// altura, 8 entre linhas). O Flutter soma 2 ao mínimo de 32; a densidade
/// vertical -1 tira esses 2, e o `shrinkWrap` tira os 10 do alvo de toque.
abstract final class AppChip {
  static const density = VisualDensity(vertical: -1);
  static const tapTarget = MaterialTapTargetSize.shrinkWrap;
}

/// Os chips de dentro de [child] pintam o fundo de [color]. O chip não
/// escolhido é transparente no tema, mas o Flutter pinta o `canvasColor` (o
/// fundo da tela) por baixo; numa folha ou painel branco, ele saía cinza
/// (E1.08, QA r4).
class ChipSurface extends StatelessWidget {
  const ChipSurface({required this.color, required this.child, super.key});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(canvasColor: color),
    child: child,
  );
}
