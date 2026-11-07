import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/course_grant.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/firebase/course_grants_service.dart';
import '../../services/preferences_service.dart';

/// Os cursos dados ou comprados pelo servidor (`acessos/{uid}`, H-R5-61).
/// Acompanha a conta logada; sem rede vale a última cópia salva da conta.
abstract interface class CourseGrantsRepository {
  CourseGrants get current;

  Stream<CourseGrants> get changes;

  /// Começa a acompanhar a conta (idempotente).
  Future<void> start();

  /// Espera a primeira resposta do servidor depois de [start] (ou da troca
  /// de conta). Falso: não veio em [timeout] (sem rede).
  Future<bool> synced({Duration timeout});

  /// "Curso liberado" apareceu: grava `vistos.{courseId}` (H-R5-62).
  Future<void> markSeen(String courseId);
}

/// Sem Firebase: nada dado pelo servidor.
final class NoCourseGrantsRepository implements CourseGrantsRepository {
  const NoCourseGrantsRepository();

  @override
  CourseGrants get current => CourseGrants.empty;

  @override
  Stream<CourseGrants> get changes => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<bool> synced({Duration timeout = const Duration(seconds: 10)}) async =>
      false;

  @override
  Future<void> markSeen(String courseId) async {}
}

final class CloudCourseGrantsRepository implements CourseGrantsRepository {
  CloudCourseGrantsRepository(
    this._service,
    this._preferences, {
    required this._uids,
    required this._currentUid,
    required this._now,
  });

  final CourseGrantsService _service;
  final PreferencesService _preferences;
  final Stream<String?> _uids;
  final String? Function() _currentUid;
  final Now _now;

  /// A cópia de cada conta: `acessos.<uid>` (JSON de [CourseGrants]).
  static String cacheKey(String uid) => 'acessos.$uid';

  final _changes = StreamController<CourseGrants>.broadcast();
  CourseGrants _current = CourseGrants.empty;
  String? _uid;
  StreamSubscription<String?>? _accounts;
  StreamSubscription<Map<String, Object?>?>? _remote;
  Completer<void> _firstRemote = Completer<void>();
  Future<void>? _started;

  @override
  CourseGrants get current => _current;

  @override
  Stream<CourseGrants> get changes => _changes.stream;

  @override
  Future<void> start() => _started ??= () async {
    await _follow(_currentUid());
    _accounts = _uids.listen((uid) => unawaited(_follow(uid)));
  }();

  @override
  Future<bool> synced({Duration timeout = const Duration(seconds: 10)}) async {
    await start();
    if (_uid == null) return true;
    try {
      await _firstRemote.future.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _follow(String? uid) async {
    if (uid == _uid && _started != null && _remote != null) return;
    await _remote?.cancel();
    _remote = null;
    _uid = uid;
    _firstRemote = Completer<void>();
    if (uid == null) {
      _emit(CourseGrants.empty);
      return;
    }
    _emit(await _cached(uid));
    if (_uid != uid) return;
    _remote = _service
        .watch(uid)
        .listen(
          (data) => unawaited(_onRemote(uid, CourseGrants.fromJson(data))),
          // Sem permissão ou sem rede: fica a cópia.
          onError: (Object error) => debugPrint('acessos sem ler: $error'),
        );
  }

  Future<void> _onRemote(String uid, CourseGrants grants) async {
    if (_uid != uid) return;
    // A tela pode ter marcado "visto" antes do servidor confirmar.
    final local = _current.seen;
    final merged = CourseGrants(
      courses: grants.courses,
      seen: {
        ...grants.seen,
        for (final e in local.entries)
          if (!grants.seen.containsKey(e.key) ||
              grants.seen[e.key]!.isBefore(e.value))
            e.key: e.value,
      },
      blocked: grants.blocked,
      blockedUntil: grants.blockedUntil,
    );
    _emit(merged);
    await _preferences.setString(cacheKey(uid), jsonEncode(merged.toJson()));
    if (!_firstRemote.isCompleted) _firstRemote.complete();
  }

  Future<CourseGrants> _cached(String uid) async {
    final stored = await _preferences.getString(cacheKey(uid));
    if (stored == null) return CourseGrants.empty;
    try {
      return CourseGrants.fromJson(
        (jsonDecode(stored) as Map).cast<String, Object?>(),
      );
    } on Object {
      return CourseGrants.empty;
    }
  }

  void _emit(CourseGrants next) {
    if (next == _current) return;
    _current = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  @override
  Future<void> markSeen(String courseId) async {
    final uid = _uid;
    if (uid == null || !_current.courses.containsKey(courseId)) return;
    final at = _now();
    _emit(_current.markSeen(courseId, at));
    await _preferences.setString(cacheKey(uid), jsonEncode(_current.toJson()));
    // Sem rede, o Firestore guarda na fila; a tela não espera.
    unawaited(
      _service
          .markSeen(uid, courseId, at)
          .catchError((Object e) => debugPrint('vistos sem gravar: $e')),
    );
  }

  @visibleForTesting
  Future<void> dispose() async {
    await _accounts?.cancel();
    await _remote?.cancel();
    await _changes.close();
  }
}
