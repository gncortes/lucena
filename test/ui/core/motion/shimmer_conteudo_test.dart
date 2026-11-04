import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/shimmer_conteudo.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';

/// H-ANI-07: o esqueleto brilha em laço de 1100 ms e se dissolve no conteúdo,
/// que sobe 8 px.
void main() {
  Widget tela(bool carregando, {bool reduzir = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduzir),
      child: Scaffold(
        body: ShimmerConteudo(
          carregando: carregando,
          esqueleto: const SkeletonBlock(height: 40),
          child: const Text('Conteúdo'),
        ),
      ),
    ),
  );

  double fase(WidgetTester tester) =>
      tester.widget<BrilhoEsqueleto>(find.byType(BrilhoEsqueleto)).fase;

  double dy(WidgetTester tester) => tester
      .widget<Transform>(
        find
            .ancestor(
              of: find.text('Conteúdo'),
              matching: find.byType(Transform),
            )
            .first,
      )
      .transform
      .getTranslation()
      .y;

  testWidgets('carregando: o brilho anda', (tester) async {
    await tester.pumpWidget(tela(true));
    final antes = fase(tester);
    await tester.pump(const Duration(milliseconds: 550));
    expect(fase(tester), isNot(antes));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
  });

  testWidgets('o brilho dá uma volta em 1100 ms', (tester) async {
    await tester.pumpWidget(tela(true));
    final antes = fase(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(fase(tester), closeTo(antes, 1e-9));
  });

  testWidgets('carregou: esqueleto e conteúdo coexistem no meio; no fim, só '
      'o conteúdo, sem deslocamento', (tester) async {
    await tester.pumpWidget(tela(true));
    await tester.pumpWidget(tela(false));
    await tester.pump(const Duration(milliseconds: 125));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
    expect(find.text('Conteúdo'), findsOneWidget);
    expect(dy(tester), greaterThan(0));
    await tester.pump(const Duration(milliseconds: 175));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
    expect(find.text('Conteúdo'), findsOneWidget);
    expect(dy(tester), 0);
  });

  testWidgets('carga rápida (já pronto no primeiro quadro): sem esqueleto', (
    tester,
  ) async {
    await tester.pumpWidget(tela(false));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
    expect(find.text('Conteúdo'), findsOneWidget);
    expect(dy(tester), 0);
  });

  testWidgets('movimento reduzido: brilho parado e conteúdo sem subir', (
    tester,
  ) async {
    await tester.pumpWidget(tela(true, reduzir: true));
    expect(find.byType(BrilhoEsqueleto), findsNothing);
    await tester.pumpWidget(tela(false, reduzir: true));
    await tester.pump(const Duration(milliseconds: 50));
    expect(dy(tester), 0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
  });
}
