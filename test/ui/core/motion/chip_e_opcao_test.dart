import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/chip_lucena.dart';
import 'package:lucena/ui/core/motion/opcao_selecionavel.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';

/// H-ANI-21 (chip selecionado) e H-ANI-30 (opção do tour).
void main() {
  Widget app(Widget filho, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: filho)),
    ),
  );

  group('ChipLucena', () {
    Widget chips() => _Escolha(
      construir: (atual, escolher) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final nome in ['A', 'B'])
            ChipLucena(
              key: ValueKey('chip$nome'),
              label: Text(nome),
              selecionado: atual == nome,
              aoEscolher: (_) => escolher(nome),
            ),
        ],
      ),
    );

    Color fundo(WidgetTester tester, String nome) {
      final ink = find.descendant(
        of: find.byKey(ValueKey('chip$nome')),
        matching: find.byType(Ink),
      );
      final decoracao = tester.widget<Ink>(ink.first).decoration!;
      return (decoracao as ShapeDecoration).color!;
    }

    Finder filtro(String nome) => find.descendant(
      of: find.byKey(ValueKey('chip$nome')),
      matching: find.byType(FilterChip),
    );

    testWidgets('B se enche e ganha o ✓ em 200 ms; A se esvazia', (
      tester,
    ) async {
      await tester.pumpWidget(app(chips()));
      final cheio = fundo(tester, 'A');
      final vazio = fundo(tester, 'B');
      expect(cheio, isNot(vazio));
      await tester.tap(find.text('B'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(fundo(tester, 'A'), isNot(anyOf(cheio, vazio)));
      expect(fundo(tester, 'B'), isNot(anyOf(cheio, vazio)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(fundo(tester, 'B'), cheio);
      expect(fundo(tester, 'A'), vazio);
      expect(tester.widget<FilterChip>(filtro('B')).selected, isTrue);
    });

    testWidgets('mostra o ✓', (tester) async {
      await tester.pumpWidget(app(chips()));
      expect(tester.widget<FilterChip>(filtro('A')).showCheckmark, isTrue);
    });

    testWidgets('movimento reduzido: o estado final no primeiro quadro', (
      tester,
    ) async {
      await tester.pumpWidget(app(chips(), reduzir: true));
      final cheio = fundo(tester, 'A');
      final vazio = fundo(tester, 'B');
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(fundo(tester, 'B'), cheio);
      expect(fundo(tester, 'A'), vazio);
    });
  });

  group('OpcaoSelecionavel', () {
    Widget opcoes() => _Escolha(
      inicial: '1',
      construir: (atual, escolher) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final n in ['1', '2'])
            OpcaoSelecionavel(
              key: ValueKey('opcao$n'),
              selecionada: atual == n,
              aoTocar: () => escolher(n),
              child: Text('Opção $n'),
            ),
        ],
      ),
    );

    BorderSide borda(WidgetTester tester, String n) {
      final material = find
          .descendant(
            of: find.byKey(ValueKey('opcao$n')),
            matching: find.byType(Material),
          )
          .first;
      final forma = tester.widget<Material>(material).shape!;
      return (forma as RoundedRectangleBorder).side;
    }

    testWidgets('a opção 2 marca em 200 ms e a 1 desmarca', (tester) async {
      await tester.pumpWidget(app(opcoes()));
      final marcada = borda(tester, '1');
      final desmarcada = borda(tester, '2');
      expect(marcada, isNot(desmarcada));
      await tester.tap(find.text('Opção 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(borda(tester, '2'), isNot(anyOf(marcada, desmarcada)));
      expect(borda(tester, '1'), isNot(anyOf(marcada, desmarcada)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(borda(tester, '2'), marcada);
      expect(borda(tester, '1'), desmarcada);
      final radios = tester.widgetList<Icon>(
        find.byKey(MotionKeys.radioDaOpcao),
      );
      expect(radios.map((i) => i.icon), [
        Icons.radio_button_unchecked,
        Icons.radio_button_checked,
      ]);
    });

    testWidgets('é um item de grupo exclusivo para o leitor de tela', (
      tester,
    ) async {
      await tester.pumpWidget(app(opcoes()));
      expect(
        tester.getSemantics(find.byKey(const ValueKey('opcao1'))),
        matchesSemantics(
          isSelected: true,
          hasSelectedState: true,
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          label: 'Opção 1',
        ),
      );
    });

    testWidgets('movimento reduzido: o estado final no primeiro quadro', (
      tester,
    ) async {
      await tester.pumpWidget(app(opcoes(), reduzir: true));
      final marcada = borda(tester, '1');
      await tester.tap(find.text('Opção 2'));
      await tester.pump();
      expect(borda(tester, '2'), marcada);
    });
  });
}

class _Escolha extends StatefulWidget {
  const _Escolha({required this.construir, this.inicial = 'A'});

  final String inicial;
  final Widget Function(String atual, ValueChanged<String> escolher) construir;

  @override
  State<_Escolha> createState() => _EscolhaState();
}

class _EscolhaState extends State<_Escolha> {
  late var _atual = widget.inicial;

  @override
  Widget build(BuildContext context) =>
      widget.construir(_atual, (v) => setState(() => _atual = v));
}
