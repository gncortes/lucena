import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/treinador/treinador.dart';
import '../../services/firebase/treinador_service.dart';
import '../../services/preferences_service.dart';

/// O Treinador de partidas (T87) da conta logada. Os documentos vêm do
/// servidor (com a cópia do Firestore sem rede); o progresso dos exercícios
/// fica no aparelho (sobrevive a fechar o app) e vai espelhado para
/// `partidas/{id}.progresso`.
///
/// Sem conta do Lucena, as leituras dão vazio e ligar a conta lança
/// [LigarContaException] com [FalhaLigarConta.semLogin].
abstract interface class TreinadorRepository {
  /// A conta ligada (nulo: nenhuma), agora e a cada mudança.
  Stream<TreinadorConta?> conta();

  /// Liga a conta do Lichess ou do chess.com. O servidor confere que o
  /// usuário existe. Lança [LigarContaException].
  Future<void> ligarConta(Plataforma plataforma, String usuario);

  Future<void> desligarConta();

  /// Liga ou desliga o aviso das partidas-modelo.
  Future<void> definirAvisoModelos({required bool ligado});

  /// As partidas, da mais nova, com o progresso do aparelho.
  Stream<List<PartidaTreinador>> partidas();

  /// Uma partida (nulo: não existe ou ilegível), com o progresso do aparelho.
  Stream<PartidaTreinador?> partida(String id);

  /// Pede a análise de uma partida nova. [avisar]: o push avisa quando
  /// terminar. Lança [TreinadorCallException] se o servidor recusar.
  Future<void> analisar(String id, {bool avisar = true});

  /// O progresso guardado no aparelho (ou o espelho do servidor).
  Future<ProgressoPartida> progresso(String id);

  /// Grava o progresso no aparelho e manda o espelho ao servidor.
  Future<void> salvarProgresso(String id, ProgressoPartida progresso);

  Stream<EstatisticasTreinador> estatisticas();

  Future<TreinadorConfig> config();

  Future<List<PartidaModelo>> modelos(String eco);
}

/// Sem Firebase: nada ligado.
final class NoTreinadorRepository implements TreinadorRepository {
  const NoTreinadorRepository();

  @override
  Stream<TreinadorConta?> conta() => Stream.value(null);

  @override
  Future<void> ligarConta(Plataforma plataforma, String usuario) async =>
      throw const LigarContaException(FalhaLigarConta.semResposta);

  @override
  Future<void> desligarConta() async {}

  @override
  Future<void> definirAvisoModelos({required bool ligado}) async {}

  @override
  Stream<List<PartidaTreinador>> partidas() => Stream.value(const []);

  @override
  Stream<PartidaTreinador?> partida(String id) => Stream.value(null);

  @override
  Future<void> analisar(String id, {bool avisar = true}) async =>
      throw const TreinadorCallException('unavailable');

  @override
  Future<ProgressoPartida> progresso(String id) async => ProgressoPartida.vazio;

  @override
  Future<void> salvarProgresso(String id, ProgressoPartida progresso) async {}

  @override
  Stream<EstatisticasTreinador> estatisticas() =>
      Stream.value(EstatisticasTreinador.vazia);

  @override
  Future<TreinadorConfig> config() async => TreinadorConfig.padrao;

  @override
  Future<List<PartidaModelo>> modelos(String eco) async => const [];
}

final class CloudTreinadorRepository implements TreinadorRepository {
  CloudTreinadorRepository(
    this._service,
    this._preferences, {
    required this._uids,
    required this._currentUid,
  });

  final TreinadorService _service;
  final PreferencesService _preferences;
  final Stream<String?> _uids;
  final String? Function() _currentUid;

  /// O progresso de cada partida no aparelho.
  static String progressoKey(String uid, String id) =>
      'treinador.progresso.$uid.$id';

  /// Avisa as telas abertas quando o progresso local muda.
  final _progressoMudou = StreamController<String>.broadcast();

