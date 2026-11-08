import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/retorno_do_lance.dart';
import 'package:lucena/ui/core/motion/selo_na_peca.dart';
import 'package:lucena/ui/core/motion/tabuleiro_hero.dart';
import 'package:lucena/ui/core/motion/troca_com_fade.dart';

/// H-ANI-11 e H-ANI-12: o mesmo sinal de acerto e de erro em todo exercício,
/// e o selo sempre inteiro: nas laterais e embaixo dentro do tabuleiro; na
/// fileira de cima sai por cima dele (há espaço acima).
void main() {
  const tamanho = 320.0;

  Widget tela(Widget filho, {bool reduzir = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduzir),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.square(dimension: tamanho, child: filho),
        ),
      ),
    ),
  );

  Widget retorno(TipoDeRetorno tipo, {VoidCallback? aoVoltar, Key? key}) =>
      RetornoDoLance(
        key: key,
        tipo: tipo,
        casa: Square.e4,
        orientacao: Side.white,
        tamanho: tamanho,
        vibrar: true,
        aoVoltar: aoVoltar,
        child: const ColoredBox(color: Colors.brown),
      );

  double escalaDoSelo(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.ancestor(
          of: find.byKey(MotionKeys.seloNaPeca),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  double dx(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(MotionKeys.tabuleiroDoRetorno))
      .transform
      .getTranslation()
      .x;

  /// Alguma cor por cima do tabuleiro (o filho é o marrom).
  Finder corNaCasa() => find.descendant(
    of: find.byKey(MotionKeys.tabuleiroDoRetorno),
    matching: find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color != Colors.brown,
    ),
  );

  List<String> hapticos(WidgetTester tester) {
    final chamadas = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          chamadas.add(call.arguments as String);
        }
        return null;
      },
    );
    return chamadas;
  }

  group('H-ANI-12 · selo na peça', () {
    for (final orientacao in Side.values) {
      testWidgets('inteiro em a8, h8, h1 e e4 '
          '(${orientacao.name} embaixo), sempre do mesmo tamanho', (
        tester,
      ) async {
        Size? tamanhoDoSelo;
        for (final casa in [Square.a8, Square.h8, Square.h1, Square.e4]) {
          await tester.pumpWidget(
            tela(
              SeloNaPeca(
                key: ValueKey(casa),
                casa: casa,
                orientacao: orientacao,
                tamanho: tamanho,
                cor: Colors.green,
                saltar: false,
                child: const Icon(Icons.check),
              ),
            ),
          );
          final selo = tester.getRect(find.byKey(MotionKeys.seloNaPeca));
          expect(selo.left, greaterThanOrEqualTo(0), reason: '$casa');
          expect(selo.right, lessThanOrEqualTo(tamanho + 1e-9));
          expect(selo.bottom, lessThanOrEqualTo(tamanho + 1e-9));
          // Por cima, só o pedaço que sai de toda casa (30% do selo).
          expect(selo.top, greaterThanOrEqualTo(-selo.height * 0.3 - 1e-9));
          tamanhoDoSelo ??= selo.size;
          expect(selo.width, closeTo(tamanhoDoSelo.width, 1e-9));
          expect(selo.height, closeTo(tamanhoDoSelo.height, 1e-9));
        }
      });
    }

    testWidgets('em e4: no canto de cima à direita, um pouco para fora', (
      tester,
    ) async {
      await tester.pumpWidget(
        tela(
          const SeloNaPeca(
            casa: Square.e4,
            orientacao: Side.white,
            tamanho: tamanho,
            cor: Colors.green,
            saltar: false,
            child: Icon(Icons.check),
          ),
        ),
      );
      final selo = tester.getRect(find.byKey(MotionKeys.seloNaPeca));
      const e4 = Rect.fromLTWH(160, 160, 40, 40);
      expect(selo.center.dx, greaterThan(e4.center.dx));
      expect(selo.center.dy, lessThan(e4.center.dy));
      expect(selo.right, greaterThan(e4.right));
      expect(selo.top, lessThan(e4.top));
    });
  });

  group('H-ANI-11 · retorno do lance', () {
    testWidgets('acerto: o selo salta acima de 1 e assenta em 1; a casa não '
        'muda de cor; '
        'vibração leve', (tester) async {
      final vibrou = hapticos(tester);
      await tester.pumpWidget(tela(retorno(TipoDeRetorno.acerto)));
      expect(vibrou, ['HapticFeedbackType.lightImpact']);
      await tester.pump(const Duration(milliseconds: 130));
      expect(escalaDoSelo(tester), greaterThan(1));
      await tester.pump(const Duration(milliseconds: 130));
      expect(escalaDoSelo(tester), 1);
      expect(corNaCasa(), findsNothing);
      await tester.pump(const Duration(milliseconds: 160));
      expect(corNaCasa(), findsNothing);
      expect(dx(tester), 0);
    });

    testWidgets('erro: o tabuleiro fica parado (sem tremida) e a casa não muda '
        'de cor; a peça volta; vibração média', (tester) async {
      final vibrou = hapticos(tester);
      var voltou = 0;
      await tester.pumpWidget(
        tela(retorno(TipoDeRetorno.erro, aoVoltar: () => voltou++)),
      );
      expect(vibrou, ['HapticFeedbackType.mediumImpact']);
      for (var ms = 0; ms < 340; ms += 20) {
        expect(dx(tester), 0);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pump(const Duration(milliseconds: 20));
      expect(dx(tester), 0);
      expect(corNaCasa(), findsNothing);
      expect(voltou, 0);
      await tester.pump(const Duration(milliseconds: 760));
      expect(voltou, 1);
    });

    testWidgets('o mesmo retorno nos cinco tipos de exercício: a mesma '
        'sequência de quadros', (tester) async {
      Future<List<(double, double)>> quadros(String tipo) async {
        await tester.pumpWidget(
          tela(retorno(TipoDeRetorno.erro, key: ValueKey(tipo))),
        );
        final lista = <(double, double)>[];
        for (var ms = 0; ms <= 1100; ms += 50) {
          lista.add((dx(tester), escalaDoSelo(tester)));
          await tester.pump(const Duration(milliseconds: 50));
        }
        return lista;
      }

      hapticos(tester);
      final licao = await quadros('licao');
      for (final tipo in ['armadilha', 'escola', 'partes', 'corrida']) {
        expect(await quadros(tipo), licao, reason: tipo);
      }
    });

    testWidgets('movimento reduzido: parado e selo em 1 no primeiro quadro', (
      tester,
    ) async {
      hapticos(tester);
      await tester.pumpWidget(tela(retorno(TipoDeRetorno.erro), reduzir: true));
      expect(escalaDoSelo(tester), 1);
      expect(corNaCasa(), findsNothing);
      for (var ms = 0; ms < 400; ms += 20) {
        expect(dx(tester), 0);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();
    });
  });

  testWidgets('o selo da fileira de cima não é recortado pelo fade nem pelo '
      'hero do tabuleiro (Gabriel, 04/11)', (tester) async {
    await tester.pumpWidget(
      tela(
        TabuleiroHero(
          id: 'x',
          child: TrocaComFade(
            chave: 1,
            child: RetornoDoLance(
              tipo: TipoDeRetorno.acerto,
              casa: Square.h8,
              orientacao: Side.white,
              tamanho: tamanho,
              vibrar: false,
              child: const ColoredBox(color: Colors.brown),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selo = find.byKey(MotionKeys.seloNaPeca);
    expect(tester.getRect(selo).top, lessThan(0));
    for (final tipo in [ClipRect, ClipRRect]) {
      expect(
        find.ancestor(of: selo, matching: find.byType(tipo)),
        findsNothing,
        reason: '$tipo',
      );
    }
    for (final pilha in tester.widgetList<Stack>(
      find.ancestor(of: selo, matching: find.byType(Stack)),
    )) {
      expect(pilha.clipBehavior, Clip.none);
    }
  });
}
