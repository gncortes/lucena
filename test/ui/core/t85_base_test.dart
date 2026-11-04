import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/core/widgets/busy_button.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';
import 'package:lucena/ui/core/widgets/lucena_card.dart';

/// T85-D0: a base comum das frentes. Superfícies sem branco (cartão #FAFBF9
/// com contorno 1px #E1E5DF; folha e diálogo #F5F7F4), botão com carregando e
/// esqueleto com a app bar no primeiro carregamento.
void main() {
  const card = Color(0xFFFAFBF9);
  const outline = Color(0xFFE1E5DF);
  const sheet = Color(0xFFF5F7F4);

  group('superfícies do tema claro', () {
    final theme = AppTheme.light;

    test('os tokens têm os valores do canvas', () {
      expect(AppColors.cardSurface, card);
      expect(AppColors.cardOutline, outline);
      expect(AppColors.sheetSurface, sheet);
    });

    test('cartão #FAFBF9 com contorno 1px #E1E5DF e raio 16', () {
      expect(theme.cardTheme.color, card);
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.side, const BorderSide(color: outline));
      expect(shape.borderRadius, const BorderRadius.all(Radius.circular(16)));
      expect(theme.colorScheme.surfaceContainerLow, card);
    });

    test('folha e diálogo com o fundo da tela', () {
      expect(theme.scaffoldBackgroundColor, sheet);
      expect(theme.bottomSheetTheme.backgroundColor, sheet);
      expect(theme.bottomSheetTheme.modalBackgroundColor, sheet);
      expect(theme.dialogTheme.backgroundColor, sheet);
    });
  });

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );

  group('LucenaCard', () {
    testWidgets('pinta #FAFBF9 com contorno e padding 16', (tester) async {
      await tester.pumpWidget(app(const LucenaCard(child: Text('x'))));
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(CoreKeys.card),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as ShapeDecoration;
      expect(decoration.color, card);
      final shape = decoration.shape as RoundedRectangleBorder;
      expect(shape.side, const BorderSide(color: outline));
      final padding = tester.widget<Padding>(
        find.ancestor(of: find.text('x'), matching: find.byType(Padding)).first,
      );
      expect(padding.padding, const EdgeInsets.all(16));
    });

    testWidgets('com onTap, o cartão inteiro abre', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(LucenaCard(onTap: () => taps++, child: const Text('x'))),
      );
      await tester.tap(find.byKey(CoreKeys.card));
      expect(taps, 1);
    });
  });

  group('BusyButton', () {
    testWidgets('mostra o carregando no próprio botão e não aceita outro '
        'toque', (tester) async {
      final done = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        app(
          BusyButton(
            label: 'Salvar',
            onPressed: () {
              calls++;
              return done.future;
            },
          ),
        ),
      );
      await tester.tap(find.byType(BusyButton));
      await tester.pump();
      expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
      // H-ANI-08: o rótulo sai em 120 ms.
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Salvar'), findsNothing);
      // O rótulo continua para o leitor de tela.
      expect(find.bySemanticsLabel('Salvar'), findsOneWidget);
      await tester.tap(find.byType(BusyButton));
      expect(calls, 1);
      done.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(CoreKeys.busySpinner), findsNothing);
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets('busy de fora também liga o carregando', (tester) async {
      await tester.pumpWidget(
        app(
          BusyButton(
            label: 'Salvar',
            busy: true,
            style: BusyButtonStyle.tonal,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('mantém a largura do rótulo enquanto carrega', (tester) async {
      final done = Completer<void>();
      await tester.pumpWidget(
        app(BusyButton(label: 'Continuar', onPressed: () => done.future)),
      );
      final before = tester.getSize(find.byType(BusyButton));
      await tester.tap(find.byType(BusyButton));
      await tester.pump();
      expect(tester.getSize(find.byType(BusyButton)), before);
      done.complete();
      await tester.pumpAndSettle();
    });
  });

  group('LoadSkeletonScreen', () {
    testWidgets('mantém a app bar com o título durante o primeiro '
        'carregamento', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const LoadSkeletonScreen(title: 'Sua semana'),
        ),
      );
      expect(find.widgetWithText(AppBar, 'Sua semana'), findsOneWidget);
      expect(find.byKey(CoreKeys.skeleton), findsOneWidget);
    });

    testWidgets('aceita blocos no desenho da tela', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const LoadSkeletonScreen(
            title: 'Guia',
            blocks: [SkeletonShape.card(88), SkeletonShape.line(120)],
          ),
        ),
      );
      expect(find.byKey(CoreKeys.skeleton), findsOneWidget);
      expect(find.byKey(CoreKeys.skeletonBlock), findsNWidgets(2));
    });
  });
}
