import 'dart:convert';

import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/lesson_content.dart';
import '../../services/asset_service.dart';
import '../../services/scoped_asset_cache.dart';
import '../school/lesson_repository.dart';
import '../school/lesson_repository_asset.dart';
import 'endgame_lesson_repository.dart';

/// As aulas em `assets/lessons/endgames/` (índice e uma aula por arquivo,
/// gerados por `build_aula.py`) e as falas em
/// `assets/lessons/<idioma>/endgames/<aula>.json`.
class AssetEndgameLessonRepository implements EndgameLessonRepository {
  /// [school] dá as falas comuns (`coach.*`), por baixo das das aulas.
  AssetEndgameLessonRepository(this._assets, {required this.school});

  static const indexPath = 'assets/lessons/endgames/index.json';

  /// As aulas ainda em revisão (abaixo da nota A), à parte do índice porque
  /// o `build_aula.py` regrava o índice.
  static const reviewPath = 'assets/lessons/endgames/review.json';
  static String lessonPath(String id) => 'assets/lessons/endgames/$id.json';
  static String textsPath(String language, String id) =>
      'assets/lessons/$language/endgames/$id.json';

  final AssetService _assets;
  final LessonRepository school;
  late final _cache = ScopedAssetCache(_assets);

  @override
  Future<EndgameTrail> trail() => _cache.load(indexPath, _loadTrail);

  @override
  Future<LessonTexts> texts(String language) =>
      _cache.load(('texts', language), () => _mergedTexts(language));

  Future<LessonTexts> _mergedTexts(String language) async {
    final common = await school.texts(language);
    final english = await _load('en');
    if (language == 'en' ||
        !AssetLessonRepository.languages.contains(language)) {
      return english.over(common);
    }
    return (await _load(language)).over(english).over(common);
  }

  Future<EndgameTrail> _loadTrail() async {
    final index =
        jsonDecode(await _assets.loadString(indexPath)) as Map<String, dynamic>;
    final review = await _review();
    final failed = await _review('failed');
    final modules = <EndgameModule>[];
    for (final module
        in (index['modules'] as List? ?? const [])
            .cast<Map<String, dynamic>>()) {
      final lessons = <EndgameLesson>[];
      for (final id in (module['lessons'] as List).cast<String>()) {
        final json = jsonDecode(
          await _assets.loadString(lessonPath(id)),
        ) as Map<String, dynamic>;
        await _dropMissingScripts(json);
        lessons.add(
          parseLesson(
            json,
            inReview: review.contains(id),
            failed: failed.contains(id),
          ),
        );
      }
      modules.add(EndgameModule(id: module['id'] as String, lessons: lessons));
    }
    return EndgameTrail(modules: modules);
  }

  /// Tira de [lesson] o `roteiro` das partes cujo arquivo ainda não existe
  /// (T76: a estrutura liga todos os capítulos, e os roteiros chegam um a um).
  /// A parte sem roteiro fica escondida por `VisibleLessons.partVisible`.
  Future<void> _dropMissingScripts(Map<String, dynamic> lesson) async {
    for (final part
        in (lesson['parts'] as List? ?? const [])
            .cast<Map<String, dynamic>>()) {
      final path = part['roteiro'];
      if (path is! String) continue;
      try {
        await _assets.loadString(path);
      } on LessonContentNotFound {
        part.remove('roteiro');
      } on LessonContentUnavailable {
        rethrow;
      } on Object {
        part.remove('roteiro');
      }
    }
  }

  /// Sem o arquivo, nenhuma aula está em revisão.
  Future<Set<String>> _review([String list = 'lessons']) async {
    try {
      final json = jsonDecode(
        await _assets.loadString(reviewPath),
      ) as Map<String, dynamic>;
      return {...(json[list] as List? ?? const []).cast<String>()};
    } on LessonContentNotFound {
      return const {};
    } on LessonContentUnavailable {
      rethrow;
    } catch (_) {
      return const {};
    }
  }

  Future<LessonTexts> _load(String language) =>
      _cache.load(('lessonTexts', language), () => _loadTexts(language));

  Future<LessonTexts> _loadTexts(String language) async {
    final all = <String, dynamic>{};
    for (final lesson in (await _cache.load(indexPath, _loadTrail)).lessons) {
      final json = jsonDecode(
        await _assets.loadString(textsPath(language, lesson.id)),
      ) as Map<String, dynamic>;
      all.addAll(prefixed(lesson.id, json));
    }
    return LessonTexts.fromJson(all);
  }

  /// As falas de uma aula com as chaves no espaço das falas da escola:
  /// `step.x` vira `<aula>.x` (o que `LessonTexts.step` procura), e as outras
  /// (`title`, `ex.e01`, `key.k1`, `history`...) ganham o prefixo da aula.
  static Map<String, dynamic> prefixed(
    String lessonId,
    Map<String, dynamic> json,
  ) => {
    for (final MapEntry(:key, :value) in json.entries)
      key.startsWith('step.')
              ? '$lessonId.${key.substring('step.'.length)}'
              : '$lessonId.$key':
          value,
  };

  /// Lê uma aula gerada. Passo de tipo desconhecido é ignorado.
  static EndgameLesson parseLesson(
    Object? json, {
    bool inReview = false,
    bool failed = false,
  }) {
    final map = json as Map<String, dynamic>;
    final id = map['id'] as String;
    final practice = map['practice'] as Map<String, dynamic>;
    return EndgameLesson(
      id: id,
      module: map['module'] as String,
      inReview: inReview,
      failed: failed,
      lesson: AssetLessonRepository.parseLesson(map),
      exercises: [
        for (final exercise
            in (map['exercises'] as List).cast<Map<String, dynamic>>())
          Exercise(
            id: exercise['id'] as String,
            stars: exercise['stars'] as int,
            fen: exercise['fen'] as String,
            goal:
                PositionGoal.fromCode(exercise['goal'] as String?) ??
                PositionGoal.win,
            origin: exercise['origin'] as String? ?? 'own',
            line: AssetLessonRepository.parseLine(exercise['line'] as List),
          ),
      ],
      passScore: map['passScore'] as int,
      keyPositions: [
        for (final position
            in (map['keyPositions'] as List? ?? const [])
                .cast<Map<String, dynamic>>())
          KeyPosition(
            id: position['id'] as String,
            fen: position['fen'] as String,
            ref: position['ref'] as String?,
          ),
      ],
      practice: Practice(
        fen: practice['fen'] as String,
        goal:
            PositionGoal.fromCode(practice['goal'] as String?) ??
            PositionGoal.win,
        positionId: practice['positionId'] as String?,
      ),
      references: [
        for (final reference
            in (map['references'] as List? ?? const [])
                .cast<Map<String, dynamic>>())
          Reference(
            id: reference['id'] as String,
            kind: reference['kind'] as String,
            fields: {
              for (final MapEntry(:key, :value) in reference.entries)
                if (key != 'id' && key != 'kind') key: '$value',
            },
          ),
      ],
    );
  }
}
