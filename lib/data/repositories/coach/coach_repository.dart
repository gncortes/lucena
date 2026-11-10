import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/coach/coach.dart';
import '../../services/firebase/coach_service.dart';
import '../../services/preferences_service.dart';

/// O Treinador de partidas (T87) da conta logada. Os documentos vêm do
/// servidor (com a cópia do Firestore sem rede); o progresso dos exercícios
/// fica no aparelho (sobrevive a fechar o app) e vai espelhado para
/// `partidas/{id}.progresso`.
///
/// Sem conta do Lucena, as leituras dão vazio e ligar a conta lança
/// [LinkAccountException] com [LinkAccountFailure.noLogin].
abstract interface class CoachRepository {
  /// A conta ligada (nulo: nenhuma), agora e a cada mudança.
  Stream<CoachAccount?> account();

  /// Liga a conta do Lichess ou do chess.com. O servidor confere que o
  /// usuário existe. Lança [LinkAccountException].
  Future<void> linkAccount(Platform platform, String username);

  /// Liga a conta do Lichess pelo login de lá: o servidor lê o dono do
  /// [token] no Lichess, o que prova que a conta é de quem liga. Lança
  /// [LinkAccountException] ([LinkAccountFailure.lichessLogin]: token
  /// que não vale mais).
  Future<void> linkLichess(String token);

  Future<void> unlinkAccount();

  /// Liga ou desliga o aviso das partidas-modelo.
  Future<void> setModelGamesNotice({required bool linked});

  /// As partidas, da mais nova, com o progresso do aparelho.
  Stream<List<CoachGame>> games();

  /// Uma partida (nulo: não existe ou ilegível), com o progresso do aparelho.
  Stream<CoachGame?> game(String id);

  /// Pede a análise de uma partida nova. [notify]: o push avisa quando
  /// terminar. Lança [CoachCallException] se o servidor recusar.
  Future<void> analyze(String id, {bool notify = true});

  /// O progresso guardado no aparelho (ou o espelho do servidor).
  Future<GameProgress> progress(String id);

  /// Grava o progresso no aparelho e manda o espelho ao servidor.
  Future<void> saveProgress(String id, GameProgress progress);

  Stream<CoachStats> stats();

  Future<CoachConfig> config();

  Future<List<ModelGame>> modelGames(String eco);
}

/// Sem Firebase: nada ligado.
final class NoCoachRepository implements CoachRepository {
  const NoCoachRepository();

  @override
  Stream<CoachAccount?> account() => Stream.value(null);

  @override
  Future<void> linkAccount(Platform platform, String username) async =>
      throw const LinkAccountException(LinkAccountFailure.noResponse);

  @override
  Future<void> linkLichess(String token) async =>
      throw const LinkAccountException(LinkAccountFailure.noResponse);

  @override
  Future<void> unlinkAccount() async {}

  @override
  Future<void> setModelGamesNotice({required bool linked}) async {}

  @override
  Stream<List<CoachGame>> games() => Stream.value(const []);

  @override
  Stream<CoachGame?> game(String id) => Stream.value(null);

  @override
  Future<void> analyze(String id, {bool notify = true}) async =>
      throw const CoachCallException('unavailable');

  @override
  Future<GameProgress> progress(String id) async => GameProgress.empty;

  @override
  Future<void> saveProgress(String id, GameProgress progress) async {}

  @override
  Stream<CoachStats> stats() => Stream.value(CoachStats.blank);

  @override
  Future<CoachConfig> config() async => CoachConfig.standard;

  @override
  Future<List<ModelGame>> modelGames(String eco) async => const [];
}

final class CloudCoachRepository implements CoachRepository {
  CloudCoachRepository(
    this._service,
    this._preferences, {
    required this._uids,
    required this._currentUid,
  });

  final CoachService _service;
  final PreferencesService _preferences;
  final Stream<String?> _uids;
  final String? Function() _currentUid;

  /// O progresso de cada partida no aparelho.
  static String progressKey(String uid, String id) =>
      'treinador.progresso.$uid.$id';

  /// Avisa as telas abertas quando o progresso local muda.
  final _progressChanged = StreamController<String>.broadcast();

