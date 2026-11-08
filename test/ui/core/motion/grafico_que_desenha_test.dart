import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/grafico_que_desenha.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';

/// H-ANI-19: a linha do rating se desenha.
void main() {
  final recebidos = <TempoDoGrafico>[];

  Widget tela(String periodo, {bool reduzir = false, EntradasVistas? vistas}) =>
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduzir),
        child: EntradasVistasEscopo(
          vistas: vistas ?? EntradasVistas(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: EntradaDaTela(
              id: 'grafico',
              child: GraficoQueDesenha(
                periodo: periodo,
                pintor: (tempo) {
                  recebidos.add(tempo);
                  return _Pintor(tempo);
                },
                tamanho: const Size(300, 160),
              ),
            ),
          ),
        ),
      );

  double linha() => recebidos.last.linha;

  testWidgets('a linha se desenha em 900 ms, na curva emphasized', (
    tester,
  ) async {
    recebidos.clear();
    await tester.pumpWidget(tela('mes'));
    expect(linha(), 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(recebidos.last.progresso, closeTo(.5, .01));
    expect(linha(), closeTo(LucenaMotion.emphasized.transform(.5), .02));
    await tester.pump(const Duration(milliseconds: 450));
    expect(recebidos.last.progresso, 1);
    expect(linha(), 1);
    expect(recebidos.last.area, 1);
    expect(recebidos.last.ponto(0), 1);
  });

  testWidgets('a área aparece no fim; os pontos saltam um depois do outro', (
    tester,
  ) async {
    recebidos.clear();
    await tester.pumpWidget(tela('mes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(recebidos.last.area, 0);
    expect(recebidos.last.ponto(0), greaterThan(recebidos.last.ponto(1)));
    expect(recebidos.last.ponto(1), greaterThan(recebidos.last.ponto(2)));
    await tester.pump(const Duration(milliseconds: 350));
    expect(recebidos.last.area, allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
  });

  testWidgets('trocar o período redesenha de 0 a 1 em 300 ms', (tester) async {
    recebidos.clear();
    final vistas = EntradasVistas();
    await tester.pumpWidget(tela('mes', vistas: vistas));
    await tester.pumpAndSettle();
    await tester.pumpWidget(tela('ano', vistas: vistas));
    expect(recebidos.last.progresso, 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(recebidos.last.progresso, allOf(greaterThan(0), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 150));
    expect(recebidos.last.progresso, 1);
  });

  testWidgets('tela já vista: o gráfico vem inteiro', (tester) async {
    recebidos.clear();
    final vistas = EntradasVistas();
    await tester.pumpWidget(tela('mes', vistas: vistas));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(tela('mes', vistas: vistas));
    expect(recebidos.last.progresso, 1);
  });

  testWidgets('movimento reduzido: inteiro no primeiro quadro', (tester) async {
    recebidos.clear();
    await tester.pumpWidget(tela('mes', reduzir: true));
    expect(recebidos.last.progresso, 1);
    expect(recebidos.last.linha, 1);
    await tester.pumpWidget(tela('ano', reduzir: true));
    expect(recebidos.last.progresso, 1);
  });
}

class _Pintor extends CustomPainter {
  _Pintor(this.tempo);

  final TempoDoGrafico tempo;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_Pintor old) => true;
}
