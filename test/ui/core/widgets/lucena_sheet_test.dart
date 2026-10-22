import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/core/theme/app_sheet.dart';
import 'package:lucena/ui/core/widgets/lucena_sheet.dart';
import 'package:lucena/ui/core/widgets/sheet_close_button.dart';

import '../../../../testing/test_app.dart';

/// T73 (D7): um jeito só de abrir folha de baixo: raio 28, alça 32×4 e o ✕
/// redondo por fora, acima do canto final. D15: o chip informativo tem 28.
void main() {
  testWidgets('a folha tem raio 28, alça 32×4 e o ✕ por fora que fecha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? result = 'ainda aberta';
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showLucenaSheet<String>(
                  context,
                  builder: (_) => const SizedBox(height: 120),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final handle = tester.getSize(find.byKey(SheetKeys.handle));
    expect(handle, AppSheet.handleSize);
    final surface = tester.widget<Material>(find.byKey(SheetKeys.surface));
    expect(
      (surface.shape! as RoundedRectangleBorder).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(28)),
    );
    // O ✕ está acima da folha, fora dela, no canto final.
    final close = tester.getRect(find.byKey(SheetKeys.close));
    final sheet = tester.getRect(find.byKey(SheetKeys.surface));
    expect(close.bottom, lessThanOrEqualTo(sheet.top));
    expect(close.right, lessThanOrEqualTo(400 - SheetCloseButton.margin + 1));
    expect(close.width, greaterThanOrEqualTo(48));
    // O fundo escurecido vem do tema.
    final barrier = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(barrier.color, AppSheet.scrim);

    await tester.tap(find.byKey(SheetKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(SheetKeys.surface), findsNothing);
    expect(result, isNull);
  });
}
