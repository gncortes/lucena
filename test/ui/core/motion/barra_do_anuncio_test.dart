import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/motion/barra_do_anuncio.dart';

import 'entrada_helpers.dart';

/// H-ANI-31: a barra do anúncio, com "Conhecer o Pilares" que entra e afunda
/// e a contagem "Fechar em N" → "Fechar".
void main() {
  var fechou = 0;

  Widget app(int restantes, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Row(
          children: [
            ConhecerQueEntra(
              child: TextButton(
                onPressed: () {},
                child: const Text('Conhecer'),
              ),
            ),
            ContagemParaFechar(restantes: restantes, aoFechar: () => fechou++),
          ],
        ),
      ),
    ),
  );

  double xDoConhecer(WidgetTester tester) =>
      tester.getTopLeft(find.text('Conhecer')).dx;

  double escalaDoConhecer(WidgetTester tester) => tester
      .widget<AnimatedScale>(
        find.descendant(
          of: find.byKey(MotionKeys.conhecerDoAnuncio),
          matching: find.byKey(MotionKeys.cartaoPressionado),
        ),
      )
      .scale;

  setUp(() => fechou = 0);

  testWidgets('a contagem segue 3, 2, 1, Fechar e só fecha no fim', (
    tester,
  ) async {
    final vistos = <String>[];
    for (final n in [3, 2, 1, 0]) {
      await tester.pumpWidget(app(n));
      await tester.pumpAndSettle();
      vistos.add(n == 0 ? 'Fechar' : 'Fechar em $n');
      expect(find.text(vistos.last), findsOneWidget);
      if (n > 0) {
        await tester.tap(find.byKey(MotionKeys.contagemParaFechar));
        expect(fechou, 0);
      }
    }
    await tester.tap(find.byKey(MotionKeys.contagemParaFechar));
    expect(fechou, 1);
  });

  testWidgets('cada troca de número cruza em 200 ms', (tester) async {
    await tester.pumpWidget(app(3));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final novo = opacidadeAcima(tester, find.text('Fechar em 2'));
    expect(novo, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 110));
    expect(opacidadeAcima(tester, find.text('Fechar em 2')), 1);
    expect(find.text('Fechar em 3'), findsNothing);
  });

  testWidgets('"Fechar em 3" aparece com fade de 250 ms', (tester) async {
    await tester.pumpWidget(app(3));
    expect(opacidadeAcima(tester, find.text('Fechar em 3')), lessThan(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    expect(opacidadeAcima(tester, find.text('Fechar em 3')), 1);
  });

  testWidgets('Conhecer entra 12 px da direita e afunda a 0,94', (
    tester,
  ) async {
    await tester.pumpWidget(app(3));
    await tester.pumpAndSettle();
    final fim = xDoConhecer(tester);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(3));
    expect(xDoConhecer(tester), closeTo(fim + 12, .5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(xDoConhecer(tester), inExclusiveRange(fim, fim + 12));
    await tester.pump(const Duration(milliseconds: 170));
    expect(xDoConhecer(tester), fim);

    final gesto = await tester.startGesture(
      tester.getCenter(find.text('Conhecer')),
    );
    await tester.pump();
    expect(escalaDoConhecer(tester), .94);
    await gesto.up();
    await tester.pumpAndSettle();
    expect(escalaDoConhecer(tester), 1);
  });

  testWidgets('movimento reduzido: tudo no lugar no primeiro quadro', (
    tester,
  ) async {
    await tester.pumpWidget(app(3, reduzir: true));
    await tester.pumpAndSettle();
    final fim = xDoConhecer(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(3, reduzir: true));
    expect(xDoConhecer(tester), fim);
    expect(opacidadeAcima(tester, find.text('Fechar em 3')), 1);
    await tester.pumpWidget(app(2, reduzir: true));
    expect(opacidadeAcima(tester, find.text('Fechar em 2')), 1);
    expect(find.text('Fechar em 3'), findsNothing);
  });
}
