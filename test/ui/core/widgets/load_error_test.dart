import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/theme/canvas_symbols.dart';
import 'package:lucena/ui/core/widgets/actions_footer.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('o ícone e o texto entram como estado de erro (H-ANI-24)', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: LoadErrorScreen(kind: LoadErrorKind.generic, onAction: () {}),
      ),
    );
    expect(find.byKey(MotionKeys.iconeDoEstado), findsOneWidget);
    expect(find.byKey(MotionKeys.textoDoEstado), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('retry assíncrono carrega no botão e mantém a tela', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: LoadErrorScreen(
          kind: LoadErrorKind.generic,
          onAction: () => pending.future,
        ),
      ),
    );
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pump();
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(LoadErrorKeys.action)).onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
  final cases = <LoadErrorKind, (String, String?, IconData)>{
    LoadErrorKind.generic: (
      'Ocorreu um erro inesperado',
      null,
      CanvasSymbols.error,
    ),
    LoadErrorKind.offline: (
      'Sem internet',
      'Você precisa de conexão com a internet para acessar este recurso.',
      CanvasSymbols.wifiOff,
    ),
    LoadErrorKind.noSpace: (
      'Falta espaço no celular',
      null,
      CanvasSymbols.storage,
    ),
    LoadErrorKind.unavailable: (
      'Conteúdo indisponível',
      null,
      CanvasSymbols.error,
    ),
    LoadErrorKind.notFound: (
      'Conteúdo não encontrado',
      'O link pode estar errado ou o conteúdo foi removido.',
      CanvasSymbols.searchOff,
    ),
    LoadErrorKind.engine: (
      'Ocorreu um erro inesperado',
      null,
      CanvasSymbols.error,
    ),
    LoadErrorKind.launch: ('O Lucena não abriu', null, CanvasSymbols.error),
    LoadErrorKind.launchAgain: (
      'O Lucena continua sem abrir',
      'Feche o app e abra novamente. Se continuar, veja o espaço livre no celular.',
      CanvasSymbols.error,
    ),
  };

  Future<void> pump(WidgetTester tester, LoadErrorScreen screen) =>
      tester.pumpWidget(TestApp(locale: const Locale('pt'), child: screen));

  for (final entry in cases.entries) {
    testWidgets('${entry.key.name}: texto, ícone, rodapé e callbacks', (
      tester,
    ) async {
      var actions = 0;
      var backs = 0;
      var spaces = 0;
      await pump(
        tester,
        LoadErrorScreen(
          kind: entry.key,
          onAction: () => actions++,
          onBack: () => backs++,
          onFreeSpace: () => spaces++,
        ),
      );
      final (title, message, icon) = entry.value;
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      if (message != null) expect(find.text(message), findsOneWidget);
      expect(
        find.byType(Text),
        findsNWidgets(
          1 +
              (message == null ? 0 : 1) +
              (entry.key == LoadErrorKind.notFound
                  ? 1
                  : entry.key == LoadErrorKind.noSpace
                  ? 3
                  : 2),
        ),
      );
      expect(find.byType(AppBar), findsNothing);
      expect(
        tester.widget<ActionsFooter>(find.byType(ActionsFooter)).stacked,
        isTrue,
      );
      final glyph = tester.widget<Icon>(find.byIcon(icon));
      expect(glyph.size, 64);
      expect(glyph.fill, 0);
      expect(
        glyph.color,
        Theme.of(tester.element(find.byIcon(icon))).colorScheme.primary,
      );
      expect(
        find.text(
          entry.key == LoadErrorKind.notFound
              ? 'Ir para o início'
              : 'Tentar novamente',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(LoadErrorKeys.action));
      expect(actions, 1);
      if (entry.key == LoadErrorKind.notFound) {
        expect(find.byKey(LoadErrorKeys.back), findsNothing);
        expect(find.text('Tentar novamente'), findsNothing);
      } else {
        await tester.tap(find.byKey(LoadErrorKeys.back));
        expect(backs, 1);
      }
      if (entry.key == LoadErrorKind.noSpace) {
        expect(find.byKey(LoadErrorKeys.freeSpace), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Liberar espaço'),
            matching: find.byType(FilledButton),
          ),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: find.byKey(LoadErrorKeys.action),
            matching: find.byType(OutlinedButton),
          ),
          findsNothing,
        );
        expect(
          tester.widget(find.byKey(LoadErrorKeys.action)),
          isA<OutlinedButton>(),
        );
        await tester.tap(find.byKey(LoadErrorKeys.freeSpace));
        expect(spaces, 1);
        expect(
          tester.getTopLeft(find.byKey(LoadErrorKeys.freeSpace)).dy,
          lessThan(tester.getTopLeft(find.byKey(LoadErrorKeys.action)).dy),
        );
      } else {
        expect(find.byKey(LoadErrorKeys.freeSpace), findsNothing);
        expect(
          tester.widget(find.byKey(LoadErrorKeys.action)),
          isA<FilledButton>(),
        );
      }
    });
  }

  testWidgets('sem callbacks opcionais: só tentar de novo preenchido', (
    tester,
  ) async {
    for (final kind in LoadErrorKind.values) {
      await pump(tester, LoadErrorScreen(kind: kind, onAction: () {}));
      expect(find.byKey(LoadErrorKeys.back), findsNothing);
      expect(find.byKey(LoadErrorKeys.freeSpace), findsNothing);
      expect(
        tester.widget(find.byKey(LoadErrorKeys.action)),
        isA<FilledButton>(),
      );
    }
  });

  testWidgets('conteúdo centralizado acima do rodapé em 412×917', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(
      tester,
      LoadErrorScreen(kind: LoadErrorKind.generic, onAction: () {}),
    );
    final top = tester.getTopLeft(find.byIcon(CanvasSymbols.error)).dy;
    final bottom = tester
        .getBottomLeft(find.text('Ocorreu um erro inesperado'))
        .dy;
    final footer = tester.getTopLeft(find.byType(ActionsFooter)).dy;
    expect((top - (footer - bottom)).abs() / footer, lessThanOrEqualTo(.05));
    expect(tester.takeException(), isNull);
  });
}
