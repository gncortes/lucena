import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/data/services/firebase/auth_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/avatar_photo.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/profile_account_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../testing/fakes/fake_avatar_repository.dart';
import '../../../../testing/fakes/fake_cloud_store_service.dart';
import '../../../../testing/fakes/fake_lichess_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_sync_repository.dart';

class _FirebaseAuth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Credential extends Mock implements UserCredential {}

class _Google extends Mock implements GoogleSignIn {}

class _GoogleAccount extends Mock implements GoogleSignInAccount {}

class _Authentication extends Mock implements GoogleSignInAuthentication {}

class _UserInfo extends Mock implements UserInfo {}

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
  @override
  Future<void> deleteUser(String uid) async {
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
  Completer<void>? gate;
  @override
  Future<UserProfile> load() async {
    await gate?.future;
    return super.load();
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
  late ProfileAccountCubit cubit;
  late List<String> authDeleted;
  late List<String> order;
  bool needsRecent = true;

  setUp(() {
    firebase = _FirebaseAuth();
    google = _Google();
    a = _User();
    b = _User();
    current = a;
    authDeleted = [];
    order = [];
    needsRecent = true;
    for (final (user, uid) in [(a, 'A'), (b, 'B')]) {
      when(() => user.uid).thenReturn(uid);
      final info = _UserInfo();
      when(() => info.providerId).thenReturn('google.com');
      when(() => user.providerData).thenReturn([info]);
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
    auth = FirebaseAuthService(auth: firebase, google: google);
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
    final scheduler = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(scheduler.dispose);
    cubit = ProfileAccountCubit(
      accounts: accounts,
      sync: scheduler,
      lichess: FakeLichessRepository(),
      profile: profile,
    );
    addTearDown(cubit.close);
  });

  void noDeletion() {
    expect(avatars.deleted, isEmpty);
    expect(store.deleted, isEmpty);
    expect(authDeleted, isEmpty);
    expect(cubit.state.notice, isNot(ProfileNotice.deleted));
    expect(cubit.state.busy, isFalse);
  }

  test(
    'Conta1 outra credencial Google não apaga nenhuma conta e sai',
    () async {
      when(() => a.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
      await cubit.deleteAccount();
      noDeletion();
      expect(current, isNull);
      expect(cubit.state.notice, ProfileNotice.deleteDifferentAccount);
      verifyNever(() => firebase.signInWithCredential(any()));
      expect(store.users, isEmpty);
    },
  );

  test('Conta1 divergência libera push da sessão antes do logout', () async {
    preferences.saved = 'A|token-a';
    store.pushTokens.addAll({'A': 'token-a', 'B': 'token-b'});
    when(() => a.reauthenticateWithCredential(any()))
        .thenThrow(FirebaseAuthException(code: 'user-mismatch'));
    await cubit.deleteAccount();
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
      await cubit.deleteAccount();
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
      final deletion = cubit.deleteAccount();
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
      await cubit.deleteAccount();
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
    await cubit.deleteAccount();
    noDeletion();
    expect(current, a);
  });

  test('Conta1 erro de reautenticação preserva foto, nuvem e Auth', () async {
    when(() => a.reauthenticateWithCredential(any()))
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await cubit.deleteAccount();
    noDeletion();
  });

  test('Conta1 mesma conta reautentica antes de foto, nuvem e Auth', () async {
    await cubit.deleteAccount();
    expect(order, ['reauth', 'photo', 'cloud', 'auth']);
    expect(authDeleted, ['A']);
    expect(cubit.state.notice, ProfileNotice.deleted);
    verifyNever(() => firebase.signInWithCredential(any()));
    expect(store.users, isEmpty);
  });

  test('Conta1 erro Google preserva todos os dados', () async {
    when(() => google.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError),
    );
    await cubit.deleteAccount();
    noDeletion();
  });

  test(
    'Conta1 resultado de reauth sem usuário nunca autoriza remoção',
    () async {
      final result = _Credential();
      when(() => result.user).thenReturn(null);
      when(() => a.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => result);
      await cubit.deleteAccount();
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
          final deletion = cubit.deleteAccount();
          await pumpEventQueue();
          current = signedOut ? null : b;
          gate.complete();
          await deletion;
          expect(avatars.deleted, isNot(contains('B')));
          expect(store.deleted, isNot(contains('B')));
          expect(authDeleted, isEmpty);
          expect(cubit.state.notice, ProfileNotice.deleteDifferentAccount);
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
          final deletion = cubit.deleteAccount();
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
          expect(cubit.state.notice, ProfileNotice.deleted);
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
      await cubit.deleteAccount();
      noDeletion();
      expect(cubit.state.notice, ProfileNotice.deleteDifferentAccount);
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
      await cubit.deleteAccount();
      expect(authDeleted, ['A']);
      expect(cubit.state.notice, ProfileNotice.deleted);
    },
  );

  for (final signedOut in [false, true]) {
    test(
      'Conta1 mudança durante leitura do perfil: logout=$signedOut',
      () async {
        final gate = profile.gate = Completer<void>();
        final deletion = cubit.deleteAccount();
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
}
