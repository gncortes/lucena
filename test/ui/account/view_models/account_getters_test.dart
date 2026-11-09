import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/progress_summary.dart';
import 'package:lucena/ui/account/view_models/account_cubit.dart';
import 'package:lucena/ui/account/view_models/account_photo_cubit.dart';
import 'package:lucena/ui/account/view_models/account_restored_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_avatar_repository.dart';
import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_photo_repository.dart';

/// O que as telas da conta liam direto do repositório e agora vem do cubit.
void main() {
  group('AccountCubit.signedIn', () {
    test('com conta entrada', () async {
      final cubit = AccountCubit(
        FakeAccountRepository(account: FakeAccountRepository.google),
      );
      addTearDown(cubit.close);
      expect(cubit.signedIn, isTrue);
    });

    test('sem conta', () async {
      final cubit = AccountCubit(FakeAccountRepository());
      addTearDown(cubit.close);
      expect(cubit.signedIn, isFalse);
    });
  });

  group('AccountPhotoCubit', () {
    AccountPhotoCubit photo(FakeAccountRepository accounts) =>
        AccountPhotoCubit(
          accounts: accounts,
          photos: FakePhotoRepository(null),
          avatars: FakeAvatarRepository(),
        );

    test('o nome e a conta entrada vêm da conta', () async {
      final cubit = photo(
        FakeAccountRepository(account: FakeAccountRepository.google),
      );
      addTearDown(cubit.close);
      expect(cubit.accountName, FakeAccountRepository.google.name);
      expect(cubit.signedIn, isTrue);
    });

    test('sem conta, nem nome nem conta entrada', () async {
      final cubit = photo(FakeAccountRepository());
      addTearDown(cubit.close);
      expect(cubit.accountName, isNull);
      expect(cubit.signedIn, isFalse);
    });
  });

  group('AccountRestoredCubit.accountName', () {
    AccountRestoredCubit restored({FakeAccountRepository? accounts}) =>
        AccountRestoredCubit(
          const ProgressSummary(),
          FakeJourneyRepository(),
          FakeCharacterRepository(),
          accounts: accounts,
        );

    test('o nome da conta que entrou', () async {
      final cubit = restored(
        accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      );
      addTearDown(cubit.close);
      expect(cubit.accountName, FakeAccountRepository.google.name);
    });

    test('sem o repositório, nenhum', () async {
      final cubit = restored();
      addTearDown(cubit.close);
      expect(cubit.accountName, isNull);
    });
  });
}
