import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/core/keys/pace_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/core/pace/pace_ui.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';

import '../../../../testing/goldens/golden_harness.dart';
import '../../../../testing/test_app.dart';

/// A folha "Escolha o ritmo" (canvas SugP2RitmoA): do mais calmo ao mais
/// rápido, "Recomendado" no Blitz, 5+3 marcado quando nada foi escolhido e a
/// escolha salva vencendo; a folha numa cor só.
void main() {
  PaceChoice? chosen;

  Future<void> open(
    WidgetTester tester, {
    TimeControl? current,
    Locale locale = const Locale('pt'),
    Size size = const Size(411, 914),
  }) async {
    await Goldens.loadFonts();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    chosen = null;
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open'),
                onPressed: () async =>
                    chosen = await showPaceSheet(context, current: current),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  // A opção marcada é a que tem o fundo `primaryContainer`.
  bool selected(WidgetTester tester, String code) {
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(PaceKeys.option(code)),
            matching: find.byType(Material),
          )
          .first,
    );
    return material.color ==
        Theme.of(tester.element(find.byKey(PaceKeys.sheet)))
            .colorScheme
            .primaryContainer;
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('a ordem vai do mais calmo ao mais rápido', (tester) async {
    await open(tester);
    expect(
      [for (final c in SpeedrunPaces.groupsCalmToFast.keys) c.name],
      ['rapid', 'blitz', 'bullet', 'ultraBullet'],
    );
    final ordem = [
      top(tester, 'Rápido'),
      top(tester, 'Blitz'),
      top(tester, 'Bullet'),
      top(tester, 'Ultra Bullet'),
    ];
    expect(ordem, [...ordem]..sort());
    // Dentro do grupo, também do mais calmo ao mais rápido.
    expect(
      tester.getTopLeft(find.byKey(PaceKeys.option('180+0'))).dx,
      lessThan(tester.getTopLeft(find.byKey(PaceKeys.option('180+2'))).dx),
    );
  });

  testWidgets('"Recomendado" fica só no Blitz, na linha da categoria', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(PaceKeys.recommended), findsOneWidget);
    expect(find.text('Recomendado'), findsOneWidget);
    final badge = tester.getRect(find.byKey(PaceKeys.recommended));
    final blitz = tester.getRect(find.text('Blitz'));
    expect(badge.center.dy, closeTo(blitz.center.dy, 2));
    expect(badge.left, greaterThan(blitz.right));
  });

  testWidgets('sem escolha anterior, o 5+3 vem marcado e confirma', (
    tester,
  ) async {
    await open(tester);
    expect(selected(tester, '300+3'), isTrue);
    expect(selected(tester, '180+2'), isFalse);
    await tester.tap(find.byKey(PaceKeys.confirm));
    await tester.pumpAndSettle();
    expect(chosen?.time, SpeedrunPaces.standard);
  });

  testWidgets('a escolha salva vence o 5+3', (tester) async {
    const saved = TimeControl(
      initial: Duration(minutes: 2),
      increment: Duration(seconds: 1),
    );
    await open(tester, current: saved);
    expect(selected(tester, '120+1'), isTrue);
    expect(selected(tester, '300+3'), isFalse);
  });

  testWidgets('a folha tem uma cor só: título e corpo na mesma superfície', (
    tester,
  ) async {
    await open(tester);
    final surface = tester.widget<Material>(find.byKey(SheetKeys.surface));
    expect(surface.color, AppColors.sheetSurface);

    // Pixels de fora dos textos: o do cabeçalho e o do corpo da folha.
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find
          .ancestor(
            of: find.byKey(SheetKeys.surface),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    final image = (await tester.runAsync(() => boundary.toImage()))!;
    final bytes = (await tester.runAsync(image.toByteData))!;
    int pixel(Offset global) {
      final local = boundary.globalToLocal(global);
      final offset = (local.dy.floor() * image.width + local.dx.floor()) * 4;
      return Color.fromARGB(
        bytes.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      ).toARGB32();
    }

    final header = tester.getRect(find.byKey(SheetKeys.header));
    final body = tester.getRect(find.byKey(PaceKeys.option('300+3')));
    // x = 4: dentro da folha e fora de qualquer texto ou botão.
    final inHeader = pixel(Offset(4, header.center.dy));
    final inBody = pixel(Offset(4, body.center.dy));
    expect(inHeader, AppColors.sheetSurface.toARGB32());
    expect(inBody, inHeader);
  });

  testWidgets('golden: folha do ritmo em 411×914', (tester) async {
    await open(tester);
    await expectLater(
      find.byType(Navigator).first,
      matchesGoldenFile('goldens/pace_sheet/ritmo_411x914.png'),
    );
  });

  testWidgets('em 360×640 não estoura e o Confirmar fica à vista', (
    tester,
  ) async {
    await open(tester, size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    final confirm = tester.getRect(find.byKey(PaceKeys.confirm));
    expect(confirm.bottom, lessThanOrEqualTo(640));
    expect(confirm.height, greaterThanOrEqualTo(48));
  });
}
