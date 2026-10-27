import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/linked_lesson.dart';
import '../../../domain/models/learning_record.dart';
import '../analytics/analytics_repository.dart';
import '../campaign/campaign_repository.dart';
import '../school/lesson_source.dart';
import 'learning_repository.dart';

/// Only explicit lesson commands observe activity. Loading congratulations or
/// restoring a progress repository never enters here. The owner is bound when
/// the lesson session is constructed, including a null (guest) owner.
class LearningLessonSource implements LessonSource {
  LearningLessonSource(
    this.inner, {
    this.learning,
    this.analytics = const NoAnalyticsRepository(),
    this.campaigns,
  }) : _owner = learning?.currentUid();
  final LessonSource inner;
  final LearningRepository? learning;
  final AnalyticsRepository analytics;
  final CampaignRepository? campaigns;
  final String? _owner;
  final Map<String, String?> _versions = {};
  Future<void> _pending = Future.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final repository = learning;
    if (repository != null) return repository.serial(action);
    final next = _pending.then((_) => action());
    _pending = next.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return next;
  }

  Future<String?> _version(String id) async {
    if (_versions.containsKey(id)) return _versions[id];
    return _versions[id] = await learning?.versionOf(endgame, id);
  }

  String get _kind => endgame ? 'endgame_chapter' : 'school_lesson';
  Future<LearningRecord?> _record(String id, {String? part}) async {
    final owner = _owner;
    final repository = learning;
    if (owner == null ||
        repository == null ||
        owner != repository.currentUid()) {
      return null;
    }
    final version = await _version(id);
    final kind = part == null ? _kind : 'endgame_lesson';
    final unit = part == null ? id : '$id/$part';
    return (await repository.load(owner))
        .where(
          (r) => r.kind == kind && r.unitId == unit && r.version == version,
        )
        .firstOrNull;
  }

  Future<bool> _newRevision(String id) async {
    final repository = learning;
    final owner = _owner;
    if (repository == null ||
        owner == null ||
        owner != repository.currentUid()) {
      return false;
    }
    final version = await _version(id);
    if (version == null) return false;
    return (await repository.load(owner)).any(
      (r) =>
          r.kind == _kind &&
          r.unitId == id &&
          r.version != version &&
          r.firstStartedAt != null,
    );
  }

  Future<void> _observe(
    String id, {
    String? part,
    bool started = false,
    bool completed = false,
  }) async {
    // A completion without an observed start belongs to legacy/other-account
    // progress. Keep its actual activity, but do not mint a nominal completion.
    if (completed && (await _record(id, part: part))?.firstStartedAt == null) {
      return;
    }
    await learning?.observe(
      owner: _owner,
      version: await _version(id),
      kind: part == null ? _kind : 'endgame_lesson',
      unitId: part == null ? id : '$id/$part',
      started: started,
      completed: completed,
    );
  }

  @override
  bool get endgame => inner.endgame;
  @override
  Future<Lesson?> lesson(String id) async {
    await _version(id);
    return inner.lesson(id);
  }

  @override
  Future<LessonTexts> texts(String language) => inner.texts(language);
  @override
  Future<List<Reference>> references(String id) => inner.references(id);
  @override
  Future<(int, int)> placeOf(String id) => inner.placeOf(id);
  @override
  Future<bool> untouched(String id) => inner.untouched(id);
  @override
  Future<LessonCheckpoint?> checkpoint() => inner.checkpoint();
  @override
  Future<void> clearCheckpoint() => _serial(inner.clearCheckpoint);
  @override
  Future<void> leave() => _serial(inner.leave);
  @override
  Future<void> saveCheckpoint(LessonCheckpoint checkpoint) => _serial(() async {
    final first =
        await inner.untouched(checkpoint.lessonId) ||
        await _newRevision(checkpoint.lessonId);
    await inner.saveCheckpoint(checkpoint);
    await _observe(checkpoint.lessonId, started: first);
    if (endgame && checkpoint.part != null) {
      // Legacy chapter progress cannot establish a new start for its parts.
      final known =
          (await _record(checkpoint.lessonId))?.firstStartedAt != null;
      await _observe(
        checkpoint.lessonId,
        part: checkpoint.part,
        started: known,
      );
    }
  });
  @override
  Future<LessonOutcome> complete(String id) => _complete(id, null);
  @override
  Future<LessonOutcome> completePart(String id, String partId) =>
      _complete(id, partId);

  Future<LessonOutcome> _complete(String id, String? part) => _serial(() async {
    final before = await inner.completion(id, part: part);
    final chapterRecord = await _record(id);
    final partRecord = part == null ? null : await _record(id, part: part);
    final result = part == null
        ? await inner.complete(id)
        : await inner.completePart(id, part);
    final after = await inner.completion(id, part: part);
    await _observe(id);
    if (endgame && part != null) await _observe(id, part: part);
    if (endgame &&
        part != null &&
        after.part &&
        (!before.part ||
            (partRecord?.firstStartedAt != null &&
                partRecord?.contentCompletedAt == null))) {
      await _observe(id, part: part, completed: true);
    }
    var versionCompleted =
        chapterRecord?.firstStartedAt != null &&
        chapterRecord?.contentCompletedAt == null;
    if (endgame && versionCompleted) {
      final chapter = await inner.lesson(id);
      for (final section in chapter?.parts ?? <LessonPart>[]) {
        if ((await _record(id, part: section.id))?.contentCompletedAt == null) {
          versionCompleted = false;
        }
      }
    }
    if (after.lesson &&
        chapterRecord?.contentCompletedAt == null &&
        (chapterRecord?.firstStartedAt != null
            ? versionCompleted
            : !before.lesson)) {
      await _observe(id, completed: true);
      await analytics.log(
        AnalyticsEvents.aulaConcluida(
          aulaId: id,
          tipoAula: endgame ? 'finais' : 'escola',
        ),
      );
      final campaign = await campaigns?.active();
      final target = LinkedLesson(
        endgame ? LinkedLessonKind.endgame : LinkedLessonKind.school,
        id,
      );
      if (campaign != null && campaign.lesson == target) {
        await campaigns!.clear();
        await analytics.log(AnalyticsEvents.campanhaAulaConcluida(campaign));
      }
    }
    return result;
  });
  @override
  Future<({bool lesson, bool part})> completion(String id, {String? part}) =>
      inner.completion(id, part: part);
}
