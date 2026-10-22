import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Os documentos de cada conta no Firestore. O desenho e as regras estão em
/// `firebase/firestore.rules` (resumo em `firebase/README.md`):
/// - `users/{uid}`: o perfil;
/// - `users/{uid}/progress/summary` e `users/{uid}/games/{id}`: o progresso
///   (E1.13).
///
/// O Firestore guarda as gravações sem rede e as manda quando ela volta.
abstract class CloudStoreService {
  /// Junta [data] ao perfil (cria se não existe).
  Future<void> mergeUser(String uid, Map<String, Object?> data);

  /// O resumo do progresso (`progress/summary`). Nulo: a conta ainda não
  /// tem. Lança [CloudStoreException] sem rede e sem cópia no aparelho.
  Future<Map<String, Object?>?> readProgress(String uid);

  /// Troca o resumo do progresso. Termina quando o servidor confirma.
  Future<void> writeProgress(String uid, Map<String, Object?> data);

  /// Grava uma partida em `games/{id}`. A partida não muda depois de
  /// gravada: se o [id] já existe, nada acontece.
  Future<void> writeGame(String uid, String id, Map<String, Object?> data);

  /// Apaga o perfil e tudo abaixo dele que o app grava. Precisa de rede:
  /// sem ela lança [CloudStoreException] em vez de apagar só a cópia local.
  Future<void> deleteUser(String uid);
}

/// O Firestore não respondeu (sem rede, sem permissão).
class CloudStoreException implements Exception {
  const CloudStoreException(this.code);

  final String code;

  @override
  String toString() => 'CloudStoreException($code)';
}

class NoCloudStoreService implements CloudStoreService {
  const NoCloudStoreService();

  @override
  Future<void> mergeUser(String uid, Map<String, Object?> data) async {}

  @override
  Future<Map<String, Object?>?> readProgress(String uid) async => null;

  @override
  Future<void> writeProgress(String uid, Map<String, Object?> data) async {}

  @override
  Future<void> writeGame(
    String uid,
    String id,
    Map<String, Object?> data,
  ) async {}

  @override
  Future<void> deleteUser(String uid) async {}
}

class FirestoreCloudStoreService implements CloudStoreService {
  FirestoreCloudStoreService({
    FirebaseFirestore? firestore,
    String? Function()? currentUid,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseFirestore _db;

  /// Quem está logado no Auth agora (nulo: ninguém).
  final String? Function() _currentUid;

  // Sem rede, set e delete ficam na fila e só terminam quando o servidor
  // confirma; apagar a conta não espera para sempre.
  static const _deleteTimeout = Duration(seconds: 30);

  // As subcoleções que o app grava: apagar a conta passa por todas.
  static const _subcollections = ['progress', 'games'];

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Future<void> mergeUser(String uid, Map<String, Object?> data) =>
      _user(uid).set(data, SetOptions(merge: true));

  DocumentReference<Map<String, dynamic>> _summary(String uid) =>
      _user(uid).collection('progress').doc('summary');

  @override
  Future<Map<String, Object?>?> readProgress(String uid) async {
    try {
      return (await _summary(uid).get()).data();
    } on FirebaseException catch (error) {
      throw CloudStoreException(error.code);
    }
  }

  @override
  Future<void> writeProgress(String uid, Map<String, Object?> data) async {
    try {
      await _summary(uid).set(data);
    } on FirebaseException catch (error) {
      throw CloudStoreException(error.code);
    }
  }

  @override
  Future<void> writeGame(
    String uid,
    String id,
    Map<String, Object?> data,
  ) async {
    try {
      await _user(uid).collection('games').doc(id).set(data);
    } on FirebaseException catch (error) {
      // As regras não deixam mudar uma partida: o id já existe, ela já está
      // lá. Mas a mesma recusa vem sem login ou com o token vencido; aí não
      // é "já gravada".
      if (error.code == 'permission-denied' && _currentUid() == uid) return;
      throw CloudStoreException(error.code);
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    final user = _user(uid);
    // Do servidor: sem rede, o get() comum leria só o cache do aparelho e
    // deixaria partidas na nuvem.
    const server = GetOptions(source: Source.server);
    try {
      await () async {
        for (final name in _subcollections) {
          final docs = await user.collection(name).get(server);
          for (final doc in docs.docs) {
            await doc.reference.delete();
          }
        }
        await user.delete();
      }().timeout(_deleteTimeout);
    } on FirebaseException catch (error) {
      throw CloudStoreException(error.code);
    } on TimeoutException {
      throw const CloudStoreException('unavailable');
    }
  }
}
