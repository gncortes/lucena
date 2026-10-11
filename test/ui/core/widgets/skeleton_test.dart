import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/empty_state.dart';
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

  testWidgets('estado vazio: frase e a ação que enche a lista', (tester) async {
    var tapped = false;
    await pump(
      tester,
      EmptyState(
        icon: Icons.history_rounded,
        message: 'Ainda sem partidas.',
        actionLabel: 'Jogar agora',
        onAction: () => tapped = true,
      ),
    );
    expect(find.text('Ainda sem partidas.'), findsOneWidget);
    await tester.tap(find.text('Jogar agora'));
    expect(tapped, isTrue);
  });

  testWidgets('erro sem "tentar de novo": só a frase', (tester) async {
    await pump(tester, const ErrorState(message: 'Não deu certo.'));
    expect(find.text('Não deu certo.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
