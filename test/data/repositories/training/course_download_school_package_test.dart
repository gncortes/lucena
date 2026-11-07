import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/repositories/training/course_download_repository.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/lesson_package_index.dart';
import 'package:lucena/data/services/lesson_package_service.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';

import '../../../../testing/fakes/fake_secure_storage_service.dart';

const coursePath = 'assets/lessons/course.json';

Map<String, String> fixture() => {
  coursePath: jsonEncode({
    'modules': [
      {
        'id': 'm',
        'lessons': [
          {'id': 'a', 'steps': [], 'roteiro': 'assets/lessons/roteiros/a.json'},
        ],
      },
    ],
  }),
  'assets/lessons/roteiros/a.json': '{"licao":"a","parte":"a","etapas":[]}',
  for (final language in ['en', 'pt']) ...{
    'assets/lessons/$language/lessons.json': '{}',
    'assets/lessons/$language/roteiro_generico.json': '{"generic":"$language"}',
    'assets/lessons/$language/roteiro_iniciante.json':
        '{"beginner":"$language"}',
    'assets/lessons/$language/iniciante/a.json': '{"lesson":"$language"}',
  },
};

void main() {
  late Directory directory;
  late Map<String, String> files;
  late FakeSecureStorageService cache;
  var online = true;
  var requests = 0;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('school-package-');
    files = fixture();
    cache = FakeSecureStorageService();
    online = true;
    requests = 0;
  });
  tearDown(() => directory.delete(recursive: true));

  LessonPackageService service() => LessonPackageService(
    source: PublishedLessonContentReader(
      release: 'school-test',
      cache: cache,
      currentUser: () => 'student',
      download: (object) async {
        requests++;
        if (!online) throw const SocketException('offline');
        final path = object.substring('content/releases/school-test/'.length);
        final text = path == 'manifest.json'
            ? jsonEncode({
                'format': 1,
                'status': 'published',
                'release': 'school-test',
                'files': {
                  for (final entry in files.entries)
                    entry.key: {
                      'bytes': utf8.encode(entry.value).length,
                      'sha256': sha256
                          .convert(utf8.encode(entry.value))
                          .toString(),
                    },
                },
              })
            : files[path];
        return text == null ? null : Uint8List.fromList(utf8.encode(text));
      },
    ),
    directory: () async => directory,
    identity: () => 'student',
  );

  test(
    'first entry installs implicit dictionaries for offline restart',
    () async {
      await CourseDownloadRepository(service())
          .prepare(TrainingCourseConfig.escola);
      online = false;
      final restored = service();
      expect(await restored.installed('escola:entry'), isTrue);
      final scripts = AssetLessonScriptRepository(
        LessonContentAssets(reader: restored),
      );
      final before = requests;
      expect(
        (await scripts.script('assets/lessons/roteiros/a.json')).lessonId,
        'a',
      );
      for (final language in ['en', 'pt']) {
        final texts = await scripts.texts('a', language);
        expect(texts.say('generic'), language);
        expect(texts.say('beginner'), language);
        expect(texts.say('lesson'), language);
      }
      expect(requests, before);
    },
  );

  for (final path in [
    'assets/lessons/pt/iniciante/a.json',
    'assets/lessons/en/roteiro_generico.json',
  ]) {
    test('missing mandatory $path prevents installation', () async {
      files.remove(path);
      final packages = service();
      await expectLater(
        CourseDownloadRepository(packages).prepare(TrainingCourseConfig.escola),
        throwsA(isA<LessonContentNotFound>()),
      );
      expect(await packages.installed('escola:entry'), isFalse);
    });
  }

  test(
    'route script is downloaded without an explicit course reference',
    () async {
      files[coursePath] = '{"modules":[{"lessons":[{"id":"a","steps":[]}]}]}';
      await CourseDownloadRepository(service())
          .prepare(TrainingCourseConfig.escola);
      online = false;
      expect(
        await service().read('assets/lessons/roteiros/a.json'),
        files['assets/lessons/roteiros/a.json'],
      );
    },
  );

  final candidate = Platform.environment['SCHOOL_PACKAGE_CANDIDATE'];
  if (candidate != null) {
    test(
      'private local Python bundle matches Dart index and offline school',
      () async {
        final bundle = jsonDecode(
          await File('$candidate/bundle.json').readAsString(),
        ) as Map;
        final index = LessonPackageIndex.fromJson(
          jsonDecode(await File('$candidate/index.json').readAsString())
              as Map<String, dynamic>,
        );
        files = Map<String, String>.from(bundle['files'] as Map);
        index.packages['escola:entry']!.verify(files);
        final packages = service();
        final wireIndex = jsonDecode(
          await File('$candidate/index.json').readAsString(),
        ) as Map<String, dynamic>;
        // Keep the Python descriptor intact; only the synthetic transport's
        // release name differs from the local candidate's label.
        await CourseDownloadRepository(
          packages,
          indexSource: LessonPackageIndexSource(
            () async => {...wireIndex, 'release': 'school-test'},
          ),
        ).prepare(TrainingCourseConfig.escola);
        online = false;
        final restored = service();
        final scripts = AssetLessonScriptRepository(
          LessonContentAssets(reader: restored),
        );
        final course = jsonDecode(await restored.read(coursePath)) as Map;
        final before = requests;
        for (final module in course['modules'] as List) {
          for (final lesson in (module as Map)['lessons'] as List) {
            final data = lesson as Map;
            if (data['roteiro'] case final String path) {
              await scripts.script(path);
            }
            for (final language in ['en', 'pt']) {
              await scripts.texts(data['id'] as String, language);
            }
          }
        }
        expect(requests, before);
      },
    );
  }
}
