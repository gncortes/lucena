import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Apaga o perfil e tudo abaixo dele que o app grava.
  Future<void> deleteUser(String uid);
}

class NoCloudStoreService implements CloudStoreService {
  const NoCloudStoreService();

  @override
  Future<void> mergeUser(String uid, Map<String, Object?> data) async {}

  @override
  Future<void> deleteUser(String uid) async {}
}

class FirestoreCloudStoreService implements CloudStoreService {
  FirestoreCloudStoreService([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // As subcoleções que o app grava: apagar a conta passa por todas.
  static const _subcollections = ['progress', 'games'];

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Future<void> mergeUser(String uid, Map<String, Object?> data) =>
      _user(uid).set(data, SetOptions(merge: true));

  @override
  Future<void> deleteUser(String uid) async {
    final user = _user(uid);
    for (final name in _subcollections) {
      final docs = await user.collection(name).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }
    await user.delete();
  }
}
