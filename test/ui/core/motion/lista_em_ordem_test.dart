import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/lista_em_ordem.dart';

import 'entrada_helpers.dart';

/// H-ANI-17: listas e passos entram um de cada vez, de cima para baixo.
void main() {
  Widget tela(Widget filho, {bool reduzir = false, EntradasVistas? vistas}) =>
      MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 800),
          disableAnimations: reduzir,
        ),
        child: MaterialApp(
          home: EntradasVistasEscopo(
            vistas: vistas ?? EntradasVistas(),
            child: Scaffold(
              body: EntradaDaTela(id: 'PropV1TreinoAjuda', child: filho),
            ),
          ),
        ),
      );

  List<Widget> linhas(int n, {double altura = 40}) => [
    for (var i = 0; i < n; i++)
      SizedBox(height: altura, child: Text('Linha $i')),
  ];

  Finder linha(int i) => find.byKey(MotionKeys.itemDaLista(i));
  Finder passo(int i) => find.byKey(MotionKeys.passo(i));
  Finder conector(int i) => find.byKey(MotionKeys.conector(i));

  double escalaY(WidgetTester tester, Finder parte) {
    final t = find.descendant(of: parte, matching: find.byType(Transform));
    if (t.evaluate().isEmpty) return 1;
    return tester.widget<Transform>(t.first).transform.storage[5];
  }

  group('ListaEmOrdem', () {
    testWidgets('feitos: o item k começa só depois de k × 90 ms', (
      tester,
    ) async {
      await tester.pumpWidget(tela(ListaEmOrdem.feitos(itens: linhas(5))));
      final comeco = List<int?>.filled(5, null);
      for (var ms = 0; ms <= 900; ms += 5) {
        for (var k = 0; k < 5; k++) {
          if (comeco[k] == null && opacidade(tester, linha(k)) > 0) {
            comeco[k] = ms;
          }
        }
        await tester.pump(const Duration(milliseconds: 5));
      }
      for (var k = 0; k < 5; k++) {
        expect(comeco[k], greaterThanOrEqualTo(k * 90), reason: 'item $k');
      }
      expect(comeco.toSet(), hasLength(5), reason: 'dois no mesmo quadro');
      for (var k = 0; k < 5; k++) {
        expect(opacidade(tester, linha(k)), 1);
        expect(subida(tester, linha(k)), 0);
      }
    });

    testWidgets('lista longa: 30 ms entre linhas; sobe 10 px', (tester) async {
      await tester.pumpWidget(tela(ListaEmOrdem(itens: linhas(5))));
      expect(subida(tester, linha(0)), closeTo(10, .01));
      await tester.pump(const Duration(milliseconds: 29));
      expect(opacidade(tester, linha(1)), 0);
      await tester.pump(const Duration(milliseconds: 11));
      expect(opacidade(tester, linha(1)), greaterThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('30 itens numa tela que mostra 8: do 9º ao 30º não animam', (
      tester,
    ) async {
      await tester.pumpWidget(
        tela(
          SingleChildScrollView(
            child: ListaEmOrdem(itens: linhas(30, altura: 100)),
          ),
        ),
      );
      await tester.pump();
      expect(opacidade(tester, linha(0)), lessThan(1));
      for (var k = 8; k < 30; k++) {
        expect(opacidade(tester, linha(k)), 1, reason: 'item $k');
        expect(subida(tester, linha(k)), 0, reason: 'item $k');
      }
      await tester.pumpAndSettle();
    });

    testWidgets('filtrar depois da entrada: a lista nova aparece pronta', (
      tester,
    ) async {
      final vistas = EntradasVistas();
      await tester.pumpWidget(
        tela(ListaEmOrdem(itens: linhas(5)), vistas: vistas),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        tela(ListaEmOrdem(itens: linhas(3).reversed.toList()), vistas: vistas),
      );
      for (var k = 0; k < 3; k++) {
        expect(opacidade(tester, linha(k)), 1);
      }
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('voltar à tela: pronta no primeiro quadro', (tester) async {
      final vistas = EntradasVistas();
      await tester.pumpWidget(
        tela(ListaEmOrdem(itens: linhas(5)), vistas: vistas),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        tela(ListaEmOrdem(itens: linhas(5)), vistas: vistas),
      );
      for (var k = 0; k < 5; k++) {
        expect(opacidade(tester, linha(k)), 1);
      }
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('movimento reduzido: tudo pronto no primeiro quadro', (
      tester,
    ) async {
      await tester.pumpWidget(
        tela(ListaEmOrdem(itens: linhas(5)), reduzir: true),
      );
      for (var k = 0; k < 5; k++) {
        expect(opacidade(tester, linha(k)), 1);
        expect(subida(tester, linha(k)), 0);
      }
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('PassosComConector', () {
    testWidgets('passo, conector descendo, e só então o passo seguinte', (
      tester,
    ) async {
      await tester.pumpWidget(tela(PassosComConector(passos: linhas(3))));
      int? fimDoPasso0;
      int? conectorComeca;
      int? conectorChega;
      int? passo1Comeca;
      for (var ms = 0; ms <= 2000; ms += 5) {
        if (fimDoPasso0 == null && opacidade(tester, passo(0)) >= 1) {
          fimDoPasso0 = ms;
        }
        final y = escalaY(tester, conector(0));
        if (conectorComeca == null && y > 0) conectorComeca = ms;
        if (conectorChega == null && y >= 1) conectorChega = ms;
        if (passo1Comeca == null && opacidade(tester, passo(1)) > 0) {
          passo1Comeca = ms;
        }
        await tester.pump(const Duration(milliseconds: 5));
      }
      expect(conectorComeca, greaterThanOrEqualTo(fimDoPasso0!));
      expect(passo1Comeca, greaterThanOrEqualTo(conectorChega!));
      expect(escalaY(tester, conector(1)), 1);
      expect(opacidade(tester, passo(2)), 1);
    });

    testWidgets('5 passos cabem em 2 s', (tester) async {
      await tester.pumpWidget(tela(PassosComConector(passos: linhas(5))));
      await tester.pump(const Duration(milliseconds: 2000));
      for (var k = 0; k < 5; k++) {
        expect(opacidade(tester, passo(k)), 1);
      }
      for (var k = 0; k < 4; k++) {
        expect(escalaY(tester, conector(k)), 1);
      }
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('movimento reduzido: tudo no lugar, conector inteiro', (
      tester,
    ) async {
      await tester.pumpWidget(
        tela(PassosComConector(passos: linhas(3)), reduzir: true),
      );
      for (var k = 0; k < 3; k++) {
        expect(opacidade(tester, passo(k)), 1);
      }
      expect(escalaY(tester, conector(0)), 1);
      expect(escalaY(tester, conector(1)), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
