import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/lichess/lichess_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/platform_rating.dart';
import '../../../domain/use_cases/analytics_rules.dart';

/// Um aviso do Perfil, mostrado uma vez.
enum ProfileNotice {
  /// "Atualizar o rating" sem rede: fica o de antes.
  lichessOffline,

  /// Sair ou desconectar o Lichess falhou: "Ocorreu um erro inesperado" e
  /// tudo fica como estava (gap 5).
  failed,
}

/// Onde está o envio do progresso para a conta (cartão do Perfil).
enum ProfileSyncPhase {
  /// Ainda não tentou neste Perfil: o cartão mostra a última vez salva.
  idle,

  /// Enviando: "Salvando…".
  saving,

  /// Terminou bem: "Salvo agora".
  saved,

  /// Sem rede: a última vez salva e o aviso de que fica no celular.
  offline,
}

class ProfileAccountState {
  const ProfileAccountState({
    this.account,
    this.lichess,
    this.syncedAt,
    this.syncPhase = ProfileSyncPhase.idle,
    this.busy = false,
    this.notice,
    this.noticeCount = 0,
    this.blocked = false,
  });

  /// Nulo: sem conta.
  final Account? account;

  /// A última leitura do Lichess. Nulo: desconectado.
  final PlatformRating? lichess;

  /// A última sincronização da conta neste aparelho.
  final DateTime? syncedAt;

  /// O envio de agora; o cartão da conta se desenha por ele.
  final ProfileSyncPhase syncPhase;

  /// Lendo o Lichess.
  final bool busy;
  final ProfileNotice? notice;

  /// Muda a cada aviso, para a tela mostrar o mesmo aviso de novo.
  final int noticeCount;

  /// A conta foi suspensa pelo admin: a nuvem recusa as gravações e o
  /// progresso segue no aparelho. Acompanhado ao vivo; a tela mostra o aviso
  /// `ProfileKeys.accountBlocked`.
  final bool blocked;

  ProfileAccountState copyWith({
    Account? Function()? account,
    PlatformRating? Function()? lichess,
    DateTime? Function()? syncedAt,
    ProfileSyncPhase? syncPhase,
    bool? busy,
    ProfileNotice? notice,
    bool? blocked,
  }) => ProfileAccountState(
    account: account == null ? this.account : account(),
    lichess: lichess == null ? this.lichess : lichess(),
    syncedAt: syncedAt == null ? this.syncedAt : syncedAt(),
    syncPhase: syncPhase ?? this.syncPhase,
    busy: busy ?? this.busy,
    notice: notice ?? this.notice,
    noticeCount: notice == null ? noticeCount : noticeCount + 1,
    blocked: blocked ?? this.blocked,
  );
}

/// A parte do Perfil que não é o perfil gravado (esse fica no
/// `ProfileCubit`): a conta, a sincronização e o Lichess.
class ProfileAccountCubit extends Cubit<ProfileAccountState> {
  ProfileAccountCubit({
    required this._accounts,
    required this._sync,
    required this._lichess,
    required this._profile,
    this._analytics = const NoAnalyticsRepository(),
    this.saveTimeout = const Duration(seconds: 10),
  }) : super(ProfileAccountState(account: _accounts.current));

  final AccountRepository _accounts;
  final SyncScheduler _sync;
  final LichessRepository _lichess;
  final ProfileRepository _profile;
  final AnalyticsRepository _analytics;

  /// Quanto o cartão espera o envio antes de dizer que ficou no celular.
  final Duration saveTimeout;
  StreamSubscription<Account?>? _accountSubscription;
  StreamSubscription<String>? _syncSubscription;
  StreamSubscription<bool>? _blockedSubscription;

  /// A conta cuja suspensão [_blockedSubscription] acompanha.
  String? _blockedUid;

  Future<void> load() async {
    _accountSubscription ??= _accounts.changes.listen(_accountChanged);
    _syncSubscription ??= _sync.synced.listen((uid) async {
      if (uid == state.account?.uid) await _readSyncedAt(uid);
    });
    final lichess = await _lichess.lastRead();
    if (!isClosed) emit(state.copyWith(lichess: () => lichess));
  }

