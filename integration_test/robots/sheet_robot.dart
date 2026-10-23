import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena_ui/lucena_ui.dart';
import 'package:patrol/patrol.dart';

/// A folha de baixo padrão (`showLucenaSheet`): o corpo e o ✕ por fora.
/// Algumas folhas trocam as keys pelas próprias (som, desistir na partida):
/// [surface] e [close] dizem quais; o padrão é o de `SheetKeys`.
class SheetRobot {
  const SheetRobot(
    this.$, {
    this.surface = SheetKeys.surface,
    this.close = SheetKeys.close,
  });

  final PatrolIntegrationTester $;
  final Key surface;
  final Key close;

  /// A folha está aberta: o corpo e o ✕ aparecem, um de cada.
  Future<void> expectOpen() async {
    await $(surface).waitUntilVisible();
    expect(find.byKey(surface), findsOneWidget);
    expect(find.byKey(close), findsOneWidget);
  }

  /// Toca no ✕: a folha fecha.
  Future<void> closeWithX() async {
    await $(close).tap();
    await $.pumpAndSettle();
    expect(find.byKey(surface), findsNothing);
    expect(find.byKey(close), findsNothing);
  }
}