  /// O fluxo de [byUid] da conta logada; troca quando a conta troca.
  Stream<T> _ofAccount<T>(Stream<T> Function(String uid) byUid, T noAccount) {
    late final StreamController<T> out;
    StreamSubscription<T>? inner;
    StreamSubscription<String?>? accounts;
    String? current;
    var firstOne = true;
    void follow(String? uid) {
      if (!firstOne && uid == current) return;
      firstOne = false;
      current = uid;
      unawaited(inner?.cancel());
      inner = null;
      if (uid == null) {
        out.add(noAccount);
        return;
      }
      inner = byUid(uid).listen(
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
  Stream<CoachAccount?> account() => _ofAccount(
    (uid) => _service.watchAccount(uid).map(CoachAccount.fromJson),
    null,
  );

  @override
  Future<void> linkAccount(Platform platform, String username) =>
      _link({'plataforma': platform.wire, 'usuario': username.trim()});

  @override
  Future<void> linkLichess(String token) =>
      _link({'plataforma': Platform.lichess.wire, 'token': token});

  Future<void> _link(Map<String, Object?> data) async {
    if (_currentUid() == null) {
      throw const LinkAccountException(LinkAccountFailure.noLogin);
    }
    try {
      await _service.call(CoachFunctions.linkAccount, data);
    } on CoachCallException catch (e) {
      throw LinkAccountException(switch (e.code) {
        'not-found' || 'invalid-argument' => LinkAccountFailure.doesNotExist,
        'failed-precondition' => LinkAccountFailure.lichessLogin,
        'resource-exhausted' => LinkAccountFailure.tooMany,
        'permission-denied' => LinkAccountFailure.noPlan,
        'unauthenticated' => LinkAccountFailure.noLogin,
        _ => LinkAccountFailure.noResponse,
      });
    }
  }

  @override
  Future<void> unlinkAccount() async {
    await _service.call(CoachFunctions.unlinkAccount, const {});
  }

  @override
  Future<void> setModelGamesNotice({required bool linked}) async {
    await _service.call(CoachFunctions.modelGamesNotice, {'ligado': linked});
  }

  @override
  Stream<List<CoachGame>> games() => _ofAccount(
    (uid) => _withLocalProgress(
      () => _service.watchGames(uid).asyncMap((docs) async {
        final list = <CoachGame>[
          for (final e in docs.entries)
            if (CoachGame.fromJson(e.key, e.value) case final p?)
              await _merge(uid, p),
        ];
        list.sort((a, b) => b.moveAt.compareTo(a.moveAt));
        return list;
      }),
    ),
    const [],
  );

  @override
  Stream<CoachGame?> game(String id) => _ofAccount(
    (uid) => _withLocalProgress(
      () => _service.watchGame(uid, id).asyncMap((doc) async {
        final p = doc == null ? null : CoachGame.fromJson(id, doc);
        return p == null ? null : await _merge(uid, p);
      }),
    ),
    null,
  );

  /// Reemite [source] quando o progresso local de qualquer partida muda.
  Stream<T> _withLocalProgress<T>(Stream<T> Function() source) {
    late final StreamController<T> out;
    StreamSubscription<T>? a;
    StreamSubscription<String>? b;
    out = StreamController<T>(
      onListen: () {
        a = source().listen(out.add, onError: out.addError);
        // O documento não muda quando só o aparelho grava: lê de novo a
        // última versão com o progresso novo.
        b = _progressChanged.stream.listen((_) {
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

  Future<CoachGame> _merge(String uid, CoachGame p) async {
    final local = await _local(uid, p.id);
    return local == null ? p : p.copyWith(progress: local);
  }

  Future<GameProgress?> _local(String uid, String id) async {
    final stored = await _preferences.getString(progressKey(uid, id));
    if (stored == null) return null;
    try {
      return GameProgress.fromJson(jsonDecode(stored));
    } on Object {
      return null;
    }
  }

  @override
  Future<void> analyze(String id, {bool notify = true}) async {
    await _service.call(CoachFunctions.analyze, {
      'partida': id,
      'avisar': notify,
    });
  }

  @override
  Future<GameProgress> progress(String id) async {
    final uid = _currentUid();
    if (uid == null) return GameProgress.empty;
    final local = await _local(uid, id);
    if (local != null) return local;
    try {
      final doc = await _service.watchGame(uid, id).first;
      final remote = doc?['progresso'];
      return remote == null
          ? GameProgress.empty
          : GameProgress.fromJson(remote);
    } on Object {
      return GameProgress.empty;
    }
  }

  @override
  Future<void> saveProgress(String id, GameProgress progress) async {
    final uid = _currentUid();
    if (uid == null) return;
    await _preferences.setString(
      progressKey(uid, id),
      jsonEncode(progress.toJson()),
    );
    if (!_progressChanged.isClosed) _progressChanged.add(id);
    // Sem rede, o Firestore guarda na fila; a tela não espera.
    unawaited(
      _service
          .writeProgress(uid, id, progress.toRemote())
          .catchError((Object e) => debugPrint('progresso sem gravar: $e')),
    );
  }

  @override
  Stream<CoachStats> stats() => _ofAccount(
    (uid) => _service.watchStats(uid).map(CoachStats.fromJson),
    CoachStats.blank,
  );

  @override
  Future<CoachConfig> config() async {
    try {
      return CoachConfig.fromJson(await _service.readConfig());
    } on Object {
      return CoachConfig.standard;
    }
  }

  @override
  Future<List<ModelGame>> modelGames(String eco) async {
    try {
      return ModelGame.listFromJson(await _service.readModelGames(eco));
    } on Object {
      return const [];
    }
  }
}
