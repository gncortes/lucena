import 'dart:async';

import 'package:lucena/data/services/firebase/cloud_store_service.dart';

/// O Firestore na memória. Com [offline], a leitura falha e a gravação não
/// termina (fica na fila, como no Firestore de verdade).
class FakeCloudStoreService implements CloudStoreService {
  final users = <String, Map<String, Object?>>{};
  final progress = <String, Map<String, Object?>>{};
  final games = <String, Map<String, Map<String, Object?>>>{};
  final deleted = <String>[];
  bool offline = false;

  /// Quantas vezes cada partida foi mandada (a regra deixa só criar).
  final gameWrites = <String, int>{};

  @override
  Future<void> mergeUser(String uid, Map<String, Object?> data) {
    if (offline) return Completer<void>().future;
    users[uid] = {...?users[uid], ...data};
    return Future.value();
  }

  @override
  Future<Map<String, Object?>?> readProgress(String uid) async {
    if (offline) throw const CloudStoreException('unavailable');
    return progress[uid];
  }

  @override
  Future<void> writeProgress(String uid, Map<String, Object?> data) {
    if (offline) return Completer<void>().future;
    progress[uid] = data;
    return Future.value();
  }

  @override
  Future<void> writeGame(String uid, String id, Map<String, Object?> data) {
    if (offline) return Completer<void>().future;
    gameWrites[id] = (gameWrites[id] ?? 0) + 1;
    (games[uid] ??= {}).putIfAbsent(id, () => data);
    return Future.value();
  }

  @override
  Future<void> deleteUser(String uid) async {
    if (offline) throw const CloudStoreException('unavailable');
    deleted.add(uid);
    users.remove(uid);
    progress.remove(uid);
    games.remove(uid);
  }
}
