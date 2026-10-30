import 'dart:convert';
import 'dart:async';

import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/training/opening_parts.dart';
import '../../services/lesson_content_service.dart';
import '../../services/lesson_package_service.dart';
import '../../services/lesson_package_index.dart';

/// Adapts the currently published JSON index without inventing a backend pack.
/// Published readers verify every source file against their release manifest.
class CourseDownloadRepository {
  const CourseDownloadRepository(
    this.packages, {
    this.openingProfile,
    this.indexSource,
  });
  const CourseDownloadRepository.unconfigured()
    : packages = null,
      openingProfile = null,
      indexSource = null;
  final LessonPackageService? packages;
  final Future<String> Function()? openingProfile;
  final LessonPackageIndexSource? indexSource;
  Future<String> _profile() async => await openingProfile?.call() ?? 'solido';

  String _key(TrainingCourseConfig config, String? chapterId, String profile) =>
      '${config.course.name}:${config.course == TrainingCourse.escola ? 'entry' : '${chapterId ?? 'entry'}:$profile'}';

  Future<bool> isDownloaded(
    TrainingCourseConfig config, {
    String? chapterId,
  }) async {
    final service = packages;
    if (service == null) return false;
    final profile = await _profile();
    if (await service.installed(_key(config, chapterId, profile))) return true;
    return chapterId != null &&
        await service.contains(
          _key(config, null, profile),
          'assets/lessons/endgames/$chapterId.json',
        );
  }

  Future<void> prepare(TrainingCourseConfig config, {String? chapterId}) async {
    final service = packages;
    if (service == null) throw const LessonContentUnavailable();
    if (await isDownloaded(config, chapterId: chapterId)) {
      unawaited(
        refresh(config, chapterId: chapterId).catchError((Object _) {}),
      );
      return;
    }
    final profile = await _profile();
    final key = _key(config, chapterId, profile);
    final selection = await _selection(service.source, key);
    Future<Map<String, String>> files() =>
        _files(config, chapterId, profile, selection.source);
    if (selection.source != service.source) {
      await service.refresh(
        key,
        files,
        candidateSource: selection.source,
        descriptor: selection.descriptor,
      );
      return;
    }
    await service.install(key, files, descriptor: selection.descriptor);
  }

  /// Call close() on the returned lease after leaving a lesson/exercise/test.
  /// One account-wide lease conservatively protects shared indexes/dictionaries.
  LessonPackageLease? beginSession() => packages?.beginSession();

  /// A server index can select another immutable, published release.
  /// Failures do not alter installed content; prepare() runs this silently.
  Future<void> refresh(
    TrainingCourseConfig config, {
    String? chapterId,
    LessonContentReader? candidateSource,
  }) async {
    final service = packages;
    if (service == null) throw const LessonContentUnavailable();
    final profile = await _profile();
    final key = _key(config, chapterId, profile);
    final selection = await _selection(candidateSource ?? service.source, key);
    final selected = selection.source;
    if (service.source is PublishedLessonContentReader &&
        selected is! PublishedLessonContentReader) {
      throw const LessonContentUnavailable();
    }
    if (selected is PublishedLessonContentReader) {
      if (selected.currentUser() != service.identity()) {
        throw const LessonContentUnavailable();
      }
      await selected.refreshManifest();
    }
    await service.refresh(
      key,
      () => _files(config, chapterId, profile, selected),
      candidateSource: selected,
      descriptor: selection.descriptor,
    );
  }

  Future<({LessonContentReader source, LessonPackageDescriptor? descriptor})>
  _selection(LessonContentReader source, String key) async {
    final index = await indexSource?.fetch();
    if (index == null) return (source: source, descriptor: null);
    if (source is! PublishedLessonContentReader) {
      throw const LessonContentUnavailable();
    }
    return (
      source: source.release == index.release
          ? source
          : source.forRelease(index.release),
      descriptor: index.packages[key] ?? (throw const LessonContentNotFound()),
    );
  }

  Future<Map<String, String>> _files(
    TrainingCourseConfig config,
    String? chapterId,
    String profile,
    LessonContentReader reader,
  ) async {
    final files = <String, String>{};
    Future<void> add(
      String path, {
      bool optional = false,
      bool followReferences = true,
    }) async {
      if (files.containsKey(path)) return;
      final String text;
      try {
        text = await reader.read(path);
      } on LessonContentNotFound {
        if (optional) return;
        rethrow;
      }
      files[path] = text;
      // Script paths are explicit in both school lessons and chapter files.
      final refs = <String>{};
      void visit(Object? value) {
        if (value is String && isLessonContentPath(value)) refs.add(value);
        if (value is List) value.forEach(visit);
        if (value is Map) value.values.forEach(visit);
      }

      if (followReferences) visit(jsonDecode(text));
      for (final ref in refs) {
        await add(ref);
      }
    }

    await add(
      config.indexSource,
      followReferences: config.course == TrainingCourse.escola,
    );
    // Private chapter texts reuse the school's common feedback dictionary.
    await add('assets/lessons/en/lessons.json');
    await add('assets/lessons/pt/lessons.json', optional: true);
    if (config.course == TrainingCourse.escola) {
      return files;
    }
    final index = jsonDecode(files[config.indexSource]!) as Map;
    final chapters = [
      for (final part in (index['partes'] as List))
        for (final chapter in ((part as Map)['capitulos'] as List))
          if ((chapter as Map)['publicado'] != false &&
              chapter['status'] != 'draft')
            chapter,
    ];
    final chapter = chapterId == null
        ? chapters.firstOrNull
        : chapters.where((c) => c['id'] == chapterId).firstOrNull;
    if (chapter == null) throw const LessonContentNotFound();
    final id = chapter['id'] as String;
    await add('assets/lessons/endgames/$id.json');
    await add('assets/lessons/en/endgames/$id.json');
    await add('assets/lessons/pt/endgames/$id.json', optional: true);
    for (final lesson in (chapter['aulas'] as List).cast<Map>()) {
      if (lesson['tipo'] != 'tema') continue;
      final lessonId = lesson['id'];
      await add('assets/lessons/treino/$lessonId.json');
      await add('assets/lessons/treino/pt/$lessonId.json', optional: true);
    }
    // Opening packs do not depend on chapter selection. Profile metadata in
    // the course index selects the repertoire as one unit.
    for (final c in chapters) {
      for (final lesson in (c['aulas'] as List).cast<Map>()) {
        if (lesson['tipo'] == 'abertura' &&
            (lesson['perfil'] ??
                    openingProfileForLesson(lesson['id'] as String) ??
                    profile) ==
                profile) {
          await add('assets/lessons/treino/aberturas/${lesson['id']}.json');
        }
      }
    }
    return files;
  }
}
