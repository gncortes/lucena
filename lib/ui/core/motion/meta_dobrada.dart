import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

/// Meta dobrada (H-ANI-29, `PropV1TreinoMetasDobrada`): os cartões entram em
/// ordem, 40 ms um do outro, e "META DOBRADA" chega por último, depois do
/// último cartão e da barra que enche (700 ms).
///
/// Só na primeira entrada da tela. Com movimento reduzido, tudo no lugar.
class MetaDobradaEmOrdem extends StatelessWidget {
  const MetaDobradaEmOrdem({
    required this.selo,
    required this.cartoes,
    required this.montar,
    this.animar,
    super.key,
  });

  /// O título "META DOBRADA".
  final Widget selo;

  final List<Widget> cartoes;

  /// Arruma o selo e os cartões já animados no layout da tela.
  final Widget Function(Widget selo, List<Widget> cartoes) montar;

  /// Nulo: só na primeira entrada da tela.
  final bool? animar;

  /// Quando o cartão [i] começa a entrar.
  static Duration inicio(int i) => LucenaMotion.intervaloDaMetaDobrada * i;

  /// Quando o selo começa, com [n] cartões: depois do último e da barra.
  static Duration inicioDoSelo(int n) {
    final fim = n == 0
        ? Duration.zero
        : inicio(n - 1) + LucenaMotion.cartaoDaMetaDobrada;
    return fim > LucenaMotion.barraEnche ? fim : LucenaMotion.barraEnche;
  }

  @override
  Widget build(BuildContext context) {
    final doSelo = inicioDoSelo(cartoes.length);
    return RelogioDeEntrada(
      total: doSelo + LucenaMotion.seloDaMetaDobrada,
      animar: animar,
      child: montar(
        EntradaNoTempo(
          key: MotionKeys.seloDaMetaDobrada,
          inicio: doSelo,
          duracao: LucenaMotion.seloDaMetaDobrada,
          subida: LucenaMotion.subidaDoSeloDobrado,
          child: selo,
        ),
        [
          for (var i = 0; i < cartoes.length; i++)
            EntradaNoTempo(
              key: MotionKeys.cartaoDaMetaDobrada(i),
              inicio: inicio(i),
              duracao: LucenaMotion.cartaoDaMetaDobrada,
              subida: LucenaMotion.subidaDoTexto,
              prontoForaDaTela: true,
              child: cartoes[i],
            ),
        ],
      ),
    );
  }
}
