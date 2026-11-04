import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/firebase/firebase_bootstrap.dart';

void main() {
  test('Firebase que nunca responde não impede a abertura (Gap 5)', () async {
    final never = Completer<void>();
    final firebase = await startFirebase(
      initialize: () => never.future,
      timeout: const Duration(milliseconds: 20),
    );
    expect(firebase, isFalse);
  });

  test('Firebase que sobe a tempo fica ligado', () async {
    expect(await startFirebase(initialize: () async {}), isTrue);
  });

  test('Firebase que falha deixa o app subir sem ele', () async {
    final firebase = await startFirebase(
      initialize: () async => throw StateError('configuração ausente'),
    );
    expect(firebase, isFalse);
  });

  test('o limite padrão é curto para a abertura não esperar', () {
    expect(firebaseStartTimeout, lessThanOrEqualTo(const Duration(seconds: 5)));
  });
}
