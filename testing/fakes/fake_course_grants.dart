import 'dart:async';

import 'package:lucena/data/repositories/lesson_ad/course_grants_repository.dart';
import 'package:lucena/data/services/firebase/course_grants_service.dart';
import 'package:lucena/domain/models/course_grant.dart';

/// `acessos/{uid}` em memória. [online] falso: o [watch] não responde e o
/// [markSeen] falha (sem rede). [deny] simula a regra que recusa ler.
class FakeCourseGrantsService implements CourseGrantsService {
  final docs = <String, Map<String, Object?>>{};
  final _controllers = <String, StreamController<Map<String, Object?>?>>{};
  final seenWrites = <(String, String, DateTime)>[];
  bool online = true;
  bool deny = false;

  @override
  Stream<Map<String, Object?>?> watch(String uid) {
    final controller = StreamController<Map<String, Object?>?>(
      onListen: () {
        if (deny) {
          _controllers[uid]?.addError(StateError('permission-denied'));
        } else if (online) {
          _controllers[uid]?.add(docs[uid]);
        }
      },
    );
    _controllers[uid] = controller;
    return controller.stream;
  }

  /// A Function (ou o admin) muda o documento; chega a quem escuta.
  void put(String uid, Map<String, Object?>? doc) {
    if (doc == null) {
      docs.remove(uid);
    } else {
      docs[uid] = doc;
    }
    if (online) _controllers[uid]?.add(doc);
  }

  /// A rede voltou: o que mudou chega.
  void reconnect(String uid) {
    online = true;
    _controllers[uid]?.add(docs[uid]);
  }

  @override
  Future<void> markSeen(String uid, String courseId, DateTime at) async {
    if (!online) throw StateError('unavailable');
    final doc = docs[uid];
    if (doc == null) throw StateError('not-found');
    seenWrites.add((uid, courseId, at));
    final seen = {...?(doc['vistos'] as Map?)?.cast<String, Object?>()};
    seen[courseId] = at;
    docs[uid] = {...doc, 'vistos': seen};
  }
}

/// O repositório já pronto, para telas e view models.
class FakeCourseGrantsRepository implements CourseGrantsRepository {
  FakeCourseGrantsRepository([this._current = CourseGrants.empty]);

  CourseGrants _current;
  final _changes = StreamController<CourseGrants>.broadcast();
  final seen = <String>[];
  bool isSynced = true;

  @override
  CourseGrants get current => _current;

  set current(CourseGrants next) {
    _current = next;
    _changes.add(next);
  }

  @override
  Stream<CourseGrants> get changes => _changes.stream;

  @override
  Future<void> start() async {}

  @override
  Future<bool> synced({Duration timeout = const Duration(seconds: 10)}) async =>
      isSynced;

  @override
  Future<void> markSeen(String courseId) async {
    seen.add(courseId);
    _current = _current.markSeen(courseId, DateTime(2026));
  }
}
