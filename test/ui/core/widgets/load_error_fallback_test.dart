import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error_fallback.dart';

void main() {
  testWidgets('erro de build tem texto genérico sem ações nem exceção', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      buildLoadErrorFallback(
        FlutterErrorDetails(exception: StateError('detalhe privado')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.textContaining('detalhe privado'), findsNothing);
  });

  testWidgets('fallback uses device language even before MaterialApp', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      buildLoadErrorFallback(
        FlutterErrorDetails(exception: StateError('private')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('An unexpected error occurred'), findsOneWidget);
    expect(find.byType(MaterialApp), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fallback does not nest an app or navigator inside the existing app',
    (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (_) => buildLoadErrorFallback(
              FlutterErrorDetails(exception: StateError('private')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Navigator), findsOneWidget);
      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
