import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/botao_carregando.dart';
import 'package:lucena/ui/core/motion/circulo_carregando.dart';
import 'package:lucena/ui/core/motion/entrada_de_estado.dart';
import 'package:lucena/ui/core/motion/entrada_de_resultado.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/numero_que_conta.dart';

import 'entrada_helpers.dart';

/// H-ANI-24 (estado vazio e de erro) e H-ANI-25 (resultado).
void main() {
  Widget tela(Widget filho, {bool reduzir = false, EntradasVistas? vistas}) =>
      MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 917),
          disableAnimations: reduzir,
        ),
        child: MaterialApp(
          home: EntradasVistasEscopo(
            vistas: vistas ?? EntradasVistas(),
            child: Scaffold(body: Center(child: filho)),
          ),
        ),
      );

  group('EntradaDeEstado', () {
    final icone = find.byKey(MotionKeys.iconeDoEstado);
    final texto = find.byKey(MotionKeys.textoDoEstado);
    Completer<void>? resposta;

    Widget estado() => EntradaDeEstado(
      icone: const Icon(Icons.error_outline, size: 48),
      texto: const Text('Ocorreu um erro inesperado'),
      acao: BotaoCarregando(
        label: 'Tentar novamente',
        onPressed: () => (resposta = Completer<void>()).future,
      ),
    );

    testWidgets('o ícone escala de 0,8 a 1 em 400 ms; o texto vem depois', (
      tester,
    ) async {
      await tester.pumpWidget(tela(estado()));
      expect(escala(tester, icone), closeTo(.8, .01));
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacidade(tester, texto), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(escala(tester, icone), allOf(greaterThan(.8), lessThan(1)));
      expect(opacidade(tester, texto), greaterThan(0));
      expect(subida(tester, texto), allOf(greaterThan(0), lessThan(8)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(escala(tester, icone), 1);
      expect(opacidade(tester, icone), 1);
      await tester.pumpAndSettle();
      expect(subida(tester, texto), 0);
    });

    testWidgets('"Tentar novamente" mostra o círculo até a resposta', (
      tester,
    ) async {
      await tester.pumpWidget(tela(estado()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(CirculoCarregando), findsOneWidget);
      resposta!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(CirculoCarregando), findsNothing);
    });

    testWidgets('movimento reduzido: tudo pronto no primeiro quadro', (
      tester,
    ) async {
      await tester.pumpWidget(tela(estado(), reduzir: true));
      expect(escala(tester, icone), 1);
      expect(opacidade(tester, icone), 1);
      expect(opacidade(tester, texto), 1);
      expect(subida(tester, texto), 0);
    });
  });

  group('EntradaDeResultado', () {
    const principal = ValueKey('principal');
    var toques = 0;

    Widget resultado({String id = 'teste-1'}) => EntradaDeResultado(
      id: id,
      estrela: const Icon(Icons.star),
      titulo: const Text('Muito bem'),
      subtitulo: const Text('Teste do capítulo'),
      placar: const NumeroQueConta(valor: 10, sufixo: ' de 12'),
      bolinhas: [
        for (var i = 0; i < 12; i++) const Icon(Icons.circle, size: 12),
      ],
      viktor: const Text('Viktor'),
      botoes: FilledButton(
        key: principal,
        onPressed: () => toques++,
        child: const Text('Continuar'),
      ),
    );

    Finder parte(String nome) => find.byKey(MotionKeys.parteDoResultado(nome));
    Finder bolinha(int i) => find.byKey(MotionKeys.bolinhaDoResultado(i));
    String placar(WidgetTester tester) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(MotionKeys.numeroQueConta),
            matching: find.byType(Text),
          ),
        )
        .data!;

    testWidgets('o placar termina de contar antes de os botões entrarem', (
      tester,
    ) async {
      await tester.pumpWidget(tela(resultado()));
      var ms = 0;
      while (opacidade(tester, parte('botoes')) == 0) {
        await tester.pump(const Duration(milliseconds: 10));
        ms += 10;
        expect(ms, lessThan(1300));
      }
      expect(placar(tester), '10 de 12');
      await tester.pumpAndSettle();
    });

    testWidgets('em 700 ms o botão principal está visível e aceita toque', (
      tester,
    ) async {
      toques = 0;
      await tester.pumpWidget(tela(resultado()));
      await tester.pump(const Duration(milliseconds: 700));
      expect(opacidade(tester, parte('botoes')), greaterThan(0));
      await tester.tap(find.byKey(principal));
      expect(toques, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('em 1300 ms tudo está parado', (tester) async {
      await tester.pumpWidget(tela(resultado()));
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      for (final nome in [
        'estrela',
        'titulo',
        'subtitulo',
        'placar',
        'viktor',
        'botoes',
      ]) {
        expect(opacidade(tester, parte(nome)), 1, reason: nome);
        expect(subida(tester, parte(nome)), 0, reason: nome);
      }
      for (var i = 0; i < 12; i++) {
        expect(opacidade(tester, bolinha(i)), 1, reason: 'bolinha $i');
      }
    });

    testWidgets('as 12 bolinhas entram da esquerda para a direita, uma a uma', (
      tester,
    ) async {
      await tester.pumpWidget(tela(resultado()));
      final comeco = List<int?>.filled(12, null);
      for (var ms = 0; ms <= 1300; ms += 5) {
        for (var i = 0; i < 12; i++) {
          if (comeco[i] == null && opacidade(tester, bolinha(i)) > 0) {
            comeco[i] = ms;
          }
        }
        await tester.pump(const Duration(milliseconds: 5));
      }
      for (var i = 1; i < 12; i++) {
        expect(comeco[i]!, greaterThan(comeco[i - 1]!), reason: 'bolinha $i');
      }
    });

    testWidgets('reabrir o mesmo resultado: "10 de 12" no primeiro quadro', (
      tester,
    ) async {
      final vistas = EntradasVistas();
      await tester.pumpWidget(tela(resultado(), vistas: vistas));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(tela(resultado(), vistas: vistas));
      expect(placar(tester), '10 de 12');
      expect(opacidade(tester, parte('botoes')), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('resultado novo na mesma sessão anima de novo', (tester) async {
      final vistas = EntradasVistas();
      await tester.pumpWidget(tela(resultado(), vistas: vistas));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(tela(resultado(id: 'teste-2'), vistas: vistas));
      expect(placar(tester), '0 de 12');
      expect(opacidade(tester, parte('botoes')), 0);
      await tester.pumpAndSettle();
    });

    testWidgets('movimento reduzido: tudo pronto, placar no valor final', (
      tester,
    ) async {
      await tester.pumpWidget(tela(resultado(), reduzir: true));
      expect(placar(tester), '10 de 12');
      expect(opacidade(tester, parte('botoes')), 1);
      expect(opacidade(tester, bolinha(11)), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
