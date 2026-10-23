import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/empty_state.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../../testing/test_app.dart';

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
}
