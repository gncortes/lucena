import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucena/data/services/lesson_content_service.dart';

import '../../../testing/fakes/fake_secure_storage_service.dart';

const _path = 'assets/lessons/pt/lessons.json';
const _text = '{"example":"Synthetic contract fixture"}';
Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));
String _manifest({String status = 'published', String? digest}) => jsonEncode({
  'format': 1,
  'release': 'test_v1',
  'status': status,
  'files': {
    _path: {
      'sha256': digest ?? sha256.convert(utf8.encode(_text)).toString(),
      'bytes': utf8.encode(_text).length,
    },
  },
});

void main() {
  test('refresh checks server even with cached content and rejects mutation of immutable release', () async {
    var calls = 0;
    var manifest = _manifest();
    final reader = PublishedLessonContentReader(
      release: 'test_v1',
      currentUser: () => 'student',
      cache: FakeSecureStorageService(),
      download: (object) async {
        ++calls;
        return _bytes(object.endsWith('/manifest.json') ? manifest : _text);
      },
    );
    await reader.read(_path);
    final cachedCalls = calls;
    await reader.refreshManifest();
    expect(calls, cachedCalls + 1);
    manifest = _manifest(status: 'draft');
    await expectLater(
      reader.refreshManifest(),
      throwsA(isA<LessonContentUnavailable>()),
    );
    manifest = _manifest(digest: '0' * 64);
    await expectLater(
      reader.refreshManifest(),
      throwsA(isA<LessonContentUnavailable>()),
    );
    expect(await reader.read(_path), _text);
  });
  test('no source gives empty catalog, never bundled lesson data', () async {
    const assets = LessonContentAssets();
    expect(
      await assets.loadString('assets/lessons/course.json'),
      '{"modules":[]}',
    );
    expect(
      await assets.loadString('assets/lessons/endgames/index.json'),
      '{"modules":[]}',
    );
    expect(await assets.loadString(_path), '{}');
    await expectLater(
      assets.loadString('assets/lessons/roteiros/example.json'),
      throwsA(isA<LessonContentUnavailable>()),
    );
  });

  for (final path in [
    '../assets/lessons/course.json',
    'assets/lessons/../secret.json',
    'assets/lessons/%2e%2e/secret.json',
    'https://example.test/file.json',
    'assets/positions/positions.json',
    'assets/lessons//file.json',
  ]) {
    test('rejects non-content path: $path', () async {
      expect(isLessonContentPath(path), isFalse);
      await expectLater(
        const LessonContentAssets().loadString(path),
        throwsArgumentError,
      );
    });
  }

  test('development uses only explicitly supplied server', () async {
    Uri? requested;
    final reader = LocalHttpLessonContentReader(
      Uri.parse('http://localhost:8791/dev'),
      client: MockClient((request) async {
        requested = request.url;
        return http.Response(_text, 200);
      }),
    );
    expect(await reader.read(_path), _text);
    expect(requested.toString(), 'http://localhost:8791/dev/$_path');
  });

  test('release rejects local development URL before using it', () {
    expect(
      () => createLessonContentAssets(
        releaseBuild: true,
        firebase: false,
        localUrl: 'http://10.0.2.2:8791',
      ),
      throwsStateError,
    );
  });

  test('no selected release does not touch Firebase/download', () async {
    var calls = 0;
    final assets = createLessonContentAssets(
      releaseBuild: true,
      firebase: true,
      download: (_) async {
        calls++;
        return null;
      },
    );
    expect(await assets.loadString(_path), '{}');
    expect(calls, 0);
  });

  test(
    'published data is hash checked and stored in account-scoped secure cache',
    () async {
      final cache = FakeSecureStorageService();
      final calls = <String>[];
      final reader = PublishedLessonContentReader(
        release: 'test_v1',
        cache: cache,
        currentUser: () => 'user-a',
        download: (object) async {
          calls.add(object);
          return _bytes(object.endsWith('manifest.json') ? _manifest() : _text);
        },
      );
      expect(await reader.read(_path), _text);
      expect(calls, [
        'content/releases/test_v1/manifest.json',
        'content/releases/test_v1/$_path',
      ]);
      final offline = PublishedLessonContentReader(
        release: 'test_v1',
        cache: cache,
        currentUser: () => 'user-a',
        download: (_) async => throw StateError('offline'),
      );
      expect(await offline.read(_path), _text);
    },
  );

  test('a different account cannot reuse the paid content cache', () async {
    final cache = FakeSecureStorageService();
    final original = PublishedLessonContentReader(
      release: 'test_v1',
      cache: cache,
      currentUser: () => 'user-a',
      download: (object) async =>
          _bytes(object.endsWith('manifest.json') ? _manifest() : _text),
    );
    expect(await original.read(_path), _text);
    final other = PublishedLessonContentReader(
      release: 'test_v1',
      cache: cache,
      currentUser: () => 'user-b',
      download: (_) async => null,
    );
    await expectLater(
      other.read(_path),
      throwsA(isA<LessonContentUnavailable>()),
    );
  });

  test('no authenticated identity cannot read a published release', () async {
    var calls = 0;
    final reader = PublishedLessonContentReader(
      release: 'test_v1',
      cache: FakeSecureStorageService(),
      currentUser: () => null,
      download: (_) async {
        calls++;
        return null;
      },
    );
    await expectLater(
      reader.read(_path),
      throwsA(isA<LessonContentUnavailable>()),
    );
    expect(calls, 0);
  });

  test('draft manifest is rejected and not cached', () async {
    final cache = FakeSecureStorageService();
    final reader = PublishedLessonContentReader(
      release: 'test_v1',
      cache: cache,
      currentUser: () => 'user-a',
      download: (_) async => _bytes(_manifest(status: 'draft')),
    );
    await expectLater(
      reader.read(_path),
      throwsA(isA<LessonContentUnavailable>()),
    );
    expect(cache.values, isEmpty);
  });

  test('mismatched content hash is rejected and not cached', () async {
    final corrupt = _text.replaceFirst('Synthetic', 'synthetic');
    expect(utf8.encode(corrupt).length, utf8.encode(_text).length);
    final cache = FakeSecureStorageService();
    final reader = PublishedLessonContentReader(
      release: 'test_v1',
      cache: cache,
      currentUser: () => 'user-a',
      download: (object) async =>
          _bytes(object.endsWith('manifest.json') ? _manifest() : corrupt),
    );
    await expectLater(
      reader.read(_path),
      throwsA(isA<LessonContentUnavailable>()),
    );
    expect(cache.values.values, isNot(contains(corrupt)));
  });

  test(
    'changing account during download cannot return or cache content',
    () async {
      String? user = 'user-a';
      final cache = FakeSecureStorageService();
      final reader = PublishedLessonContentReader(
        release: 'test_v1',
        cache: cache,
        currentUser: () => user,
        download: (object) async {
          if (object.endsWith('manifest.json')) return _bytes(_manifest());
          user = 'user-b';
          return _bytes(_text);
        },
      );
      await expectLater(
        reader.read(_path),
        throwsA(isA<LessonContentUnavailable>()),
      );
      expect(cache.values.values, isNot(contains(_text)));
    },
  );

  test('network failure is retryable without creating a new reader', () async {
    var online = false;
    final reader = PublishedLessonContentReader(
      release: 'test_v1',
      cache: FakeSecureStorageService(),
      currentUser: () => 'user-a',
      download: (object) async => !online
          ? null
          : _bytes(object.endsWith('manifest.json') ? _manifest() : _text),
    );
    await expectLater(
      reader.read(_path),
      throwsA(isA<LessonContentUnavailable>()),
    );
    online = true;
    expect(await reader.read(_path), _text);
  });

  test('release identifier cannot escape the publication namespace', () {
    expect(
      () => PublishedLessonContentReader(
        release: '../drafts',
        cache: FakeSecureStorageService(),
        currentUser: () => 'user-a',
        download: (_) async => null,
      ),
      throwsArgumentError,
    );
  });
}
