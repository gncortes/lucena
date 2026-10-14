import 'package:flutter_test/flutter_test.dart';

/// A folha do Viktor abre sozinha com o texto novo e recolhe depois do tempo
/// de leitura (12 s no máximo): quem confere a folha recolhida espera isso.
Future<void> settleSheet(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 13));
  await tester.pumpAndSettle();
}
