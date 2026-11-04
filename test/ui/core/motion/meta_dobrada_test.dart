import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';
import 'package:lucena/ui/core/motion/meta_dobrada.dart';

import 'entrada_helpers.dart';

/// H-ANI-29: na meta dobrada, os cartões ganham o ✓ em ordem, um por quadro,
/// e "META DOBRADA" chega por último, depois do último cartão e da barra.
void main() {
  Widget tela({bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(
      size: const Size(412, 800),
      disableAnimations: reduzir,
    ),
    child: MaterialApp(
      home: EntradasVistasEscopo(
        vistas: EntradasVistas(),
        child: Scaffold(
          body: EntradaDaTela(
            id: 'PropV1TreinoMetasDobrada',
            child: MetaDobradaEmOrdem(
              selo: const Text('META DOBRADA'),
              cartoes: [
                for (var i = 0; i < 5; i++)
                  SizedBox(height: 60, child: Text('Meta $i')),
              ],
              montar: (selo, cartoes) =>
                  Column(children: [selo, ...cartoes]),
            ),
          ),
        ),
      ),
    ),
  );

  Finder cartao(int i) => find.byKey(MotionKeys.cartaoDaMetaDobrada(i));
  final selo = find.byKey(MotionKeys.seloDaMetaDobrada);

  testWidgets('os cartões entram em ordem, um por quadro; o selo por último', (
    tester,
  ) async {
    await tester.pumpWidget(tela());
    final comecou = <int, int>{};
    var seloCheio = -1;
    for (var quadro = 0; quadro < 120; quadro++) {
      for (var i = 0; i < 5; i++) {
        if (!comecou.containsKey(i) && opacidade(tester, cartao(i)) > 0) {
          comecou[i] = quadro;
        }
      }
      if (seloCheio < 0 && opacidade(tester, selo) >= 1) seloCheio = quadro;
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(comecou.keys, [0, 1, 2, 3, 4]);
    for (var i = 1; i < 5; i++) {
      expect(comecou[i]! > comecou[i - 1]!, isTrue, reason: 'cartão $i');
    }
    // Depois do último cartão (inteiro) e da barra (700 ms).
    final fimDosCartoes =
        MetaDobradaEmOrdem.inicio(4) + LucenaMotion.cartaoDaMetaDobrada;
    expect(MetaDobradaEmOrdem.inicioDoSelo(5) >= fimDosCartoes, isTrue);
    expect(
      MetaDobradaEmOrdem.inicioDoSelo(5) >= LucenaMotion.barraEnche,
      isTrue,
    );
    expect(seloCheio > comecou[4]!, isTrue);
    expect(subida(tester, selo), 0);
  });

  testWidgets('movimento reduzido: tudo pronto no primeiro quadro', (
    tester,
  ) async {
    await tester.pumpWidget(tela(reduzir: true));
    for (var i = 0; i < 5; i++) {
      expect(opacidade(tester, cartao(i)), 1);
    }
    expect(opacidade(tester, selo), 1);
  });
}
