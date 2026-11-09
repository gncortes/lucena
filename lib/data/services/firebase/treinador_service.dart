import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Os documentos do Treinador de partidas (T87) e as Functions que o app
/// chama. O servidor é dono do formato (`docs/tasks/T87-treinador.md`):
/// - `users/{uid}/treinador/conta` e `.../estatisticas`: só leitura;
/// - `users/{uid}/partidas/{id}`: só leitura, menos `progresso`;
/// - `treinador_config/geral` e `treinador_modelos/{eco}`: só leitura.
///
/// Ligar a conta e pedir a análise passam por callables: o servidor confere
/// o usuário no Lichess/chess.com e põe a partida na fila.
abstract interface class TreinadorService {
  Stream<Map<String, Object?>?> watchConta(String uid);

  /// As partidas, da mais nova (até [limite]). Chave: o id do documento.
  Stream<Map<String, Map<String, Object?>>> watchPartidas(
    String uid, {
    int limite,
  });

  Stream<Map<String, Object?>?> watchPartida(String uid, String id);

  Stream<Map<String, Object?>?> watchEstatisticas(String uid);

  Future<Map<String, Object?>?> readConfig();

  Future<Map<String, Object?>?> readModelos(String eco);

  /// Junta `progresso` (feitos, acertos, pontos) à partida. Sem rede, fica na
  /// fila do Firestore.
  Future<void> writeProgresso(
    String uid,
    String id,
    Map<String, Object?> progresso,
  );

  /// Chama a Function [nome] com [dados]. Lança [TreinadorCallException].
  Future<Object?> call(String nome, Map<String, Object?> dados);
}

/// A Function respondeu com erro (código do `HttpsError`: `not-found`,
/// `unavailable`, `permission-denied`, `unauthenticated`...).
final class TreinadorCallException implements Exception {
  const TreinadorCallException(this.code);

  final String code;

  @override
  String toString() => 'TreinadorCallException($code)';
}

/// Nomes das callables (combinados com a frente servidor).
abstract final class TreinadorFunctions {
  static const ligarConta = 'treinadorLigarConta';
  static const desligarConta = 'treinadorDesligarConta';
  static const analisar = 'treinadorAnalisar';
  static const avisoModelos = 'treinadorAvisoModelos';
}

class NoTreinadorService implements TreinadorService {
  const NoTreinadorService();

  @override
  Stream<Map<String, Object?>?> watchConta(String uid) => Stream.value(null);

  @override
  Stream<Map<String, Map<String, Object?>>> watchPartidas(
    String uid, {
    int limite = 200,
  }) => Stream.value(const {});

  @override
  Stream<Map<String, Object?>?> watchPartida(String uid, String id) =>
      Stream.value(null);

  @override
  Stream<Map<String, Object?>?> watchEstatisticas(String uid) =>
      Stream.value(null);

  @override
  Future<Map<String, Object?>?> readConfig() async => null;

  @override
  Future<Map<String, Object?>?> readModelos(String eco) async => null;

  @override
  Future<void> writeProgresso(
    String uid,
    String id,
    Map<String, Object?> progresso,
  ) async {}

  @override
  Future<Object?> call(String nome, Map<String, Object?> dados) async =>
      throw const TreinadorCallException('unavailable');
}

class FirebaseTreinadorService implements TreinadorService {
  FirebaseTreinadorService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Stream<Map<String, Object?>?> watchConta(String uid) =>
      _user(uid)
          .collection('treinador')
          .doc('conta')
          .snapshots()
          .map((s) => _doc(s.data()));

  @override
  Stream<Map<String, Map<String, Object?>>> watchPartidas(
    String uid, {
    int limite = 200,
  }) =>
      _user(uid)
          .collection('partidas')
          .orderBy('jogadaEm', descending: true)
          .limit(limite)
          .snapshots()
          .map((q) => {for (final d in q.docs) d.id: _doc(d.data())!});

  @override
  Stream<Map<String, Object?>?> watchPartida(String uid, String id) =>
      _user(uid)
          .collection('partidas')
          .doc(id)
          .snapshots()
          .map((s) => _doc(s.data()));

  @override
  Stream<Map<String, Object?>?> watchEstatisticas(String uid) =>
      _user(uid)
          .collection('treinador')
          .doc('estatisticas')
          .snapshots()
          .map((s) => _doc(s.data()));

  @override
  Future<Map<String, Object?>?> readConfig() async => _doc(
    (await _db.collection('treinador_config').doc('geral').get()).data(),
  );

  @override
  Future<Map<String, Object?>?> readModelos(String eco) async =>
      _doc((await _db.collection('treinador_modelos').doc(eco).get()).data());

  @override
  Future<void> writeProgresso(
    String uid,
    String id,
    Map<String, Object?> progresso,
  ) =>
      _user(uid)
          .collection('partidas')
          .doc(id)
          .set({'progresso': progresso}, SetOptions(merge: true));

  @override
  Future<Object?> call(String nome, Map<String, Object?> dados) async {
    try {
      final result = await _functions.httpsCallable(nome).call<Object?>(dados);
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      throw TreinadorCallException(error.code);
    } on FirebaseException catch (error) {
      throw TreinadorCallException(error.code);
    }
  }

  static Map<String, Object?>? _doc(Map<String, dynamic>? data) =>
      data == null ? null : _plain(data) as Map<String, Object?>;

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
