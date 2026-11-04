import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/theme/app_spacing.dart';
import 'package:lucena/ui/core/widgets/empty_state.dart';

import '../../../../testing/test_app.dart';
import '../motion/entrada_helpers.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TestApp(child: Scaffold(body: child)));

  testWidgets('tonal: frase e a ação que enche a lista', (tester) async {
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
    expect(find.byType(FilledButton), findsOneWidget);
    await tester.tap(find.text('Jogar agora'));
    expect(tapped, isTrue);
  });

  testWidgets('desenho: círculo de 72 com ícone de 48', (tester) async {
    await pump(
      tester,
      const EmptyState(icon: Icons.history_rounded, message: 'Vazio'),
    );
    final icon = find.byIcon(Icons.history_rounded);
    expect(tester.getSize(icon).width, 48);
    final circle = find.ancestor(of: icon, matching: find.byType(Container));
    expect(tester.getSize(circle.first), const Size(72, 72));
  });

  testWidgets('primary: botão com ícone', (tester) async {
    await pump(
      tester,
      EmptyState(
        style: EmptyStateStyle.primary,
        icon: Icons.history_rounded,
        message: 'Vazio',
        actionLabel: 'Jogar',
        actionIcon: Icons.play_arrow_rounded,
        onAction: () {},
      ),
    );
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(tester.getSize(find.byKey(CoreKeys.emptyAction)).height, 48);
  });

  testWidgets('text: sem ícone nem ação', (tester) async {
    await pump(
      tester,
      EmptyState(
        style: EmptyStateStyle.text,
        message: 'Nada por aqui',
        actionLabel: 'x',
        onAction: () {},
      ),
    );
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('filters: ícone solto e botão de contorno', (tester) async {
    await pump(
      tester,
      EmptyState(
        style: EmptyStateStyle.filters,
        message: 'Nenhum resultado',
        actionLabel: 'Limpar filtros',
        onAction: () {},
      ),
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byIcon(Icons.filter_list_off), findsNWidgets(2));
  });

  testWidgets('erro sem "tentar de novo": só a frase', (tester) async {
    await pump(tester, const ErrorState(message: 'Não deu certo.'));
    expect(find.text('Não deu certo.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  // H-ANI-24: o vazio e o erro entram com calma, como o LoadErrorScreen.
  group('entrada', () {
    final icone = find.byKey(MotionKeys.iconeDoEstado);
    final texto = find.byKey(MotionKeys.textoDoEstado);
    final acao = find.byKey(MotionKeys.acaoDoEstado);

    testWidgets('ícone, depois a frase, depois a ação; tudo parado no fim', (
      tester,
    ) async {
      await pump(
        tester,
        ErrorState(
          message: 'Não deu certo.',
          retryLabel: 'Tentar de novo',
          onRetry: () {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacidade(tester, icone), greaterThan(0));
      expect(opacidade(tester, texto), 0);
      expect(opacidade(tester, acao), 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacidade(tester, texto), greaterThan(opacidade(tester, acao)));
      await tester.pumpAndSettle();
      for (final parte in [icone, texto, acao]) {
        expect(opacidade(tester, parte), 1);
      }
    });

    testWidgets('mantém os espaços: md até a frase, lg até a ação', (
      tester,
    ) async {
      await pump(
        tester,
        EmptyState(
          icon: Icons.history_rounded,
          message: 'Vazio',
          messageKey: const ValueKey('frase'),
          actionLabel: 'Jogar',
          onAction: () {},
        ),
      );
      await tester.pumpAndSettle();
      final circulo = tester.getRect(icone);
      final frase = tester.getRect(find.byKey(const ValueKey('frase')));
      final botao = tester.getRect(find.byKey(CoreKeys.emptyAction));
      expect(frase.top - circulo.bottom, AppSpacing.md);
      expect(botao.top - frase.bottom, AppSpacing.lg);
    });

    testWidgets('só a frase: entra sem ícone', (tester) async {
      await pump(
        tester,
        const EmptyState(style: EmptyStateStyle.text, message: 'Nada aqui'),
      );
      expect(icone, findsNothing);
      expect(texto, findsOneWidget);
      await tester.pumpAndSettle();
      expect(opacidade(tester, texto), 1);
    });
  });
}
