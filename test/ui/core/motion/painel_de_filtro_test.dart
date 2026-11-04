import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/opcoes_do_filtro.dart';
import 'package:lucena/ui/core/widgets/lucena_sheet.dart';

import 'entrada_helpers.dart';

/// H-ANI-23: o filtro da app bar abre numa folha com as opções entrando.
void main() {
  Widget app({bool reduzir = false, EntradasVistas? vistas}) => MediaQuery(
    data: MediaQueryData(
      size: const Size(412, 800),
      disableAnimations: reduzir,
    ),
    child: EntradasVistasEscopo(
      vistas: vistas ?? EntradasVistas(),
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => showLucenaSheet<void>(
                    context,
                    filtro: true,
                    builder: (context) => OpcoesDoFiltro(
                      id: 'treino',
                      itens: [
                        for (final n in ['A', 'B', 'C'])
                          SizedBox(height: 40, child: Text('Opção $n')),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  double chip(WidgetTester tester, int i) =>
      opacidadeAcima(tester, find.text('Opção ${'ABC'[i]}'));

  Future<void> abrir(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pump();
  }

  Future<void> fechar(WidgetTester tester) async {
    Navigator.of(tester.element(find.text('Opção A'))).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('a folha chega em 350 ms; o 1º chip começa em 120 ms', (
    tester,
  ) async {
    final vistas = EntradasVistas();
    await tester.pumpWidget(app(vistas: vistas));
    await abrir(tester);
    await tester.pump(const Duration(milliseconds: 110));
    expect(chip(tester, 0), 0);
    await tester.pump(const Duration(milliseconds: 40));
    expect(chip(tester, 0), greaterThan(0));
    expect(chip(tester, 1), 0, reason: 'o 2º espera mais 40 ms');
    await tester.pump(const Duration(milliseconds: 200));
    final aos350 = tester.getRect(find.byKey(MotionKeys.folha));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(MotionKeys.folha)), aos350);
    expect(chip(tester, 2), 1);

    await fechar(tester);
    await abrir(tester);
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 3; i++) {
      expect(chip(tester, i), 1, reason: 'na 2ª abertura já vêm prontos');
    }
    await tester.pumpAndSettle();
  });

  testWidgets('movimento reduzido: a folha no lugar no primeiro quadro', (
    tester,
  ) async {
    await tester.pumpWidget(app(reduzir: true));
    await abrir(tester);
    final primeiro = tester.getRect(find.byKey(MotionKeys.folha));
    for (var i = 0; i < 3; i++) {
      expect(chip(tester, i), 1);
    }
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(MotionKeys.folha)), primeiro);
  });
}
