import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {bool still = false}) =>
      tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: still),
            child: Scaffold(body: child),
          ),
        ),
      );

  testWidgets('o esqueleto brilha enquanto carrega', (tester) async {
    await pump(tester, const SkeletonBlock());
    expect(find.byType(ShaderMask), findsOneWidget);
    // Animação contínua: há sempre um quadro pela frente.
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('com "remover animações", o esqueleto fica parado', (
    tester,
  ) async {
    await pump(tester, const SkeletonList(), still: true);
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
