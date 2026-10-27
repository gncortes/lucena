import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/campaign/campaign_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/progress_summary.dart';

/// A entrada com conta: Google ou e-mail. [failure] vale por um aviso: a
/// tela mostra e o estado volta ao normal na próxima ação.
class AccountState {
  const AccountState({
    this.busy = false,
    this.done = false,
    this.created = false,
    this.restored,
    this.offline = false,
    this.failure,
  });

  final bool busy;

  /// Entrou: a tela segue.
  final bool done;

  /// A conta é nova (criada agora com e-mail): segue para "Seu perfil".
  final bool created;

  /// A conta já tinha progresso, agora junto com o do aparelho: segue para
  /// "Bem-vindo de volta". Nulo: a conta estava vazia ou sem rede.
  final SyncResult? restored;

  /// Entrou, mas sem rede a conta não foi lida (sobe depois, sozinho).
  final bool offline;
  final AccountFailure? failure;
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(
    this._accounts, {
    this._sync,
    this._analytics = const NoAnalyticsRepository(),
    this.moment,
    this._campaigns,
  }) : super(const AccountState());

  final AnalyticsRepository _analytics;

  /// A campanha do link de post (T84): quem aceitou o convite antes da aula
  /// e entrou conta o `campanha_cadastro` `feito`.
  final CampaignRepository? _campaigns;

  /// Em que momento o convite abriu (`conta_convite`): `pos_vitoria`. Nulo
  /// fora do convite.
  final String? moment;

  /// O convite foi aceito (Google ou e-mail) ou dispensado ("Agora não").
  void inviteAnswered({required bool accepted}) {
    final moment = this.moment;
    if (moment == null) return;
    unawaited(
      _analytics.log(
        AnalyticsEvents.contaConvite(
          resposta: accepted ? 'aceitou' : 'agora_nao',
          momento: moment,
        ),
      ),
    );
  }

  final AccountRepository _accounts;

  /// Sem ele (testes antigos), entrar não lê a conta.
  final SyncScheduler? _sync;

  /// A senha mínima (a tela diz "pelo menos 8 caracteres"; o Firebase
  /// aceitaria 6).
  static const minPassword = 8;

  Future<void> signInWithGoogle() =>
      _run(_accounts.signInWithGoogle, method: 'google');

  Future<void> signInWithEmail(String email, String password) => _run(
    () => _accounts.signInWithEmail(email.trim(), password),
    method: 'email',
  );

  Future<void> createWithEmail(String email, String password) {
    if (password.length < minPassword) {
      emit(const AccountState(failure: AccountFailure.weakPassword));
      return Future.value();
    }
    return _run(
      () => _accounts.createWithEmail(email.trim(), password),
      created: true,
      method: 'email',
    );
  }

  /// "Mandar o link" de senha nova. A resposta é a mesma com ou sem conta
  /// (ninguém descobre quais e-mails têm conta). Nulo: mandou; senão, o
  /// motivo (e-mail mal escrito, sem rede).
  Future<AccountFailure?> sendPasswordReset(String email) async {
    try {
      await _accounts.sendPasswordReset(email.trim());
      return null;
    } on AccountException catch (error) {
      return error.failure == AccountFailure.wrongCredentials
          ? null
          : error.failure;
    }
  }

  Future<void> _campaignSignedIn() async {
    final campaigns = _campaigns;
    if (campaigns == null || !await campaigns.takeInvited()) return;
    final campaign = await campaigns.active();
    if (campaign == null) return;
    await _analytics.log(
      AnalyticsEvents.campanhaCadastro(campaign, resposta: 'feito'),
    );
  }

  Future<void> _run(
    Future<Account?> Function() signIn, {
    bool created = false,
    String? method,
  }) async {
    if (state.busy) return;
    emit(const AccountState(busy: true));
    try {
      final account = await signIn();
      if (account == null) {
        if (!isClosed) emit(const AccountState());
        return;
      }
      final (restored, offline) = await _read(account, created: created);
      if (method != null) {
        unawaited(
          _analytics.log(
            created
                ? AnalyticsEvents.signUp(method: method)
                : AnalyticsEvents.login(method: method),
          ),
        );
      }
      unawaited(_campaignSignedIn());
      if (restored != null) {
        unawaited(
          _analytics.log(
            AnalyticsEvents.contaProgressoRecuperado(
              itens: _items(restored.summary),
            ),
          ),
        );
      }
      if (!isClosed) {
        emit(
          AccountState(
            done: true,
            created: created,
            restored: restored,
            offline: offline,
          ),
        );
      }
    } on AccountException catch (error) {
      if (!isClosed) emit(AccountState(failure: error.failure));
    }
  }

  // Junta a conta com o aparelho (regra 13). Uma conta criada agora está
  // vazia: só sobe, sem tela de "Bem-vindo de volta".
  Future<(SyncResult?, bool)> _read(
    Account account, {
    required bool created,
  }) async {
    final sync = _sync;
    if (sync == null) return (null, false);
    try {
      final result = await sync.syncNow(account.uid);
      return (!created && result.hadRemote ? result : null, false);
    } on SyncException {
      return (null, true);
    }
  }

  // Quanto a conta trouxe: aulas, desafios, posições e partidas guardadas.
  static int _items(ProgressSummary s) =>
      s.lessons.length +
      s.school.length +
      s.stars.length +
      s.challenges.length +
      s.positions.length +
      s.featured.length;

  /// "Seu perfil" salvo com conta: o nome vai para a conta e o progresso
  /// sobe. Sem esperar: sem rede, sobe depois, sozinho.
  void publishProfile(String name) {
    final account = _accounts.current;
    if (account == null) return;
    unawaited(
      _accounts.updateProfile(name: name.trim()).catchError((Object _) {}),
    );
    final sync = _sync;
    if (sync != null) {
      unawaited(
        sync.syncNow(account.uid).then<void>((_) {}, onError: (Object _) {}),
      );
    }
  }
}
