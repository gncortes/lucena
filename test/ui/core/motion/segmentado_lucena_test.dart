import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/segmentado_lucena.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';

/// H-ANI-30 no controle segmentado (CompSegmentado, D30): o segmento tocado
/// se enche de cor em 200 ms (`emphasized`) e o anterior se esvazia; com
/// movimento reduzido, troca na hora.
void main() {
  Widget app({String? inicial, bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(child: _Escolha(inicial: inicial)),
      ),
    ),
  );

  Color fundo(WidgetTester tester, String valor) =>
      tester.widget<Material>(find.byKey(MotionKeys.segmento(valor))).color!;

  testWidgets('B se enche e A se esvazia em 200 ms', (tester) async {
    await tester.pumpWidget(app(inicial: 'A'));
    final cheio = fundo(tester, 'A');
    final vazio = fundo(tester, 'B');
    expect(cheio, isNot(vazio));
    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(fundo(tester, 'A'), isNot(anyOf(cheio, vazio)));
    expect(fundo(tester, 'B'), isNot(anyOf(cheio, vazio)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(fundo(tester, 'A'), vazio);
    expect(fundo(tester, 'B'), cheio);
  });

  testWidgets('sem escolha: nenhum cheio; tocar marca', (tester) async {
    await tester.pumpWidget(app());
    final vazio = fundo(tester, 'A');
    expect(fundo(tester, 'B'), vazio);
    expect(fundo(tester, 'C'), vazio);
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(fundo(tester, 'C'), isNot(vazio));
    expect(
      tester.getSemantics(find.byKey(MotionKeys.segmento('C'))),
      matchesSemantics(
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        label: 'C',
      ),
    );
  });

  testWidgets('segmentos com a mesma largura e 40 de altura', (tester) async {
    await tester.pumpWidget(app(inicial: 'A'));
    final a = tester.getSize(find.byKey(MotionKeys.segmento('A')));
    final c = tester.getSize(find.byKey(MotionKeys.segmento('C')));
    expect(a.width, c.width);
    expect(a.height, 40 - 2, reason: 'a borda de 1 px fica por fora');
  });

  testWidgets('com movimento reduzido: troca na hora', (tester) async {
    await tester.pumpWidget(app(inicial: 'A', reduzir: true));
    final cheio = fundo(tester, 'A');
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(fundo(tester, 'B'), cheio);
  });
}

class _Escolha extends StatefulWidget {
  const _Escolha({this.inicial});
  final String? inicial;

  @override
  State<_Escolha> createState() => _EscolhaState();
}

class _EscolhaState extends State<_Escolha> {
  late String? _atual = widget.inicial;

  @override
  Widget build(BuildContext context) => SegmentadoLucena<String>(
    valores: const ['A', 'B', 'C'],
    selecionado: _atual,
    chave: MotionKeys.segmento,
    rotulo: Text.new,
    aoEscolher: (v) => setState(() => _atual = v),
  );
}
