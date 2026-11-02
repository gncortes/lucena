import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/lichess/lichess_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/avatar_photo.dart';
import '../../../domain/models/platform_rating.dart';
import '../../../domain/use_cases/analytics_rules.dart';

/// Um aviso do Perfil, mostrado uma vez.
enum ProfileNotice {
  /// A remoção não pôde ser concluída por falta de conexão.
  deleteOffline,

  /// O Firebase pediu um login recente; com e-mail, a tela pede a senha.
  deleteRelogin,
  deleteFailed,
  deleteDifferentAccount,
  deleted,

  /// "Atualizar o rating" sem rede: fica o de antes.
  lichessOffline,
}

class ProfileAccountState {
  const ProfileAccountState({
    this.account,
    this.lichess,
    this.syncedAt,
    this.busy = false,
    this.notice,
    this.noticeCount = 0,
  });

  /// Nulo: sem conta.
  final Account? account;

  /// A última leitura do Lichess. Nulo: desconectado.
  final PlatformRating? lichess;

  /// A última sincronização da conta neste aparelho.
  final DateTime? syncedAt;

  /// Apagando a conta ou lendo o Lichess.
  final bool busy;
  final ProfileNotice? notice;

  /// Muda a cada aviso, para a tela mostrar o mesmo aviso de novo.
  final int noticeCount;

  ProfileAccountState copyWith({
    Account? Function()? account,
    PlatformRating? Function()? lichess,
    DateTime? Function()? syncedAt,
    bool? busy,
    ProfileNotice? notice,
  }) => ProfileAccountState(
    account: account == null ? this.account : account(),
    lichess: lichess == null ? this.lichess : lichess(),
    syncedAt: syncedAt == null ? this.syncedAt : syncedAt(),
    busy: busy ?? this.busy,
    notice: notice ?? this.notice,
    noticeCount: notice == null ? noticeCount : noticeCount + 1,
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
  }) : super(ProfileAccountState(account: _accounts.current));

  final AccountRepository _accounts;
  final SyncScheduler _sync;
  final LichessRepository _lichess;
  final ProfileRepository _profile;
  final AnalyticsRepository _analytics;
  StreamSubscription<Account?>? _accountSubscription;
  StreamSubscription<String>? _syncSubscription;

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
      ),
    );
    if (account == null) return;
    await _readSyncedAt(account.uid);
    // Abrir o Perfil com conta sobe o que estiver pendente.
    try {
      await _sync.syncNow(account.uid);
    } on SyncException {
      // Sem rede: o cartão mostra a última vez e o aviso de offline.
    }
  }

  Future<void> _readSyncedAt(String uid) async {
    final at = await _sync.lastSyncedAt(uid);
    if (!isClosed && state.account?.uid == uid) {
      emit(state.copyWith(syncedAt: () => at));
    }
  }

  /// O progresso fica no aparelho; a conta continua na nuvem.
  Future<void> signOut() => _accounts.signOut();

  /// Fixa a conta confirmada antes de ler o perfil ou abrir o Google.
  Future<void> deleteAccount({String? expectedUid}) async {
    if (state.busy) return;
    final uid = expectedUid ?? state.account?.uid;
    if (uid == null) return _done(ProfileNotice.deleteFailed);
    await _delete(uid);
  }

  Future<void> _delete(String expectedUid) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final deleted = await _accounts.deleteAccount(
        expectedUid: expectedUid,
        photo: await _uploadedPhoto(),
      );
      if (!deleted) return _done(null);
      unawaited(_analytics.log(AnalyticsEvents.contaApagada()));
      _done(ProfileNotice.deleted);
    } on AccountException catch (error) {
      _done(_deleteNotice(error.failure));
    } on Object {
      _done(ProfileNotice.deleteFailed);
    }
  }

  /// Depois de entrar de novo com e-mail (pedido pelo Firebase): apaga só
  /// se a conta ainda é a [uid] confirmada no diálogo.
  Future<void> deleteAfterSignIn(String uid) async {
    if (_accounts.current?.uid != uid) {
      try {
        await _accounts.signOut();
      } on Object {
        // O aviso não promete que a saída foi concluída.
      }
      _done(ProfileNotice.deleteDifferentAccount);
      return;
    }
    await _delete(uid);
  }

  // Só a foto enviada mora no Storage; a do Google e a inicial, não.
  Future<bool> _uploadedPhoto() async =>
      (await _profile.load()).photo == AvatarPhoto.upload;

  static ProfileNotice _deleteNotice(AccountFailure failure) =>
      switch (failure) {
        AccountFailure.network => ProfileNotice.deleteOffline,
        AccountFailure.recentLoginRequired => ProfileNotice.deleteRelogin,
        AccountFailure.userMismatch => ProfileNotice.deleteDifferentAccount,
        _ => ProfileNotice.deleteFailed,
      };

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
    }
  }

  /// Tira o acesso ao Lichess e o vínculo do perfil; o rating fica.
  Future<void> disconnectLichess() async {
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
    return super.close();
  }
}
