import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/services/firebase/auth_service.dart';
import 'package:lucena/data/services/firebase/cloud_store_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/avatar_photo.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/account_delete_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../testing/fakes/fake_avatar_repository.dart';
import '../../../../testing/fakes/fake_cloud_store_service.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';

class _FirebaseAuth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Credential extends Mock implements UserCredential {}

class _Google extends Mock implements GoogleSignIn {}

class _GoogleAccount extends Mock implements GoogleSignInAccount {}

class _Authentication extends Mock implements GoogleSignInAuthentication {}

class _UserInfo extends Mock implements UserInfo {}

class _Metadata extends Mock implements UserMetadata {}

class _Preferences extends Mock implements PreferencesService {
  bool fail = false;
  String? saved;
  int reads = 0;
  Completer<void>? gate;
  @override
  Future<String?> getString(String key) async {
    reads++;
    if (fail) throw StateError('preferences unavailable');
    return saved;
  }

  @override
  Future<void> remove(String key) async {
    await gate?.future;
    if (fail) throw StateError('preferences unavailable');
    saved = null;
  }
}

class _Avatars extends FakeAvatarRepository {
  Completer<void>? gate;
  final List<String> order;
  _Avatars(this.order);
  @override
  Future<void> delete(String uid) async {
    await super.delete(uid);
    order.add('photo');
    await gate?.future;
  }
}

class _Store extends FakeCloudStoreService {
  Completer<void>? gate;
  Completer<void>? pushReadGate;
  int pushReads = 0;
  final List<String> order;
  _Store(this.order);

  /// Falha a próxima remoção (uma vez).
  CloudStoreException? failDelete;

  /// Segura a gravação do perfil (`_touchProfile`) até completar.
  Completer<void>? mergeGate;

  @override
  Future<void> mergeUser(String uid, Map<String, Object?> data) async {
    await mergeGate?.future;
    await super.mergeUser(uid, data);
    order.add('merge');
  }

  @override
  Future<void> deleteUser(String uid) async {
    if (failDelete case final failure?) {
      failDelete = null;
      throw failure;
    }
    await super.deleteUser(uid);
    order.add('cloud');
    await gate?.future;
  }

  @override
  Future<String?> readPushToken(String uid) async {
    pushReads++;
    await pushReadGate?.future;
    return super.readPushToken(uid);
  }

  @override
  Future<void> deletePushToken(String uid) async {
    await super.deletePushToken(uid);
    order.add('releasePush:$uid');
  }
}

class _Profile extends FakeProfileRepository {
  _Profile() : super(const UserProfile(photo: AvatarPhoto.upload));
  bool fail = false;
  bool photoless = false;
  @override
  Future<UserProfile> load() async {
    if (fail) throw StateError('profile unavailable');
    final profile = await super.load();
    return photoless ? const UserProfile() : profile;
  }
}

