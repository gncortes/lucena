import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/troca_com_fade.dart';

import 'entrada_helpers.dart';

/// H-ANI-03 (regra de 04/11): troca de exercício por fade cruzado. O tabuleiro
/// não se move e as peças não deslizam; a posição, a fala e o enunciado
/// trocam juntos quando a [TrocaComFade.chave] muda.
void main() {
  const tabuleiro = ValueKey('tabuleiro');

  Widget exercicio(String fala) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(key: tabuleiro, width: 300, height: 300),
      Text(fala),
    ],
  );

  Future<void> monta(
    WidgetTester tester,
    String id, {
    bool reduzir = false,
    String? fala,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduzir),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: TrocaComFade(chave: id, child: exercicio(fala ?? 'Fala $id')),
        ),
      ),
    ),
  );

  testWidgets('a primeira posição entra sem fade', (tester) async {
    await monta(tester, 'e1');
    expect(opacidadeAcima(tester, find.text('Fala e1')), 1);
  });

  testWidgets('trocar a chave cruza as duas em 300 ms, tabuleiro parado', (
    tester,
  ) async {
    await monta(tester, 'e1');
    final lugar = tester.getRect(find.byKey(tabuleiro));
    await monta(tester, 'e2');
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(tabuleiro), findsNWidgets(2));
    for (final e in find.byKey(tabuleiro).evaluate()) {
      expect(tester.getRect(find.byElementPredicate((x) => x == e)), lugar);
    }
    expect(
      opacidadeAcima(tester, find.text('Fala e1')),
      inExclusiveRange(0, 1),
    );
    expect(
      opacidadeAcima(tester, find.text('Fala e2')),
      inExclusiveRange(0, 1),
    );
    expect(find.byType(SlideTransition), findsNothing);

    await tester.pump(const Duration(milliseconds: 151));
    expect(find.text('Fala e1'), findsNothing);
    expect(opacidadeAcima(tester, find.text('Fala e2')), 1);
  });

  testWidgets('mesma chave com filho novo: troca no lugar, sem fade', (
    tester,
  ) async {
    await monta(tester, 'e1');
    await monta(tester, 'e1', fala: 'Fala nova');
    expect(find.text('Fala nova'), findsOneWidget);
    expect(opacidadeAcima(tester, find.text('Fala nova')), 1);
    expect(find.text('Fala e1'), findsNothing);
  });

  testWidgets('movimento reduzido: fade de 100 ms', (tester) async {
    await monta(tester, 'e1', reduzir: true);
    await monta(tester, 'e2', reduzir: true);
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      opacidadeAcima(tester, find.text('Fala e2')),
      inExclusiveRange(0, 1),
    );
    await tester.pump(const Duration(milliseconds: 51));
    expect(find.text('Fala e1'), findsNothing);
    expect(opacidadeAcima(tester, find.text('Fala e2')), 1);
  });
}
