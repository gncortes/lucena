import 'dart:async';

import 'package:lucena/data/services/firebase/cloud_store_service.dart';
import 'package:lucena/domain/models/push_permission.dart';

/// O Firestore na memória. Com [offline], a leitura falha e a gravação não
/// termina (fica na fila, como no Firestore de verdade).
class FakeCloudStoreService implements CloudStoreService {
  final users = <String, Map<String, Object?>>{};
  final progress = <String, Map<String, Object?>>{};
  final games = <String, Map<String, Map<String, Object?>>>{};
  final deleted = <String>[];

  /// O token do push de cada conta (`push/device`).
  final pushTokens = <String, String>{};

  /// A permissão e a abertura gravadas em `push/device` (H-R5-60).
  final pushStatus = <String, PushDeviceStatus>{};

  /// Os documentos abertos a todos, por `coleção/id`.
  final public = <String, Map<String, Object?>>{};
  bool offline = false;

  /// Os documentos criados em `feedback/` (com o uid de [currentUid], sem o
  /// `createdAt` do servidor).
  final feedback = <Map<String, Object?>>[];

  /// Quem está logado no Auth. Nulo: o feedback é recusado
  /// (`unauthenticated`), como no serviço de verdade.
  String? currentUid = 'me';

  /// As contas suspensas pelo admin (`bloqueios/{uid}`).
  final blocked = <String>{};

  /// Com `true`, a regra recusa o `feedback/` (a gravação falha na hora).
  bool refuseFeedback = false;

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
    pushTokens.remove(uid);
    pushStatus.remove(uid);
    feedback.removeWhere((doc) => doc['uid'] == uid);
  }

  @override
  Future<String?> readPushToken(String uid) async {
    if (offline) throw const CloudStoreException('unavailable');
    return pushTokens[uid];
  }

  @override
  Future<void> writePushToken(String uid, String token, DateTime at) {
    if (offline) return Completer<void>().future;
    pushTokens[uid] = token;
    return Future.value();
  }

  @override
  Future<void> deletePushToken(String uid) {
    if (offline) return Completer<void>().future;
    pushTokens.remove(uid);
    pushStatus.remove(uid);
    return Future.value();
  }

  @override
  Future<void> writePushStatus(String uid, PushDeviceStatus status) {
    if (offline) return Completer<void>().future;
    pushStatus[uid] = status;
    return Future.value();
  }

  @override
  Future<Map<String, Object?>?> readPublic(String collection, String id) async {
    if (offline) throw const CloudStoreException('unavailable');
    return public['$collection/$id'];
  }

  @override
  Future<void> addFeedback(Map<String, Object?> data) {
    if (refuseFeedback) {
      return Future.error(const CloudStoreException('permission-denied'));
    }
    final uid = currentUid;
    if (uid == null) {
      return Future.error(const CloudStoreException('unauthenticated'));
    }
    if (offline) return Completer<void>().future;
    feedback.add({...data, 'uid': uid});
    return Future.value();
  }

  @override
  Future<bool> readBlocked(String uid, DateTime now) async =>
      !offline && blocked.contains(uid);

  @override
  Future<CloudExport> exportUser(String uid) async {
    if (offline) throw const CloudStoreException('unavailable');
    return CloudExport(
      user: users[uid],
      progress: progress[uid],
      games: {...?games[uid]},
    );
  }
}
