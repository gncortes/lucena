import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_invite_repository.dart';
import '../../../data/repositories/account/account_repository.dart';

/// O convite da conta no fim de uma partida que acabou agora (H-CON-02):
/// verdadeiro enquanto o cartão aparece. Sem [AccountInviteRepository],
/// nunca convida.
class ConclusionInviteCubit extends Cubit<bool> {
  ConclusionInviteCubit({this._accounts, this._invite}) : super(false);

  final AccountRepository? _accounts;
  final AccountInviteRepository? _invite;

  /// Mostra o cartão a quem está sem conta, se o convite não está suspenso.
  Future<void> check() async {
    final invite = _invite;
    if (invite == null) return;
    if (_accounts?.current != null) return;
    if (!await invite.pending()) return;
    if (!isClosed) emit(true);
  }

  /// O X do cartão vale como "Agora não": some e suspende por 7 dias.
  Future<void> dismiss() async {
    if (!state) return;
    emit(false);
    await _invite!.markShown();
  }
}
