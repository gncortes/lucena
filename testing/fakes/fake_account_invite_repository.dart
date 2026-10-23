import 'package:lucena/data/repositories/account/account_invite_repository.dart';

/// Por padrão o convite ainda não saiu.
class FakeAccountInviteRepository implements AccountInviteRepository {
  FakeAccountInviteRepository({this.shown = false});

  bool shown;

  @override
  Future<bool> pending() async => !shown;

  @override
  Future<void> markShown() async => shown = true;
}
