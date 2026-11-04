import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import 'casa_no_tabuleiro.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O halo vermelho na casa do rei em xeque (H-ANI-10): pulsa duas vezes em
/// 700 ms e fica aceso. Com movimento reduzido, fica aceso sem pulsar.
///
/// Ocupa o tabuleiro inteiro (empilhe sobre ele, do mesmo tamanho) e não
/// recebe toques. Uma [casa] nova recomeça os pulsos.
class HaloDeXeque extends StatefulWidget {
  const HaloDeXeque({
    required this.casa,
    required this.orientacao,
    required this.tamanho,
    super.key,
  });

  /// A opacidade do halo aceso, entre os pulsos e depois deles.
  static const opacidadeAcesa = .7;

  final Square casa;
  final Side orientacao;

  /// Lado do tabuleiro.
  final double tamanho;

  /// A opacidade em [t] (0 a 1 dos 700 ms): dois picos, em 1/4 e 3/4.
  static double opacidade(double t) {
    final pulso = math.sin(2 * math.pi * t);
    return opacidadeAcesa + (1 - opacidadeAcesa) * pulso * pulso;
  }

  @override
  State<HaloDeXeque> createState() => _HaloDeXequeState();
}

class _HaloDeXequeState extends State<HaloDeXeque>
    with SingleTickerProviderStateMixin {
  late final _pulsos = AnimationController(
    vsync: this,
    duration: LucenaMotion.haloDoXeque,
  );

  /// A casa que já pulsou: outra dependência que muda não repete o pulso.
  Square? _pulsou;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulsar();
  }

  @override
  void didUpdateWidget(HaloDeXeque oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pulsar();
  }

  void _pulsar() {
    if (MovimentoReduzido.of(context)) {
      _pulsos.value = 1;
    } else if (_pulsou != widget.casa) {
      _pulsos.forward(from: 0);
    }
    _pulsou = widget.casa;
  }

  @override
  void dispose() {
    _pulsos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.error;
    final casa = retanguloDaCasa(
      widget.casa,
      widget.orientacao,
      widget.tamanho,
    );
    return IgnorePointer(
      child: SizedBox.square(
        dimension: widget.tamanho,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: casa,
              child: AnimatedBuilder(
                animation: _pulsos,
                builder: (context, child) => Opacity(
                  key: MotionKeys.haloDeXeque,
                  opacity: HaloDeXeque.opacidade(_pulsos.value),
                  child: child,
                ),
                child: CustomPaint(painter: _Halo(cor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Halo extends CustomPainter {
  const _Halo(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.drawRect(
      area,
      Paint()
        ..shader = RadialGradient(
          colors: [cor, cor.withValues(alpha: .55), cor.withValues(alpha: 0)],
          stops: const [0, .55, 1],
        ).createShader(area),
    );
  }

  @override
  bool shouldRepaint(_Halo oldDelegate) => oldDelegate.cor != cor;
}
