import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error_fallback.dart';

void main() {
  testWidgets('erro de build tem texto genérico sem ações nem exceção', (
    tester,
  ) async {
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
}
