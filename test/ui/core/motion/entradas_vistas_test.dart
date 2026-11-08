import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';

/// H-ANI-01, critério 2: "só na primeira entrada" é uma vez por tela na
/// sessão, num registro injetado (nunca global).
void main() {
  test('primeiraVez: true na primeira chamada, false na segunda', () {
    final vistas = EntradasVistas();
    expect(vistas.primeiraVez('PropV1TreinoCatalogo'), isTrue);
    expect(vistas.primeiraVez('PropV1TreinoCatalogo'), isFalse);
    expect(vistas.primeiraVez('PropV1TreinoProgresso'), isTrue);
  });

  test('um registro novo (nova sessão) volta a true', () {
    EntradasVistas().primeiraVez('PropV1TreinoCatalogo');
    expect(EntradasVistas().primeiraVez('PropV1TreinoCatalogo'), isTrue);
  });

  group('EntradaDaTela', () {
    Widget tela(EntradasVistas vistas, void Function(bool) ler) =>
        EntradasVistasEscopo(
          vistas: vistas,
          child: EntradaDaTela(
            id: 'PropV1TreinoCatalogo',
            child: Builder(
              builder: (context) {
                ler(EntradaDaTela.primeira(context));
                return const SizedBox();
              },
            ),
          ),
        );

    testWidgets('todos os widgets da mesma tela leem o mesmo valor', (
      tester,
    ) async {
      final vistas = EntradasVistas();
      final lidos = <bool>[];
      await tester.pumpWidget(
        EntradasVistasEscopo(
          vistas: vistas,
          child: EntradaDaTela(
            id: 'PropV1TreinoCatalogo',
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Builder(
                    builder: (context) {
                      lidos.add(EntradaDaTela.primeira(context));
                      return const SizedBox();
                    },
                  ),
              ],
            ),
          ),
        ),
      );
      expect(lidos, [true, true, true]);
    });

    testWidgets('reconstruir a tela não muda o valor da entrada', (
      tester,
    ) async {
      final vistas = EntradasVistas();
      final lidos = <bool>[];
      await tester.pumpWidget(tela(vistas, lidos.add));
      await tester.pumpWidget(tela(vistas, lidos.add));
      expect(lidos, everyElement(isTrue));
    });

    testWidgets('voltar à tela (novo widget) na mesma sessão: false', (
      tester,
    ) async {
      final vistas = EntradasVistas();
      final lidos = <bool>[];
      await tester.pumpWidget(tela(vistas, lidos.add));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(tela(vistas, lidos.add));
      expect(lidos, [true, false]);
    });

    testWidgets('sem tela em volta, conta como primeira entrada', (
      tester,
    ) async {
      late bool lido;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            lido = EntradaDaTela.primeira(context);
            return const SizedBox();
          },
        ),
      );
      expect(lido, isTrue);
    });

    testWidgets('sem registro em volta, toda entrada é a primeira', (
      tester,
    ) async {
      final lidos = <bool>[];
      Widget semRegistro() => EntradaDaTela(
        id: 'PropV1TreinoCatalogo',
        child: Builder(
          builder: (context) {
            lidos.add(EntradaDaTela.primeira(context));
            return const SizedBox();
          },
        ),
      );
      await tester.pumpWidget(semRegistro());
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(semRegistro());
      expect(lidos, [true, true]);
    });
  });
}
