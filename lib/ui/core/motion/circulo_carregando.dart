import 'package:flutter/material.dart';

import 'lucena_motion.dart';

/// O círculo de carregando do app (H-ANI-08, decisão 3 de 04/11): um arco que
/// dá uma volta a cada 800 ms, linear. É indicador de progresso, não enfeite:
/// gira mesmo com movimento reduzido.
class CirculoCarregando extends StatefulWidget {
  const CirculoCarregando({
    this.tamanho = 22,
    this.traco = 3,
    this.cor,
    super.key,
  });

  final double tamanho;
  final double traco;
  final Color? cor;

  @override
  State<CirculoCarregando> createState() => _CirculoCarregandoState();
}

class _CirculoCarregandoState extends State<CirculoCarregando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: LucenaMotion.giroCarregando,
  )..repeat();

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.tamanho,
    child: RotationTransition(
      turns: _giro,
      child: CircularProgressIndicator(
        // Arco fixo que gira: o ritmo é o do giro, não o do Material.
        value: .75,
        strokeWidth: widget.traco,
        color: widget.cor,
        strokeCap: StrokeCap.round,
      ),
    ),
  );
}
