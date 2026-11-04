import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/movimento_reduzido.dart';

/// H-ANI-01, critério 1: o app lê "remover animações" num lugar só.
void main() {
  Future<bool> ler(WidgetTester tester, {required bool reduzir}) async {
    late bool lido;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduzir),
        child: Builder(
          builder: (context) {
            lido = MovimentoReduzido.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return lido;
  }

  testWidgets('com "remover animações" ligado, devolve true', (tester) async {
    expect(await ler(tester, reduzir: true), isTrue);
  });

  testWidgets('sem a opção, devolve false', (tester) async {
    expect(await ler(tester, reduzir: false), isFalse);
  });

  group('animarEntrada', () {
    Future<bool> entrada(
      WidgetTester tester, {
      required bool reduzir,
      required EntradasVistas vistas,
    }) async {
      late bool lido;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduzir),
          child: EntradasVistasEscopo(
            vistas: vistas,
            child: EntradaDaTela(
              id: 'PropV1TreinoCatalogo',
              child: Builder(
                builder: (context) {
                  lido = MovimentoReduzido.animarEntrada(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      return lido;
    }

    testWidgets('primeira entrada e movimento ligado: anima', (tester) async {
      expect(
        await entrada(tester, reduzir: false, vistas: EntradasVistas()),
        isTrue,
      );
    });

    testWidgets('movimento reduzido: não anima', (tester) async {
      expect(
        await entrada(tester, reduzir: true, vistas: EntradasVistas()),
        isFalse,
      );
    });

    testWidgets('tela já vista: não anima', (tester) async {
      final vistas = EntradasVistas()..primeiraVez('PropV1TreinoCatalogo');
      expect(await entrada(tester, reduzir: false, vistas: vistas), isFalse);
    });
  });
}