  Future<void> _accountChanged(Account? account) async {
    if (isClosed) return;
    final same = account?.uid == state.account?.uid;
    emit(
      state.copyWith(
        account: () => account,
        syncedAt: same ? null : () => null,
        syncPhase: same ? null : ProfileSyncPhase.idle,
        blocked: same ? null : false,
      ),
    );
    if (account?.uid != _blockedUid) _watchBlocked(account?.uid);
    if (account == null) return;
    await _readSyncedAt(account.uid);
    // Abrir o Perfil com conta sobe o que estiver pendente.
    if (!isClosed) emit(state.copyWith(syncPhase: ProfileSyncPhase.saving));
    final save = _sync.saveNow(account.uid);
    var phase = ProfileSyncPhase.saved;
    try {
      await save.timeout(saveTimeout);
    } on SyncException {
      // Sem rede ou envio que falhou: o cartão mostra a última vez e o aviso de offline.
      phase = ProfileSyncPhase.offline;
    } on TimeoutException {
      // Sem rede, a escrita só termina quando o servidor confirma: o cartão
      // diz que fica no celular e, se a confirmação vier depois, vira "salvo".
      phase = ProfileSyncPhase.offline;
      unawaited(_savedLater(save, account.uid));
    }
    await _finish(account.uid, phase);
  }

  Future<void> _savedLater(Future<Object?> save, String uid) async {
    try {
      await save;
    } on Object {
      return;
    }
    await _finish(uid, ProfileSyncPhase.saved);
  }

  Future<void> _finish(String uid, ProfileSyncPhase phase) async {
    if (isClosed || state.account?.uid != uid) return;
    emit(state.copyWith(syncPhase: phase));
    await _readSyncedAt(uid);
  }

  /// Acompanha a suspensão da conta [uid] enquanto ela estiver no Perfil:
  /// o admin pode suspender ou liberar com a tela aberta (H-R5-43).
  void _watchBlocked(String? uid) {
    unawaited(_blockedSubscription?.cancel());
    _blockedSubscription = null;
    _blockedUid = uid;
    if (uid == null) return;
    _blockedSubscription = _accounts.blockedChanges(uid).listen(
      (blocked) {
        if (!isClosed && state.account?.uid == uid) {
          emit(state.copyWith(blocked: blocked));
        }
      },
      // Sem a leitura, o cartão segue como sempre; o servidor recusa igual.
      onError: reportHandledError,
    );
  }

  Future<void> _readSyncedAt(String uid) async {
    final at = await _sync.lastSyncedAt(uid);
    if (!isClosed && state.account?.uid == uid) {
      emit(state.copyWith(syncedAt: () => at));
    }
  }

  /// O progresso fica no aparelho; a conta continua na nuvem. Falhando,
  /// a conta fica e o aviso aparece (gap 5).
  Future<void> signOut() => _guard(_accounts.signOut);

  Future<void> _guard(Future<void> Function() action) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await action();
      _done(null);
    } on Object catch (error, stack) {
      debugPrint('profile action failed: $error');
      reportHandledError(error, stack);
      _done(ProfileNotice.failed);
    }
  }

  void _done(ProfileNotice? notice) {
    if (!isClosed) emit(state.copyWith(busy: false, notice: notice));
  }

  /// Lê os ratings do Lichess de novo. Sem rede, fica a leitura de antes.
  Future<void> refreshLichess() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final rating = await _lichess.account();
      if (!isClosed) {
        emit(state.copyWith(busy: false, lichess: () => rating));
      }
    } on LichessException {
      _done(ProfileNotice.lichessOffline);
    } on Object catch (error, stack) {
      // Outra falha: "Ocorreu um erro inesperado" e a leitura de antes fica.
      reportHandledError(error, stack);
      _done(ProfileNotice.failed);
    }
  }

  /// Tira o acesso ao Lichess e o vínculo do perfil; o rating fica.
  Future<void> disconnectLichess() => _guard(_disconnectLichess);

  Future<void> _disconnectLichess() async {
    await _lichess.disconnect();
    final profile = await _profile.load();
    await _profile.save(
      profile.copyWith(lichessUser: null, lichessLinkedAt: null),
    );
    unawaited(
      _analytics.setTrait(
        AnalyticsTrait.lichessLinked,
        AnalyticsRules.yesNo(false),
      ),
    );
    if (!isClosed) emit(state.copyWith(lichess: () => null));
  }

  @override
  Future<void> close() async {
    await _accountSubscription?.cancel();
    await _syncSubscription?.cancel();
    await _blockedSubscription?.cancel();
    return super.close();
  }
}
