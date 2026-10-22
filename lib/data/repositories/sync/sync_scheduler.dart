import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/account.dart';
import '../account/account_repository.dart';
import 'sync_repository.dart';

/// Quando o progresso vai para a conta (E1.13, regra 12): ao entrar, ao abrir
/// o app com conta e um pouco depois de terminar uma partida ou uma aula.
/// [changes] avisa que o aparelho gravou progresso; os avisos em sequência
/// viram um envio só, [delay] depois do último, nunca um a cada lance.
class SyncScheduler {
  SyncScheduler(
    this._accounts,
    this._sync, {
    this._changes = const Stream.empty(),
    this.delay = const Duration(seconds: 20),
  });

  final AccountRepository _accounts;
  final SyncRepository _sync;
  final Stream<void> _changes;
  final Duration delay;

  StreamSubscription<Account?>? _accountSubscription;
  StreamSubscription<void>? _changeSubscription;
  Timer? _timer;
  ({String uid, Future<SyncResult> result})? _running;
  final _synced = StreamController<String>.broadcast();

  /// Avisa o uid de cada sincronização que terminou bem.
  Stream<String> get synced => _synced.stream;

  /// Quando a conta [uid] sincronizou pela última vez neste aparelho.
  Future<DateTime?> lastSyncedAt(String uid) => _sync.lastSyncedAt(uid);

  void start() {
    _accountSubscription ??= _accounts.changes.listen((account) {
      if (account != null) unawaited(_quiet(account.uid));
    });
    _changeSubscription ??= _changes.listen((_) {
      _timer?.cancel();
      _timer = Timer(delay, () {
        final account = _accounts.current;
        if (account != null) unawaited(_quiet(account.uid));
      });
    });
  }

  /// Sincroniza agora e espera a resposta (a tela "Bem-vindo de volta").
  /// Se já há uma sincronização da mesma conta andando, espera por ela.
  Future<SyncResult> syncNow(String uid) {
    final running = _running;
    if (running != null && running.uid == uid) return running.result;
    final result = _sync
        .sync(uid)
        .then((result) {
          if (!_synced.isClosed) _synced.add(uid);
          return result;
        })
        .whenComplete(() => _running = null);
    _running = (uid: uid, result: result);
    return result;
  }

  Future<void> _quiet(String uid) async {
    try {
      await syncNow(uid);
    } on SyncException {
      // Sem rede: a próxima partida ou a próxima abertura tenta de novo.
    } on Object catch (error) {
      debugPrint('Sincronização falhou: $error');
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _accountSubscription?.cancel();
    await _changeSubscription?.cancel();
    await _synced.close();
  }
}
