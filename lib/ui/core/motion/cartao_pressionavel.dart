import 'package:flutter/widgets.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O cartão que afunda no toque (H-ANI-20): desce a 0,97 em 100 ms e volta
/// em 200 ms (`emphasized`) quando o dedo sai ou o gesto é cancelado. O
/// toque em si (e a ondulação) é do `InkWell` de dentro do [child].
///
/// Responde ao dedo na hora, sem esperar o atraso do toque do Flutter. Com
/// movimento reduzido, não escala: sobra a ondulação.
class CartaoPressionavel extends StatefulWidget {
  const CartaoPressionavel({required this.child, super.key});

  final Widget child;

  @override
  State<CartaoPressionavel> createState() => _CartaoPressionavelState();
}

class _CartaoPressionavelState extends State<CartaoPressionavel> {
  var _apertado = false;

  void _apertar(bool apertado) {
    if (_apertado != apertado) setState(() => _apertado = apertado);
  }

  @override
  Widget build(BuildContext context) {
    final reduzido = MovimentoReduzido.of(context);
    return Listener(
      onPointerDown: (_) => _apertar(true),
      onPointerUp: (_) => _apertar(false),
      onPointerCancel: (_) => _apertar(false),
      child: AnimatedScale(
        key: MotionKeys.cartaoPressionado,
        scale: _apertado && !reduzido ? LucenaMotion.escalaDoToque : 1,
        duration: reduzido
            ? Duration.zero
            : _apertado
            ? LucenaMotion.cartaoAfunda
            : LucenaMotion.cartaoVolta,
        curve: LucenaMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}
