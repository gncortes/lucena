import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/lesson_package_index.dart';
import 'package:lucena/data/services/lesson_package_service.dart';
import 'package:lucena/data/repositories/training/course_download_repository.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';

import '../../../testing/fakes/fake_secure_storage_service.dart';

const path = 'assets/lessons/course.json';
const text = '{"modules":[]}';
Map<String, dynamic> descriptor() {
  final file = {
    'bytes': utf8.encode(text).length,
    'sha256': sha256.convert(utf8.encode(text)).toString(),
  };
  final files = {path: file};
  return {
    'bytes': utf8.encode(text).length,
    'sha256': sha256.convert(utf8.encode(jsonEncode(files))).toString(),
    'files': files,
  };
}

void main() {
  test('server published index selects new release, verifies bytes and defers activation during lesson', () async {
    final directory = await Directory.systemTemp.createTemp('package-index-');
    addTearDown(() => directory.delete(recursive: true));
    var release = 'r1';
    Map<String, String> files(String version) => {
      path: jsonEncode({'modules': [], 'version': version}),
      'assets/lessons/en/lessons.json': '{}',
    };
    Map<String, dynamic> entries(String version) => {
      for (final entry in files(version).entries)
        entry.key: {
          'bytes': utf8.encode(entry.value).length,
          'sha256': sha256.convert(utf8.encode(entry.value)).toString(),
        },
    };
    final reader = PublishedLessonContentReader(
      release: 'r1',
      cache: FakeSecureStorageService(),
      currentUser: () => 'student',
      download: (object) async {
        final version = object.split('/')[2];
        final contentPath = object.substring(
          'content/releases/$version/'.length,
        );
        final content = contentPath == 'manifest.json'
            ? jsonEncode({
                'format': 1,
                'release': version,
                'status': 'published',
                'files': entries(version),
              })
            : files(version)[contentPath];
        return content == null
            ? null
            : Uint8List.fromList(utf8.encode(content));
      },
    );
    final packages = LessonPackageService(
      source: reader,
      directory: () async => directory,
      identity: () => 'student',
    );
    final repository = CourseDownloadRepository(
      packages,
      indexSource: LessonPackageIndexSource(() async {
        final fileMap = entries(release);
        final paths = fileMap.keys.toList()..sort();
        final sorted = {for (final name in paths) name: fileMap[name]};
        return {
          'format': 1,
          'status': 'published',
          'release': release,
          'packages': {
            'escola:entry': {
              'bytes': files(release).values
                  .fold<int>(0, (n, value) => n + utf8.encode(value).length),
              'sha256': sha256
                  .convert(utf8.encode(jsonEncode(sorted)))
                  .toString(),
              'files': sorted,
            },
          },
        };
      }),
    );
    await repository.prepare(TrainingCourseConfig.escola);
    final lease = repository.beginSession()!;
    release = 'r2';
    await repository.refresh(TrainingCourseConfig.escola);
    expect(await packages.read(path), files('r1')[path]);
    expect((packages.source as PublishedLessonContentReader).release, 'r1');
    await lease.close();
    expect(await packages.read(path), files('r2')[path]);
    expect((packages.source as PublishedLessonContentReader).release, 'r2');
    final restored = LessonPackageService(
      source: reader,
      directory: () async => directory,
      identity: () => 'student',
    );
    expect(await restored.read(path), files('r2')[path]);
  });
  test('versioned index source actually calls injected server and parses bytes/hash contract', () async {
    var calls = 0;
    final source = LessonPackageIndexSource(() async {
      ++calls;
      return {
        'format': 1,
        'status': 'published',
        'release': 'r2',
        'packages': {'escola:entry': descriptor()},
      };
    });
    final index = await source.fetch();
    expect(index.release, 'r2');
    index.packages['escola:entry']!.verify({path: text});
    await source.fetch();
    expect(calls, 2);
  });
  test('package digest and exact file set are verified independently of file digests', () {
    final valid = LessonPackageDescriptor.fromJson(descriptor());
    expect(
      () => valid.verify({path: '$text '}),
      throwsA(isA<LessonContentUnavailable>()),
    );
    expect(
      () => valid.verify({path: text, 'assets/lessons/extra.json': '{}'}),
      throwsA(isA<LessonContentUnavailable>()),
    );
    final wrong = descriptor()..['sha256'] = '0' * 64;
    expect(
      () => LessonPackageDescriptor.fromJson(wrong).verify({path: text}),
      throwsA(isA<LessonContentUnavailable>()),
    );
  });
  test(
    'draft release, unsafe path and inconsistent package bytes are rejected',
    () {
      expect(
        () => LessonPackageIndex.fromJson({
          'format': 1,
          'status': 'draft',
          'release': 'r2',
          'packages': {},
        }),
        throwsA(isA<LessonContentUnavailable>()),
      );
      expect(
        () => LessonPackageDescriptor.fromJson(descriptor()..['bytes'] = 999),
        throwsA(isA<LessonContentUnavailable>()),
      );
      final bad = descriptor()
        ..['files'] = {
          'assets/lessons/../escape.json': {'bytes': 0, 'sha256': '0' * 64},
        };
      expect(
        () => LessonPackageDescriptor.fromJson(bad),
        throwsA(isA<LessonContentUnavailable>()),
      );
    },
  );
}
