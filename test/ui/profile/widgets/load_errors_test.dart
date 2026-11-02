import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/profile/widgets/profile_screen.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_lichess_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_sync_repository.dart';
import '../../../../testing/test_app.dart';

class _Profiles extends FakeProfileRepository {
  _Profiles() : super(const UserProfile(nickname: 'Ana', country: 'BR'));
  bool failing = false;
  Completer<UserProfile>? pending;
  @override
  Future<UserProfile> load() async {
    if (failing) throw StateError('profile');
    if (pending case final request?) return request.future;
    return super.load();
  }
}

void main() {
  testWidgets(
    'profile reload failure retains global profile and retry recovers',
    (tester) async {
      final repository = _Profiles();
      final cubit = ProfileCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      final saved = cubit.state;
      final accounts = FakeAccountRepository();
      final scheduler = SyncScheduler(accounts, FakeSyncRepository());
      addTearDown(scheduler.dispose);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          profileCubit: cubit,
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<SyncScheduler>.value(value: scheduler),
              RepositoryProvider<LichessRepository>.value(
                value: FakeLichessRepository(),
              ),
              RepositoryProvider<ProfileRepository>.value(value: repository),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ProfileKeys.screen), findsOneWidget);
      repository.failing = true;
      await cubit.load();
      await tester.pump();
      expect(cubit.state, same(saved));
      expect(
        tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
        LoadErrorKind.generic,
      );
      expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsOneWidget);
      repository.failing = false;
      final pending = repository.pending = Completer<UserProfile>();
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(LoadErrorKeys.action)).onPressed,
        isNull,
      );
      pending.complete(saved!);
      await tester.pump();
      expect(find.byKey(ProfileKeys.screen), findsOneWidget);
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
