import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/lichess/lichess_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/platform_rating.dart';

/// Um aviso do Perfil, mostrado uma vez.
enum ProfileNotice {
  /// Apagar sem rede: nada foi apagado.
  deleteOffline,

  /// O Firebase pediu um login recente; com e-mail, a tela pede a senha.
  deleteRelogin,
  deleteFailed,
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
  }) : super(ProfileAccountState(account: _accounts.current));

  final AccountRepository _accounts;
  final SyncScheduler _sync;
  final LichessRepository _lichess;
  final ProfileRepository _profile;
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

  /// Apaga a conta (diálogo confirmado). Com Google, um login recente
  /// pedido pelo Firebase é feito aqui mesmo e a conta é apagada em seguida.
  Future<void> deleteAccount() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _accounts.deleteAccount();
      _done(ProfileNotice.deleted);
    } on AccountException catch (error) {
      if (error.failure == AccountFailure.recentLoginRequired &&
          state.account?.provider == AccountProvider.google) {
        await _deleteAfterGoogle();
        return;
      }
      _done(_deleteNotice(error.failure));
    }
  }

  /// Depois de entrar de novo com e-mail (pedido pelo Firebase): apaga só
  /// se a conta ainda é a [uid] confirmada no diálogo.
  Future<void> deleteAfterSignIn(String uid) async {
    if (_accounts.current?.uid != uid) {
      emit(state.copyWith(notice: ProfileNotice.deleteFailed));
      return;
    }
    await deleteAccount();
  }

  Future<void> _deleteAfterGoogle() async {
    try {
      final account = await _accounts.signInWithGoogle();
      if (account == null) return _done(null);
      await _accounts.deleteAccount();
      _done(ProfileNotice.deleted);
    } on AccountException catch (error) {
      _done(_deleteNotice(error.failure));
    }
  }

  static ProfileNotice _deleteNotice(AccountFailure failure) =>
      switch (failure) {
        AccountFailure.network => ProfileNotice.deleteOffline,
        AccountFailure.recentLoginRequired => ProfileNotice.deleteRelogin,
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
    await _profile.save(profile.copyWith(lichessUser: null));
    if (!isClosed) emit(state.copyWith(lichess: () => null));
  }

  @override
  Future<void> close() async {
    await _accountSubscription?.cancel();
    await _syncSubscription?.cancel();
    return super.close();
  }
}
