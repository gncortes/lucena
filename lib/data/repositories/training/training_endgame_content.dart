import 'dart:convert';

import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/lesson_content.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../services/asset_service.dart';
import '../../services/scoped_asset_cache.dart';
import '../endgames/endgame_lesson_repository.dart';
import '../endgames/endgame_lesson_repository_asset.dart';
import '../school/lesson_repository.dart';
import '../school/lesson_repository_asset.dart';

/// Separate private sources. Construct only in development/E2E/QA compositions;
/// this registry never widens the public repository or its release whitelist.
final class TrainingEndgameContent {
  TrainingEndgameContent(
    AssetService assets, {
    required LessonRepository school,
    required Map<String, String> indexes,
  }) : _sources = {
         for (final entry in indexes.entries)
           entry.key: _TrainingEndgameRepository(
             assets,
             school: school,
             namespace: entry.key,
             index: entry.value,
           ),
       };

  factory TrainingEndgameContent.fromConfigs(
    AssetService assets, {
    required LessonRepository school,
    required Iterable<TrainingCourseConfig> configs,
  }) => TrainingEndgameContent(
    assets,
    school: school,
    indexes: {
      for (final config in configs)
        if (config.indexSource.startsWith('assets/courses/'))
          config.indexSource.split('/')[2]: config.indexSource,
    },
  );

  final Map<String, _TrainingEndgameRepository> _sources;

  EndgameLessonRepository? forId(String? id) => _sources.entries
      .where((entry) => id?.startsWith('${entry.key}.') ?? false)
      .map((entry) => entry.value)
      .firstOrNull;

  EndgameLessonRepository? forIndex(String index) =>
      _sources.values.where((source) => source.index == index).firstOrNull;
}

final class _TrainingEndgameRepository implements EndgameLessonRepository {
  _TrainingEndgameRepository(
    this.assets, {
    required this.school,
    required this.namespace,
    required this.index,
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(namespace)) {
      throw ArgumentError.value(namespace, 'namespace');
    }
  }

  final AssetService assets;
  final LessonRepository school;
  final String namespace, index;
  late final _cache = ScopedAssetCache(assets);

  Future<Map<String, dynamic>> _index() => _cache.load(
    'index',
    () async =>
        jsonDecode(await assets.loadString(index)) as Map<String, dynamic>,
  );

  @override
  Future<EndgameTrail> trail() => _cache.load('trail', _trail);

  Future<EndgameTrail> _trail() async {
    final json = await _index();
    final modules = <EndgameModule>[];
    for (final part in json['partes'] as List) {
      final lessons = <EndgameLesson>[];
      for (final chapter in (part as Map)['capitulos'] as List) {
        final id = (chapter as Map)['id'] as String;
        if (!id.startsWith('$namespace.') ||
            !RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(id)) {
          throw const FormatException('Invalid private chapter identifier');
        }
        final Map<String, dynamic> data;
        try {
          data = jsonDecode(
            await assets.loadString(
              AssetEndgameLessonRepository.lessonPath(id),
            ),
          ) as Map<String, dynamic>;
        } on LessonContentNotFound {
          continue;
        }
        if (data['id'] != id) {
          throw const FormatException('Private chapter identifier mismatch');
        }
        for (final lessonPart in (data['parts'] as List? ?? const [])) {
          final map = lessonPart as Map;
          final script = map['roteiro'];
          if (script is! String) continue;
          try {
            await assets.loadString(script);
          } on LessonContentNotFound {
            map.remove('roteiro');
          }
        }
        // Private access is not approval for publication or an automatic A.
        lessons.add(
          AssetEndgameLessonRepository.parseLesson(data, inReview: true),
        );
      }
      modules.add(EndgameModule(id: part['id'] as String, lessons: lessons));
    }
    return EndgameTrail(modules: modules);
  }

  @override
  Future<LessonTexts> texts(String language) =>
      _cache.load(('texts', language), () async {
        final common = await school.texts(language);
        final english = await _texts('en');
        if (language == 'en' ||
            !AssetLessonRepository.languages.contains(language)) {
          return english.over(common);
        }
        return (await _texts(language)).over(english).over(common);
      });

  Future<LessonTexts> _texts(String language) =>
      _cache.load(('rawTexts', language), () async {
        final all = <String, dynamic>{};
        final titles = <String, String>{
          if (language == 'pt')
            for (final part in (await _index())['partes'] as List)
              for (final chapter in (part as Map)['capitulos'] as List)
                if ((chapter as Map)['titulo'] is String)
                  chapter['id'] as String: chapter['titulo'] as String,
        };
        for (final lesson in (await trail()).lessons) {
          try {
            final json = jsonDecode(
              await assets.loadString(
                AssetEndgameLessonRepository.textsPath(language, lesson.id),
              ),
            ) as Map<String, dynamic>;
            all.addAll(AssetEndgameLessonRepository.prefixed(lesson.id, json));
          } on LessonContentNotFound {
            if (language == 'en') rethrow;
          }
          final title = titles[lesson.id];
          if (title != null) {
            all.putIfAbsent('${lesson.id}.title', () => title);
          }
        }
        return LessonTexts.fromJson(all);
      });
}
