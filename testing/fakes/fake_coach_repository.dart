import 'dart:async';

import 'package:lucena/data/repositories/coach/coach_repository.dart';
import 'package:lucena/data/services/firebase/coach_service.dart';
import 'package:lucena/domain/models/coach/coach.dart';

import '../coach_fixtures.dart';

/// O Treinador em memória, para telas, view models e Patrol.
///
/// - [linkFailure]: o próximo [linkAccount] falha com esse motivo;
/// - [analyzeCompletes]: [analyze] leva a partida a `pronta` (com os
///   exercícios de [CoachFixtures.tiagoJson]) logo depois de `analisando`;
/// - [analyzeFailure]: [analyze] lança [CoachCallException].
class FakeCoachRepository implements CoachRepository {
  FakeCoachRepository({
    this._account,
    List<CoachGame>? games,
    CoachStats? stats,
    this.currentConfig = CoachConfig.standard,
    Map<String, List<ModelGame>>? modelGamesByEco,
  }) : _games = [...?games],
       _stats = stats ?? CoachStats.blank,
       modelGamesByEco = modelGamesByEco ?? {};

  /// Conta ligada, as cinco partidas do canvas e as estatísticas.
  factory FakeCoachRepository.withData() => FakeCoachRepository(
    account: CoachFixtures.account,
    games: CoachFixtures.list(),
    stats: CoachFixtures.stats(),
  );

  CoachAccount? _account;
  List<CoachGame> _games;
  CoachStats _stats;
  CoachConfig currentConfig;
  final Map<String, List<ModelGame>> modelGamesByEco;
  final _progresses = <String, GameProgress>{};

  LinkAccountFailure? linkFailure;
  String? analyzeFailure;

  /// O `details.motivo` da falha de [analyze] (`cota`, `teto`).
  String? analyzeReason;
  bool analyzeCompletes = false;

  final links = <(Platform, String)>[];
  final analysisRequests = <(String, bool)>[];
  final modelGamesNotices = <bool>[];

  final _changed = StreamController<void>.broadcast();

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changed.stream.map((_) => read());
  }

  void _notify() => _changed.add(null);

  CoachGame _withProgress(CoachGame p) {
    final local = _progresses[p.id];
    return local == null ? p : p.copyWith(progress: local);
  }

  // Controles do teste.

  set currentAccount(CoachAccount? value) {
    _account = value;
    _notify();
  }

  set currentGames(List<CoachGame> value) {
    _games = [...value];
    _notify();
  }

  set currentStats(CoachStats value) {
    _stats = value;
    _notify();
  }

  /// O servidor troca (ou junta) uma partida.
  void perGame(CoachGame p) {
    _games = [
      for (final e in _games)
        if (e.id != p.id) e,
      p,
    ]..sort((a, b) => b.moveAt.compareTo(a.moveAt));
    _notify();
  }

  // TreinadorRepository.

  @override
  Stream<CoachAccount?> account() => _watch(() => _account);

  @override
  Future<void> linkAccount(Platform platform, String username) async {
    links.add((platform, username));
    if (linkFailure case final failure?) {
      linkFailure = null;
      throw LinkAccountException(failure);
    }
    currentAccount = CoachAccount(
      platform: platform,
      username: username.trim(),
    );
  }

  @override
  Future<void> unlinkAccount() async => currentAccount = null;

  @override
  Future<void> setModelGamesNotice({required bool linked}) async {
    modelGamesNotices.add(linked);
    if (_account case final c?) {
      currentAccount = CoachAccount(
        platform: c.platform,
        username: c.username,
        linkedAt: c.linkedAt,
        lastFetch: c.lastFetch,
        modelGamesNotice: linked,
      );
    }
  }

  @override
  Stream<List<CoachGame>> games() =>
      _watch(() => [for (final p in _games) _withProgress(p)]);

  @override
  Stream<CoachGame?> game(String id) => _watch(() {
    for (final p in _games) {
      if (p.id == id) return _withProgress(p);
    }
    return null;
  });

  @override
  Future<void> analyze(String id, {bool notify = true}) async {
    analysisRequests.add((id, notify));
    if (analyzeFailure case final code?) {
      throw CoachCallException(code, reason: analyzeReason);
    }
    final current = _games.where((p) => p.id == id).firstOrNull;
    if (current == null) throw const CoachCallException('not-found');
    perGame(current.copyWith(status: GameStatus.analyzing));
    if (analyzeCompletes) {
      final json = {
        ...current.toJson(),
        ...CoachFixtures.tiagoJson(),
        'jogadaEm': current.moveAt.toIso8601String(),
        'adversario': current.opponent.toJson(),
        'cor': current.color.wire,
        'resultado': current.result.wire,
      };
      perGame(CoachGame.fromJson(id, json)!);
    }
  }

  @override
  Future<GameProgress> progress(String id) async =>
      _progresses[id] ??
      _games.where((p) => p.id == id).firstOrNull?.progress ??
      GameProgress.empty;

  @override
  Future<void> saveProgress(String id, GameProgress progress) async {
    _progresses[id] = progress;
    _notify();
  }

  @override
  Stream<CoachStats> stats() => _watch(() => _stats);

  @override
  Future<CoachConfig> config() async => currentConfig;

  @override
  Future<List<ModelGame>> modelGames(String eco) async =>
      modelGamesByEco[eco] ?? const [];
}

/// O serviço em memória, para testar o [CloudCoachRepository].
class FakeCoachService implements CoachService {
  final accounts = <String, Map<String, Object?>>{};
  final games = <String, Map<String, Map<String, Object?>>>{};
  final stats = <String, Map<String, Object?>>{};
  Map<String, Object?>? configDoc;
  final modelGamesDocs = <String, Map<String, Object?>>{};

  final calls = <(String, Map<String, Object?>)>[];
  final savedProgresses = <(String, String, Map<String, Object?>)>[];

  /// Código do `HttpsError` da próxima chamada (nulo: responde bem).
  String? callError;

  final _changed = StreamController<void>.broadcast();

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changed.stream.map((_) => read());
  }

  /// O servidor gravou algo: chega a quem escuta.
  void notify() => _changed.add(null);

  @override
  Stream<Map<String, Object?>?> watchAccount(String uid) =>
      _watch(() => accounts[uid]);

  @override
  Stream<Map<String, Map<String, Object?>>> watchGames(
    String uid, {
    int limit = 200,
  }) => _watch(() => {...?games[uid]});

  @override
  Stream<Map<String, Object?>?> watchGame(String uid, String id) =>
      _watch(() => games[uid]?[id]);

  @override
  Stream<Map<String, Object?>?> watchStats(String uid) =>
      _watch(() => stats[uid]);

  @override
  Future<Map<String, Object?>?> readConfig() async => configDoc;

  @override
  Future<Map<String, Object?>?> readModelGames(String eco) async =>
      modelGamesDocs[eco];

  @override
  Future<void> writeProgress(
    String uid,
    String id,
    Map<String, Object?> progress,
  ) async {
    savedProgresses.add((uid, id, progress));
    final doc = games[uid]?[id];
    if (doc != null) games[uid]![id] = {...doc, 'progresso': progress};
  }

  @override
  Future<Object?> call(String name, Map<String, Object?> data) async {
    calls.add((name, data));
    if (callError case final code?) {
      callError = null;
      throw CoachCallException(code);
    }
    return null;
  }
}
