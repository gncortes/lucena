import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/ambiente.dart';
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
    expect(
      await startFirebase(initialize: () async {}, appCheck: (_) async {}),
      isTrue,
    );
  });

  group('Emulator Suite do QA', () {
    test('desligado por padrão e nunca no prod', () {
      expect(FirebaseEmulador.ligado(define: false), isFalse);
      expect(
        FirebaseEmulador.ligado(define: true, ambiente: Ambiente.dev),
        isTrue,
      );
      expect(
        FirebaseEmulador.ligado(define: true, ambiente: Ambiente.prod),
        isFalse,
      );
      expect(FirebaseEmulador.host, '10.0.2.2');
      expect(
        [
          FirebaseEmulador.authPort,
          FirebaseEmulador.firestorePort,
          FirebaseEmulador.functionsPort,
        ],
        [9099, 8085, 5001],
      );
    });

    test('ligado, aponta para o emulador antes do App Check', () async {
      final order = <String>[];
      final firebase = await startFirebase(
        initialize: () async => order.add('init'),
        emulador: true,
        useEmulator: () async => order.add('emulador'),
        appCheck: (_) async => order.add('appCheck'),
      );
      expect(firebase, isTrue);
      expect(order, ['init', 'emulador', 'appCheck']);
    });

    test('desligado, não toca no emulador', () async {
      var used = false;
      await startFirebase(
        initialize: () async {},
        emulador: false,
        useEmulator: () async => used = true,
        appCheck: (_) async {},
      );
      expect(used, isFalse);
    });

    test(
      'emulador fora: o app sobe sem Firebase, nunca no projeto real',
      () async {
        final firebase = await startFirebase(
          initialize: () async {},
          emulador: true,
          useEmulator: () async => throw StateError('recusado'),
          appCheck: (_) async {},
        );
        expect(firebase, isFalse);
      },
    );
  });

  group('App Check (abuso)', () {
    test('o app da Play atesta pelo Play Integrity', () async {
      AndroidAppCheckProvider? used;
      await startFirebase(
        initialize: () async {},
        ambiente: Ambiente.prod,
        appCheck: (provider) async => used = provider,
      );
      expect(used, isA<AndroidPlayIntegrityProvider>());
    });

    test('o flavor dev usa o provedor de depuração, sem token no código', () {
      final provider = appCheckProvider(Ambiente.dev);
      expect(provider, isA<AndroidDebugProvider>());
      expect((provider as AndroidDebugProvider).debugToken, isNull);
    });

    test('App Check que falha não desliga o Firebase', () async {
      final firebase = await startFirebase(
        initialize: () async {},
        appCheck: (_) async => throw StateError('sem Play Services'),
      );
      expect(firebase, isTrue);
    });

    test('sem flavor (testes, F-Droid) conta como dev', () {
      expect(Ambiente.atual(flavor: null), Ambiente.dev);
      expect(Ambiente.atual(flavor: 'prod'), Ambiente.prod);
    });
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