void main() {
  setUpAll(
    () => registerFallbackValue(
      GoogleAuthProvider.credential(idToken: 'fallback'),
    ),
  );
  late _FirebaseAuth firebase;
  late _Google google;
  late _User a;
  late _User b;
  User? current;
  late _GoogleAccount selected;
  late FirebaseAuthService auth;
  late CloudAccountRepository accounts;
  late _Store store;
  late _Avatars avatars;
  late _Profile profile;
  late _Preferences preferences;
  late AccountDeleteCubit cubit;
  late List<String> authDeleted;
  late List<String> order;
  bool needsRecent = true;
  final clock = DateTime.utc(2026, 11, 2, 12);
  late Map<_User, _UserInfo> infos;
  late Map<_User, _Metadata> metadata;

  setUp(() {
    firebase = _FirebaseAuth();
    google = _Google();
    a = _User();
    b = _User();
    current = a;
    authDeleted = [];
    order = [];
    needsRecent = true;
    infos = {};
    metadata = {};
    for (final (user, uid) in [(a, 'A'), (b, 'B')]) {
      when(() => user.uid).thenReturn(uid);
      final info = infos[user] = _UserInfo();
      when(() => info.providerId).thenReturn('google.com');
      when(() => user.providerData).thenReturn([info]);
      final meta = metadata[user] = _Metadata();
      when(() => meta.lastSignInTime).thenReturn(clock);
      when(() => user.metadata).thenReturn(meta);
      when(() => user.delete()).thenAnswer((_) async {
        if (needsRecent) {
          throw FirebaseAuthException(code: 'requires-recent-login');
        }
        // Match the Android plugin: delete resolves native currentUser.
        authDeleted.add(current!.uid);
        current = null;
        order.add('auth');
      });
    }
    final resultA = _Credential();
    when(() => resultA.user).thenReturn(a);
    when(() => a.reauthenticateWithCredential(any())).thenAnswer((_) async {
      order.add('reauth');
      needsRecent = false;
      return resultA;
    });
    final resultB = _Credential();
    when(() => resultB.user).thenReturn(b);
    when(() => firebase.signInWithCredential(any())).thenAnswer((_) async {
      current = b;
      needsRecent = false;
      return resultB;
    });
    when(() => firebase.currentUser).thenAnswer((_) => current);
    when(() => firebase.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    when(() => firebase.signOut()).thenAnswer((_) async {
      order.add('signOut');
      current = null;
    });
    when(() => google.initialize()).thenAnswer((_) async {});
    when(() => google.signOut()).thenAnswer((_) async {});
    when(() => google.disconnect()).thenAnswer((_) async {});
    selected = _GoogleAccount();
    final authentication = _Authentication();
    when(() => authentication.idToken).thenReturn('selected-token');
    when(() => selected.authentication).thenReturn(authentication);
    when(() => google.authenticate()).thenAnswer((_) async => selected);
    auth = FirebaseAuthService(
      auth: firebase,
      google: google,
      now: FakeNow(clock),
    );
    store = _Store(order);
    avatars = _Avatars(order);
    profile = _Profile();
    preferences = _Preferences();
    accounts = CloudAccountRepository(
      auth,
      store,
      avatars: avatars,
      now: FakeNow(DateTime.utc(2026, 11, 2)),
      language: () async => 'pt',
      preferences: preferences,
    );
    cubit = AccountDeleteCubit(uid: 'A', accounts: accounts, profile: profile);
    addTearDown(cubit.close);
  });

  void noDeletion() {
    expect(avatars.deleted, isEmpty);
    expect(store.deleted, isEmpty);
    expect(authDeleted, isEmpty);
    expect(cubit.state.step, isNot(AccountDeleteStep.deleted));
    expect(cubit.state.busy, isFalse);
  }

  test(
    'Conta1 outra credencial Google não apaga nenhuma conta e sai',
    () async {
      when(() => a.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
      await cubit.confirm();
      noDeletion();
      expect(current, isNull);
      expect(cubit.state.step, AccountDeleteStep.differentAccount);
      verifyNever(() => firebase.signInWithCredential(any()));
      expect(store.users, isEmpty);
    },
  );

  test('Conta1 divergência libera push da sessão antes do logout', () async {
    preferences.saved = 'A|token-a';
    store.pushTokens.addAll({'A': 'token-a', 'B': 'token-b'});
    when(() => a.reauthenticateWithCredential(any()))
        .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
    await cubit.confirm();
    noDeletion();
    expect(preferences.saved, isNull);
    expect(store.pushTokens, {'B': 'token-b'});
    expect(order, ['releasePush:A', 'signOut']);
    expect(current, isNull);
  });

  test(
    'Conta1 divergência tenta Firebase mesmo se limpeza push falha',
    () async {
      preferences.saved = 'A|token-a';
      preferences.fail = true;
      store.pushTokens['A'] = 'token-a';
      when(() => a.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
      await cubit.confirm();
      noDeletion();
      expect(preferences.reads, 1);
      expect(current, isNull);
      verify(() => firebase.signOut()).called(1);
      verify(() => google.signOut()).called(1);
    },
  );

  test(
    'Conta1 divergência mantém login na fila durante limpeza push',
    () async {
      preferences.saved = 'A|token-a';
      store.pushTokens.addAll({'A': 'token-a', 'B': 'token-b'});
      final gate = store.pushReadGate = Completer<void>();
      when(() => a.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
      final deletion = cubit.confirm();
      await pumpEventQueue();
      expect(store.pushReads, 1);
      final login = auth.signInWithGoogle();
      await pumpEventQueue();
      expect(current, a);
      verifyNever(() => firebase.signOut());
      verifyNever(() => firebase.signInWithCredential(any()));
      gate.complete();
      await deletion;
      await login;
      noDeletion();
      expect(current, b);
      expect(order, ['releasePush:A', 'signOut']);
      expect(store.pushTokens, {'B': 'token-b'});
    },
  );

  test(
    'Conta1 divergência tenta logout se remoção remota do push falha',
    () async {
      preferences.saved = 'A|token-a';
      store.pushTokens['A'] = 'token-a';
      store.offline = true;
      when(() => a.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
      await cubit.confirm();
      noDeletion();
      expect(store.pushReads, 1);
      expect(preferences.saved, isNull);
      expect(store.pushTokens, {'A': 'token-a'});
      expect(current, isNull);
      verify(() => firebase.signOut()).called(1);
    },
  );

  test('Conta1 cancelar Google preserva foto, nuvem e Auth', () async {
    when(() => google.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );
    await cubit.confirm();
    noDeletion();
    expect(current, a);
  });

  test('Conta1 erro de reautenticação preserva foto, nuvem e Auth', () async {
    when(() => a.reauthenticateWithCredential(any()))
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await cubit.confirm();
    noDeletion();
  });

  test('Conta1 mesma conta reautentica antes de foto, nuvem e Auth', () async {
    await cubit.confirm();
    expect(order, ['reauth', 'photo', 'cloud', 'auth']);
    expect(authDeleted, ['A']);
    expect(cubit.state.step, AccountDeleteStep.deleted);
    verifyNever(() => firebase.signInWithCredential(any()));
    expect(store.users, isEmpty);
  });

  test('Conta1 erro Google preserva todos os dados', () async {
    when(() => google.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError),
    );
    await cubit.confirm();
    noDeletion();
  });

  test(
    'Conta1 resultado de reauth sem usuário nunca autoriza remoção',
    () async {
      final result = _Credential();
      when(() => result.user).thenReturn(null);
      when(() => a.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => result);
      await cubit.confirm();
      noDeletion();
      expect(current, isNull);
    },
  );

  for (final stage in ['google', 'reauth', 'photo', 'cloud', 'preferences']) {
    for (final signedOut in [false, true]) {
      test(
        'Conta1 troca externa em $stage logout=$signedOut não apaga B',
        () async {
          final gate = Completer<void>();
          switch (stage) {
            case 'google':
              when(() => google.authenticate()).thenAnswer((_) async {
                await gate.future;
                return selected;
              });
            case 'reauth':
              when(() => a.reauthenticateWithCredential(any()))
                  .thenAnswer((_) async {
                    await gate.future;
                    final result = _Credential();
                    when(() => result.user).thenReturn(a);
                    return result;
                  });
            case 'photo':
              avatars.gate = gate;
            case 'cloud':
              store.gate = gate;
            case 'preferences':
              preferences.gate = gate;
          }
          final deletion = cubit.confirm();
          await pumpEventQueue();
          current = signedOut ? null : b;
          gate.complete();
          await deletion;
          expect(avatars.deleted, isNot(contains('B')));
          expect(store.deleted, isNot(contains('B')));
          expect(authDeleted, isEmpty);
          expect(cubit.state.step, AccountDeleteStep.differentAccount);
          expect(cubit.state.busy, isFalse);
          if (stage == 'google' || stage == 'reauth') noDeletion();
        },
      );
    }
  }

  for (final action in ['google', 'email', 'create', 'logout']) {
    for (final stage in ['photo', 'native']) {
      test(
        'Conta1 serializa $action durante $stage até terminar Auth.delete',
        () async {
          final gate = Completer<void>();
          if (stage == 'photo') {
            avatars.gate = gate;
          } else {
            when(() => a.delete()).thenAnswer((_) async {
              await gate.future;
              authDeleted.add(current!.uid);
              current = null;
              order.add('auth');
            });
          }
          final resultB = _Credential();
          when(() => resultB.user).thenReturn(b);
          when(
            () => firebase.signInWithEmailAndPassword(
              email: 'b@example.com',
              password: 'password',
            ),
          ).thenAnswer((_) async {
            current = b;
            return resultB;
          });
          when(
            () => firebase.createUserWithEmailAndPassword(
              email: 'b@example.com',
              password: 'password',
            ),
          ).thenAnswer((_) async {
            current = b;
            return resultB;
          });
          when(() => b.sendEmailVerification()).thenAnswer((_) async {});
          final deletion = cubit.confirm();
          await pumpEventQueue();
          final Future<Object?> mutation = switch (action) {
            'google' => auth.signInWithGoogle(),
            'email' => auth.signInWithEmail('b@example.com', 'password'),
            'create' => auth.createWithEmail('b@example.com', 'password'),
            _ => auth.signOut(),
          };
          await pumpEventQueue();
          expect(current, a);
          verifyNever(() => firebase.signOut());
          verifyNever(() => firebase.signInWithCredential(any()));
          verifyNever(
            () => firebase.signInWithEmailAndPassword(
              email: 'b@example.com',
              password: 'password',
            ),
          );
          verifyNever(
            () => firebase.createUserWithEmailAndPassword(
              email: 'b@example.com',
              password: 'password',
            ),
          );
          gate.complete();
          await deletion;
          await mutation;
          expect(authDeleted, ['A']);
          expect(avatars.deleted, ['A']);
          expect(store.deleted, ['A']);
          expect(current, action == 'logout' ? isNull : same(b));
          expect(cubit.state.step, AccountDeleteStep.deleted);
        },
      );
    }
  }

  test(
    'Conta1 falha de logout na divergência não apaga nem prende busy',
    () async {
      when(() => a.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
      when(() => firebase.signOut())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      when(() => google.signOut()).thenThrow(StateError('Google unavailable'));
      await cubit.confirm();
      noDeletion();
      expect(cubit.state.step, AccountDeleteStep.differentAccount);
      verify(() => firebase.signOut()).called(1);
      verify(() => google.signOut()).called(1);
      // Uma falha na operação anterior não envenena a fila.
      expect((await auth.signInWithGoogle())?.uid, 'B');
    },
  );

  test(
    'Conta1 revogação Google falha após exclusão sem falso fracasso',
    () async {
      when(() => google.disconnect())
          .thenThrow(StateError('Google unavailable'));
      await cubit.confirm();
      expect(authDeleted, ['A']);
      expect(cubit.state.step, AccountDeleteStep.deleted);
    },
  );

  for (final signedOut in [false, true]) {
    test(
      'Conta1 mudança durante leitura do perfil: logout=$signedOut',
      () async {
        final gate = profile.loadGate = Completer<void>();
        final deletion = cubit.confirm();
        await pumpEventQueue();
        current = signedOut ? null : b;
        needsRecent = false;
        gate.complete();
        await deletion;
        noDeletion();
      },
    );
  }

  test('Conta1 falha do push não impede logout Firebase', () async {
    preferences.fail = true;
    try {
      await accounts.signOut();
    } on Object {
      /* Failure may be reported. */
    }
    expect(current, isNull);
    verify(() => firebase.signOut()).called(1);
  });

  test('Conta1 falha Google não impede logout Firebase', () async {
    // Initialize the provider without changing Firebase identity.
    when(() => google.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );
    await auth.signInWithGoogle();
    when(() => google.signOut()).thenThrow(StateError('Google unavailable'));
    try {
      await accounts.signOut();
    } on Object {
      /* Failure may be reported. */
    }
    expect(current, isNull);
    verify(() => firebase.signOut()).called(1);
  });

  group('H-CON-14 gaps', () {
    // Conta de e-mail: sem reautenticação Google; o Firebase pede login
    // recente (5 min) para apagar.
    void email(_User user, {required Duration since}) {
      when(() => infos[user]!.providerId).thenReturn('password');
      when(() => metadata[user]!.lastSignInTime)
          .thenReturn(clock.subtract(since));
      needsRecent = since >= const Duration(minutes: 5);
    }

    test('Gap2 e-mail sem login recente não apaga nada na nuvem', () async {
      email(a, since: const Duration(minutes: 30));
      await cubit.confirm();
      noDeletion();
      expect(order, isEmpty);
      expect(cubit.state.step, AccountDeleteStep.relogin);
      expect(current, a);
    });

    test('Gap2 e-mail com login recente apaga na ordem', () async {
      email(a, since: const Duration(minutes: 1));
      await cubit.confirm();
      expect(order, ['photo', 'cloud', 'auth']);
      expect(cubit.state.step, AccountDeleteStep.deleted);
    });

    test('Gap8 gravação do perfil do novo login não sobra na nuvem', () async {
      email(a, since: const Duration(minutes: 1));
      final result = _Credential();
      when(() => result.user).thenReturn(a);
      when(
        () => firebase.signInWithEmailAndPassword(
          email: 'a@example.com',
          password: 'password',
        ),
      ).thenAnswer((_) async => result);
      final gate = store.mergeGate = Completer<void>();
      await accounts.signInWithEmail('a@example.com', 'password');
      final deletion = cubit.confirm();
      await pumpEventQueue();
      gate.complete();
      await deletion;
      await pumpEventQueue();
      expect(order, ['merge', 'photo', 'cloud', 'auth']);
      expect(store.users, isEmpty);
      expect(cubit.state.step, AccountDeleteStep.deleted);
    });

    test(
      'Gap9 rede cai no meio: aviso não diz que nada saiu e repetir termina',
      () async {
        store.failDelete = const CloudStoreException(
          'unavailable',
          partial: true,
        );
        await cubit.confirm();
        expect(cubit.state.busy, isFalse);
        expect(cubit.state.notice, AccountDeleteNotice.failed);
        expect(authDeleted, isEmpty);

        needsRecent = true;
        await cubit.confirm();
        expect(authDeleted, ['A']);
        expect(cubit.state.step, AccountDeleteStep.deleted);
      },
    );

    test(
      'Gap9 foto já saiu e a nuvem falha: aviso não é de sem internet',
      () async {
        store.failDelete = const CloudStoreException('unavailable');
        await cubit.confirm();
        expect(avatars.deleted, ['A']);
        expect(cubit.state.notice, AccountDeleteNotice.failed);
      },
    );

    test('sem internet antes de apagar: "nada foi excluído"', () async {
      profile.photoless = true;
      store.failDelete = const CloudStoreException('unavailable');
      await cubit.confirm();
      expect(cubit.state.notice, AccountDeleteNotice.offline);
      expect(authDeleted, isEmpty);
    });

    test('Gap4 erro genérico libera os botões e avisa', () async {
      profile.fail = true;
      await cubit.confirm();
      noDeletion();
      expect(cubit.state.notice, AccountDeleteNotice.failed);
    });
  });
}
