import 'dart:convert';

import '../../../domain/models/learning_record.dart';
import '../../../domain/models/learning_unit_completion.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/preferences_service.dart';

/// Account-scoped operational progress, independent of Analytics consent.
/// Guest history is never copied into an account. All read/modify/write work,
/// including restoration, shares this queue in the app's singleton instance.
class LearningRepository {
  LearningRepository(
    this._preferences,
    this._now, {
    required this.currentUid,
    required this.versionOf,
    this.onChanged,
    this.onUnitCompleted,
  });
  final PreferencesService _preferences;
  final Now _now;
  final String? Function() currentUid;
  final Future<String?> Function(bool endgame, String id) versionOf;
  final void Function()? onChanged;
  final Future<void> Function(LearningUnitCompletion)? onUnitCompleted;

  /// Awaited by explicit completion commands. Guest-local training can observe
  /// activity without creating or importing nominal account records.
  Future<void> notifyUnitCompleted({
    required String? owner,
    required String kind,
    required String unitId,
    bool testPassed = false,
  }) async {
    if (owner != currentUid()) return;
    await onUnitCompleted?.call(
      LearningUnitCompletion(
        kind: kind,
        unitId: unitId,
        at: _now(),
        testPassed: testPassed,
      ),
    );
  }

  Future<void> _pending = Future.value();

  Future<T> serial<T>(Future<T> Function() action) {
    final next = _pending.then((_) => action());
    _pending = next.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return next;
  }

  String _key(String uid) => 'learning.v1.${Uri.encodeComponent(uid)}';
  Future<List<LearningRecord>> load(String uid) async {
    final json = await _preferences.getString(_key(uid));
    if (json == null) return [];
    try {
      return LearningRecord.parse(jsonDecode(json));
    } on FormatException {
      return [];
    }
  }

  Future<void> restore(String uid, List<LearningRecord> records) =>
      serial(() async {
        await _save(uid, LearningRecord.merge(await load(uid), records));
      });
  Future<void> _save(String uid, List<LearningRecord> records) =>
      _preferences.setString(
        _key(uid),
        jsonEncode(records.map((r) => r.toJson()).toList()),
      );

  /// Caller serializes the surrounding progress command with [serial].
  /// Null owner/version means no nominal record; an account switch invalidates
  /// the session rather than reassigning its work to the next account.
  Future<void> observe({
    required String? owner,
    required String? version,
    required String kind,
    required String unitId,
    bool started = false,
    bool completed = false,
    bool passed = false,
    Map<String, int> exerciseStars = const {},
  }) async {
    if (owner == null || owner != currentUid() || version == null) return;
    if (passed &&
        !(await load(owner)).any(
          (r) =>
              r.kind == kind &&
              r.unitId == unitId &&
              r.version == version &&
              r.firstStartedAt != null,
        )) {
      return;
    }
    final at = _now().toUtc();
    final record = LearningRecord(
      kind: kind,
      unitId: unitId,
      version: version,
      firstStartedAt: started ? at : null,
      contentCompletedAt: completed ? at : null,
      testPassedAt: passed ? at : null,
      lastActivityAt: at,
      exerciseStars: exerciseStars,
    );
    await _save(owner, LearningRecord.merge(await load(owner), [record]));
    onChanged?.call();
  }
}
