import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_download_repository.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/lesson_package_service.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';

class _Reader extends LessonContentReader {
  _Reader(this.files);
  final Map<String, String> files;
  bool online = true;
  final requested = <String>[];
  @override
  Object get cacheScope => 'release-1';
  @override
  Future<String> read(String path) async {
    requested.add(path);
    if (!online) throw const LessonContentNetworkUnavailable();
    return files[path] ?? (throw const LessonContentNotFound());
  }
}

void main() {
  late Directory root;
  late _Reader source;
  String? user;
  LessonPackageService service() => LessonPackageService(
    source: source,
    directory: () async => root,
    identity: () => user,
  );
  const indexPath = 'assets/courses/pilares/index.json';
  const lessonPath = 'assets/lessons/endgames/pilares.c1.json';
  setUp(() async {
    root = await Directory.systemTemp.createTemp('lesson-package-test-');
    user = 'student-1';
    source = _Reader({indexPath: '{"partes":[]}', lessonPath: '{"parts":[]}'});
  });
  tearDown(() async => root.delete(recursive: true));

  test('complete package survives service recreation and has no network dependency', () async {
    final packages = service();
    await packages.install('entry', () async => Map.of(source.files));
    source.online = false;
    final restored = service();
    expect(await restored.installed('entry'), isTrue);
    expect(await restored.read(lessonPath), source.files[lessonPath]);
    expect(source.requested, isEmpty);
  });

  test('a failed package is never installed and retry can commit it', () async {
    final packages = service();
    await expectLater(
      packages.install('entry', () async {
        await source.read(indexPath);
        throw const LessonContentNetworkUnavailable();
      }),
      throwsA(isA<LessonContentNetworkUnavailable>()),
    );
    expect(await packages.installed('entry'), isFalse);
    await packages.install('entry', () async => Map.of(source.files));
    expect(await packages.installed('entry'), isTrue);
    expect(
      await root
          .list(recursive: true)
          .where((e) => e.path.contains('.staging-'))
          .isEmpty,
      isTrue,
    );
  });

  test('half-written staging directory is ignored after force close', () async {
    await service().install('entry', () async => Map.of(source.files));
    final markers = await root
        .list(recursive: true)
        .where((e) => e is File && e.path.endsWith('/package.json'))
        .toList();
    final target = (markers.single as File).parent;
    await target.rename('${target.parent.path}/.staging-interrupted');
    source.online = false;
    expect(await service().installed('entry'), isFalse);
    await expectLater(
      service().read(lessonPath),
      throwsA(isA<LessonContentNetworkUnavailable>()),
    );
  });

  test(
    'corrupted committed bytes fail hash verification after restart',
    () async {
      await service().install('entry', () async => Map.of(source.files));
      final files = await root
          .list(recursive: true)
          .where((e) => e is File && e.path.endsWith('/$lessonPath'))
          .toList();
      await (files.single as File).writeAsString('{"tampered":true}');
      source.online = false;
      expect(await service().installed('entry'), isFalse);
      await expectLater(
        service().read(lessonPath),
        throwsA(isA<LessonContentNetworkUnavailable>()),
      );
    },
  );

  test(
    'account switch cannot publish or read another account package',
    () async {
      final packages = service();
      await expectLater(
        packages.install('entry', () async {
          user = 'student-2';
          return Map.of(source.files);
        }),
        throwsA(isA<LessonContentUnavailable>()),
      );
      expect(await packages.installed('entry'), isFalse);
      user = 'student-1';
      await packages.install('entry', () async => Map.of(source.files));
      user = 'student-2';
      source.online = false;
      expect(await service().installed('entry'), isFalse);
      await expectLater(
        service().read(lessonPath),
        throwsA(isA<LessonContentNetworkUnavailable>()),
      );
    },
  );

  test('initial Pilares package includes one chapter and leaves the next unpublished pack alone', () async {
    source.files[indexPath] = jsonEncode({
      'partes': [
        {
          'capitulos': [
            {
              'id': 'pilares.c1',
              'aulas': [
                {'id': 'pilares.c1.fork', 'tipo': 'tema'},
                {'id': 'pilares.c1', 'tipo': 'teste'},
              ],
            },
            {
              'id': 'pilares.c2',
              'aulas': [],
              'arquivo': 'assets/lessons/endgames/pilares.c2.json',
            },
          ],
        },
      ],
    });
    source.files.addAll({
      'assets/lessons/en/lessons.json': '{}',
      'assets/lessons/en/endgames/pilares.c1.json': '{}',
      'assets/lessons/treino/pilares.c1.fork.json': '{"exercicios":[]}',
    });
    final repository = CourseDownloadRepository(service());
    await repository.prepare(TrainingCourseConfig.pilares);
    expect(await repository.isDownloaded(TrainingCourseConfig.pilares), isTrue);
    expect(
      source.requested,
      isNot(contains('assets/lessons/endgames/pilares.c2.json')),
    );
    source.online = false;
    final restored = CourseDownloadRepository(service());
    await restored.prepare(TrainingCourseConfig.pilares);
    expect(await restored.isDownloaded(TrainingCourseConfig.pilares), isTrue);
  });

  test('school package follows every script and never accepts missing required content', () async {
    const school = 'assets/lessons/course.json';
    source.files.addAll({
      school: '{"modules":[{"lessons":[{"roteiro":"assets/lessons/scripts/a.json"}]}]}',
      'assets/lessons/en/lessons.json': '{}',
    });
    final repository = CourseDownloadRepository(service());
    await expectLater(
      repository.prepare(TrainingCourseConfig.escola),
      throwsA(isA<LessonContentNotFound>()),
    );
    expect(await repository.isDownloaded(TrainingCourseConfig.escola), isFalse);
    source.files['assets/lessons/scripts/a.json'] = '{"steps":[]}';
    await repository.prepare(TrainingCourseConfig.escola);
    source.online = false;
    expect(
      await service().read('assets/lessons/scripts/a.json'),
      '{"steps":[]}',
    );
  });

  test(
    'refresh activates only after all lesson leases close and survives restart',
    () async {
      final packages = service();
      await packages.install('entry', () async => {lessonPath: 'old'});
      final first = packages.beginSession();
      final second = packages.beginSession();
      final scope = packages.cacheScope;
      await packages.refresh('entry', () async => {lessonPath: 'updated'});
      expect(await packages.read(lessonPath), 'old');
      expect(packages.cacheScope, scope);
      await first.close();
      expect(await packages.read(lessonPath), 'old');
      await second.close();
      expect(await packages.read(lessonPath), 'updated');
      expect(packages.cacheScope, isNot(scope));
      source.online = false;
      expect(await service().read(lessonPath), 'updated');
      await second.close();
    },
  );

  test('failed refresh retains installed offline content', () async {
    final packages = service();
    await packages.install('entry', () async => {lessonPath: 'old'});
    await expectLater(
      packages.refresh('entry', () async {
        throw const LessonContentNetworkUnavailable();
      }),
      throwsA(isA<LessonContentNetworkUnavailable>()),
    );
    source.online = false;
    expect(await service().installed('entry'), isTrue);
    expect(await service().read(lessonPath), 'old');
  });

  test('force close with deferred refresh keeps old pointer until a subsequent refresh', () async {
    final packages = service();
    await packages.install('entry', () async => {lessonPath: 'old'});
    packages.beginSession();
    await packages.refresh('entry', () async => {lessonPath: 'new'});
    final restarted = service();
    expect(await restarted.read(lessonPath), 'old');
    await restarted.refresh('entry', () async => {lessonPath: 'new'});
    expect(await restarted.read(lessonPath), 'new');
  });

  test('deferred refresh never activates under another account', () async {
    final packages = service();
    await packages.install('entry', () async => {lessonPath: 'old'});
    final lease = packages.beginSession();
    await packages.refresh('entry', () async => {lessonPath: 'new'});
    user = 'student-2';
    await lease.close();
    user = 'student-1';
    expect(await packages.read(lessonPath), 'old');
  });

  test(
    'shared index reads choose latest activated package deterministically',
    () async {
      final packages = service();
      await packages.install('entry', () async => {indexPath: 'old index'});
      await packages.install(
        'chapter',
        () async => {indexPath: 'new index', lessonPath: 'chapter'},
      );
      expect(await packages.read(indexPath), 'new index');
      expect(await service().read(indexPath), 'new index');
    },
  );

  test('repository refresh reads updated source in background and respects lesson lease', () async {
    const school = 'assets/lessons/course.json';
    source.files.addAll({
      school: '{"modules":[]}',
      'assets/lessons/en/lessons.json': '{}',
    });
    final packages = service();
    final repository = CourseDownloadRepository(packages);
    await repository.prepare(TrainingCourseConfig.escola);
    final lease = repository.beginSession()!;
    source.files[school] = '{"modules":[{"id":"updated"}]}';
    final before = source.requested.length;
    await repository.refresh(TrainingCourseConfig.escola);
    expect(source.requested.length, greaterThan(before));
    expect(await packages.read(school), '{"modules":[]}');
    await lease.close();
    expect(await packages.read(school), source.files[school]);
  });
}
