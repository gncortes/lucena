import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/avatar_photo.dart';

/// Em que ponto está a folha "Excluir sua conta?" (H-CON-14).
enum AccountDeleteStep {
  /// A pergunta, com os botões livres.
  ask,

  /// Apagando: "Excluir minha conta" em carregando e os dois botões travados.
  deleting,

  /// Conta de e-mail sem login recente: a tela pede a senha de novo antes
  /// de apagar qualquer dado (gap 2).
  relogin,

  /// A conta saiu; a folha fecha e quem a abriu mostra o aviso.
  deleted,

  /// O novo login trouxe outra conta: nada foi apagado e a sessão saiu
  /// (gap 1); a folha fecha com o aviso.
  differentAccount,
}

/// O aviso dentro da folha, de volta à pergunta.
enum AccountDeleteNotice {
  /// "Sem internet não dá para excluir a conta. Nada foi excluído."
  offline,

  /// "Ocorreu um erro inesperado" e "Tentar de novo" (gap 4); também a
  /// queda no meio, que não pode dizer que nada saiu (gap 9).
  failed,

  /// Desistiu do novo login: nada foi excluído.
  cancelled,
}

class AccountDeleteState {
  const AccountDeleteState({this.step = AccountDeleteStep.ask, this.notice});

  final AccountDeleteStep step;
  final AccountDeleteNotice? notice;

  bool get busy => step == AccountDeleteStep.deleting;

  @override
  bool operator ==(Object other) =>
      other is AccountDeleteState &&
      other.step == step &&
      other.notice == notice;

  @override
  int get hashCode => Object.hash(step, notice);
}

/// Excluir a conta confirmada [_uid]: login recente, conferir o `uid`,
/// foto, nuvem, Auth e sair (a ordem mora no [AccountRepository]).
class AccountDeleteCubit extends Cubit<AccountDeleteState> {
  AccountDeleteCubit({
    required this._uid,
    required this._accounts,
    required this._profile,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const AccountDeleteState());

  /// A conta confirmada ao abrir a folha; nenhuma outra é apagada.
  final String _uid;
  final AccountRepository _accounts;
  final ProfileRepository _profile;
  final AnalyticsRepository _analytics;

  /// "Excluir minha conta" (e "Tentar de novo").
  Future<void> confirm() async {
    if (state.busy) return;
    emit(const AccountDeleteState(step: AccountDeleteStep.deleting));
    try {
      final deleted = await _accounts.deleteAccount(
        expectedUid: _uid,
        photo: await _uploadedPhoto(),
      );
      if (!deleted) return _ask(AccountDeleteNotice.cancelled);
      unawaited(_analytics.log(AnalyticsEvents.contaApagada()));
      _emit(const AccountDeleteState(step: AccountDeleteStep.deleted));
    } on AccountException catch (error) {
      switch (error.failure) {
        case AccountFailure.network:
          _ask(AccountDeleteNotice.offline);
        case AccountFailure.recentLoginRequired:
          _emit(const AccountDeleteState(step: AccountDeleteStep.relogin));
        case AccountFailure.userMismatch:
          _emit(
            const AccountDeleteState(step: AccountDeleteStep.differentAccount),
          );
        case _:
          _ask(AccountDeleteNotice.failed);
      }
    } on Object catch (error, stack) {
      debugPrint('account delete failed: $error');
      reportHandledError(error, stack);
      _ask(AccountDeleteNotice.failed);
    }
  }

  /// A volta do novo login com e-mail. [signedIn] falso: a pessoa desistiu.
  /// Apaga só se a conta ainda é a confirmada na folha.
  Future<void> afterSignIn({required bool signedIn}) async {
    if (!signedIn) return _ask(AccountDeleteNotice.cancelled);
    if (_accounts.current?.uid != _uid) {
      try {
        await _accounts.signOut();
      } on Object {
        // O aviso não promete que a saída foi concluída.
      }
      _emit(const AccountDeleteState(step: AccountDeleteStep.differentAccount));
      return;
    }
    emit(const AccountDeleteState());
    await confirm();
  }

  // Só a foto enviada mora no Storage; a do Google e a inicial, não.
  Future<bool> _uploadedPhoto() async =>
      (await _profile.load()).photo == AvatarPhoto.upload;

  void _ask(AccountDeleteNotice notice) =>
      _emit(AccountDeleteState(notice: notice));

  void _emit(AccountDeleteState state) {
    if (!isClosed) emit(state);
  }
}
