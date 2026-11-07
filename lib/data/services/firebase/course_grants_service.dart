import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// `acessos/{uid}` no Firestore (H-R5-61): o dono lê o documento e grava só
/// `vistos`; quem cria e muda os cursos é a Function.
abstract interface class CourseGrantsService {
  /// O documento a cada mudança, com as datas já em [DateTime]. Nulo: não
  /// existe. Sem rede, a cópia do Firestore (se houver) e depois o servidor.
  Stream<Map<String, Object?>?> watch(String uid);

  /// Grava `vistos.{courseId}` com [at], o `dadoEm` do acesso visto (nunca o
  /// relógio do aparelho). Só funciona com o documento já criado pela
  /// Function (as regras recusam criar).
  Future<void> markSeen(String uid, String courseId, DateTime at);
}

class NoCourseGrantsService implements CourseGrantsService {
  const NoCourseGrantsService();

  @override
  Stream<Map<String, Object?>?> watch(String uid) => const Stream.empty();

  @override
  Future<void> markSeen(String uid, String courseId, DateTime at) async {}
}

class FirestoreCourseGrantsService implements CourseGrantsService {
  FirestoreCourseGrantsService([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('acessos').doc(uid);

  @override
  Stream<Map<String, Object?>?> watch(String uid) =>
      _doc(uid).snapshots().map((snapshot) {
        final data = snapshot.data();
        return data == null ? null : _plain(data) as Map<String, Object?>;
      });

  @override
  Future<void> markSeen(String uid, String courseId, DateTime at) =>
      _doc(uid).update({'vistos.$courseId': Timestamp.fromDate(at)});

  /// Troca os [Timestamp] por [DateTime], em qualquer nível.
  static Object? _plain(Object? value) => switch (value) {
    final Timestamp t => t.toDate(),
    final Map<Object?, Object?> map => <String, Object?>{
      for (final e in map.entries) '${e.key}': _plain(e.value),
    },
    final List<Object?> list => [for (final v in list) _plain(v)],
    _ => value,
  };
}
