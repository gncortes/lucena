import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_invite_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_now.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  // H-CON-02: "Agora não" (ou o X) suspende o convite por 7 dias, gravado no
  // aparelho; no 8º dia ele volta.
  test('o convite some por 7 dias e volta no 8º', () async {
    final now = FakeNow(DateTime(2026, 11, 4, 10));
    LocalAccountInviteRepository reopen() =>
        LocalAccountInviteRepository(PreferencesService(), now: now);

    expect(await reopen().pending(), isTrue);
    await reopen().markShown();
    expect(await reopen().pending(), isFalse);
    now.advance(const Duration(days: 6, hours: 23));
    expect(await reopen().pending(), isFalse);
    now.advance(const Duration(days: 1, hours: 1));
    expect(await reopen().pending(), isTrue);
  });

  test('quem já tinha visto o convite antigo volta a ser convidado', () async {
    // A chave antiga ("uma vez por instalação") não suspende para sempre.
    await PreferencesService().setBool('account.invited', value: true);
    final repository = LocalAccountInviteRepository(
      PreferencesService(),
      now: FakeNow(DateTime(2026, 11, 4)),
    );
    expect(await repository.pending(), isTrue);
  });

  test('sem o repositório do aparelho, nunca convida', () async {
    expect(await const NoAccountInviteRepository().pending(), isFalse);
  });
}