  /// O fluxo de [porUid] da conta logada; troca quando a conta troca.
  Stream<T> _daConta<T>(Stream<T> Function(String uid) porUid, T semConta) {
    late final StreamController<T> out;
    StreamSubscription<T>? inner;
    StreamSubscription<String?>? accounts;
    String? atual;
    var primeiro = true;
    void follow(String? uid) {
      if (!primeiro && uid == atual) return;
      primeiro = false;
      atual = uid;
      unawaited(inner?.cancel());
      inner = null;
      if (uid == null) {
        out.add(semConta);
        return;
      }
      inner = porUid(uid).listen(
        out.add,
        // Sem permissão ou sem rede e sem cópia: fica o que já havia.
        onError: (Object e) => debugPrint('treinador sem ler: $e'),
      );
    }

    out = StreamController<T>(
      onListen: () {
        follow(_currentUid());
        accounts = _uids.listen(follow);
      },
      onCancel: () async {
        await accounts?.cancel();
        await inner?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Stream<TreinadorConta?> conta() => _daConta(
    (uid) => _service.watchConta(uid).map(TreinadorConta.fromJson),
    null,
  );

  @override
  Future<void> ligarConta(Plataforma plataforma, String usuario) async {
    if (_currentUid() == null) {
      throw const LigarContaException(FalhaLigarConta.semLogin);
    }
    try {
      await _service.call(TreinadorFunctions.ligarConta, {
        'plataforma': plataforma.wire,
        'usuario': usuario.trim(),
      });
    } on TreinadorCallException catch (e) {
      throw LigarContaException(switch (e.code) {
        'not-found' || 'invalid-argument' => FalhaLigarConta.naoExiste,
        'permission-denied' => FalhaLigarConta.semPlano,
        'unauthenticated' => FalhaLigarConta.semLogin,
        _ => FalhaLigarConta.semResposta,
      });
    }
  }

  @override
  Future<void> desligarConta() async {
    await _service.call(TreinadorFunctions.desligarConta, const {});
  }

  @override
  Future<void> definirAvisoModelos({required bool ligado}) async {
    await _service.call(TreinadorFunctions.avisoModelos, {'ligado': ligado});
  }

  @override
  Stream<List<PartidaTreinador>> partidas() => _daConta(
    (uid) => _comProgressoLocal(
      () => _service.watchPartidas(uid).asyncMap((docs) async {
        final lista = <PartidaTreinador>[
          for (final e in docs.entries)
            if (PartidaTreinador.fromJson(e.key, e.value) case final p?)
              await _juntar(uid, p),
        ];
        lista.sort((a, b) => b.jogadaEm.compareTo(a.jogadaEm));
        return lista;
      }),
    ),
    const [],
  );

  @override
  Stream<PartidaTreinador?> partida(String id) => _daConta(
    (uid) => _comProgressoLocal(
      () => _service.watchPartida(uid, id).asyncMap((doc) async {
        final p = doc == null ? null : PartidaTreinador.fromJson(id, doc);
        return p == null ? null : await _juntar(uid, p);
      }),
    ),
    null,
  );

  /// Reemite [source] quando o progresso local de qualquer partida muda.
  Stream<T> _comProgressoLocal<T>(Stream<T> Function() source) {
    late final StreamController<T> out;
    StreamSubscription<T>? a;
    StreamSubscription<String>? b;
    out = StreamController<T>(
      onListen: () {
        a = source().listen(out.add, onError: out.addError);
        // O documento não muda quando só o aparelho grava: lê de novo a
        // última versão com o progresso novo.
        b = _progressoMudou.stream.listen((_) {
          unawaited(a?.cancel());
          a = source().listen(out.add, onError: out.addError);
        });
      },
      onCancel: () async {
        await a?.cancel();
        await b?.cancel();
      },
    );
    return out.stream;
  }

  Future<PartidaTreinador> _juntar(String uid, PartidaTreinador p) async {
    final local = await _local(uid, p.id);
    return local == null ? p : p.copyWith(progresso: local);
  }

  Future<ProgressoPartida?> _local(String uid, String id) async {
    final stored = await _preferences.getString(progressoKey(uid, id));
    if (stored == null) return null;
    try {
      return ProgressoPartida.fromJson(jsonDecode(stored));
    } on Object {
      return null;
    }
  }

  @override
  Future<void> analisar(String id, {bool avisar = true}) async {
    await _service.call(TreinadorFunctions.analisar, {
      'partida': id,
      'avisar': avisar,
    });
  }

  @override
  Future<ProgressoPartida> progresso(String id) async {
    final uid = _currentUid();
    if (uid == null) return ProgressoPartida.vazio;
    final local = await _local(uid, id);
    if (local != null) return local;
    try {
      final doc = await _service.watchPartida(uid, id).first;
      final remoto = doc?['progresso'];
      return remoto == null
          ? ProgressoPartida.vazio
          : ProgressoPartida.fromJson(remoto);
    } on Object {
      return ProgressoPartida.vazio;
    }
  }

  @override
  Future<void> salvarProgresso(String id, ProgressoPartida progresso) async {
    final uid = _currentUid();
    if (uid == null) return;
    await _preferences.setString(
      progressoKey(uid, id),
      jsonEncode(progresso.toJson()),
    );
    if (!_progressoMudou.isClosed) _progressoMudou.add(id);
    // Sem rede, o Firestore guarda na fila; a tela não espera.
    unawaited(
      _service
          .writeProgresso(uid, id, progresso.toRemoto())
          .catchError((Object e) => debugPrint('progresso sem gravar: $e')),
    );
  }

  @override
  Stream<EstatisticasTreinador> estatisticas() => _daConta(
    (uid) =>
        _service.watchEstatisticas(uid).map(EstatisticasTreinador.fromJson),
    EstatisticasTreinador.vazia,
  );

  @override
  Future<TreinadorConfig> config() async {
    try {
      return TreinadorConfig.fromJson(await _service.readConfig());
    } on Object {
      return TreinadorConfig.padrao;
    }
  }

  @override
  Future<List<PartidaModelo>> modelos(String eco) async {
    try {
      return PartidaModelo.listFromJson(await _service.readModelos(eco));
    } on Object {
      return const [];
    }
  }
}
