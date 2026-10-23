import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_invite_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('o convite sai uma vez por instalação', () async {
    LocalAccountInviteRepository reopen() =>
        LocalAccountInviteRepository(PreferencesService());

    expect(await reopen().pending(), isTrue);
    await reopen().markShown();
    expect(await reopen().pending(), isFalse);
  });

  test('sem o repositório do aparelho, nunca convida', () async {
    expect(await const NoAccountInviteRepository().pending(), isFalse);
  });
}
