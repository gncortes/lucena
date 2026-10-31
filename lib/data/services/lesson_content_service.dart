import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import 'asset_service.dart';
import 'secure_storage_service.dart';
import '../../domain/models/lesson_content.dart';

export '../../domain/models/lesson_content.dart';

/// Paths are format identifiers, not APK assets or arbitrary remote URLs.
bool isLessonContentPath(String path) =>
    RegExp(r'^assets/(lessons|courses)/[a-zA-Z0-9_./-]+\.json$')
        .hasMatch(path) &&
    !path.split('/').any((part) => part.isEmpty || part == '.' || part == '..');

abstract class LessonContentReader {
  Object get cacheScope => this;

  /// Stable storage namespace, independent of the signed-in account.
  Object get storageScope => cacheScope;
  Future<String> read(String path);
}

/// Compatibility adapter for the JSON parsers. Never falls back to rootBundle.
class LessonContentAssets extends AssetService {
  const LessonContentAssets({this.reader});

  final LessonContentReader? reader;

  @override
  Object get cacheScope => reader?.cacheScope ?? this;

  static const _emptyCatalog = {
    'assets/lessons/course.json': '{"modules":[]}',
    'assets/lessons/endgames/index.json': '{"modules":[]}',
    'assets/lessons/endgames/review.json': '{"lessons":[],"failed":[]}',
    'assets/lessons/en/lessons.json': '{}',
    'assets/lessons/pt/lessons.json': '{}',
  };

  @override
  Future<String> loadString(String path) async {
    if (!isLessonContentPath(path)) throw ArgumentError.value(path, 'path');
    if (reader case final source?) return source.read(path);
    return _emptyCatalog[path] ?? (throw const LessonContentUnavailable());
  }

  @override
  Future<Uint8List> loadBytes(String path) async =>
      Uint8List.fromList(utf8.encode(await loadString(path)));
}

/// Explicit development-only source; the factory rejects it in release builds.
class LocalHttpLessonContentReader extends LessonContentReader {
  LocalHttpLessonContentReader(this.base, {http.Client? client})
    : _client = client ?? http.Client() {
    if ((base.scheme != 'http' && base.scheme != 'https') ||
        base.host.isEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        base.userInfo.isNotEmpty) {
      throw ArgumentError.value(base, 'base');
    }
  }

  final Uri base;
  final http.Client _client;
  @override
  Object get cacheScope => base.toString();

  @override
  Future<String> read(String path) async {
    if (!isLessonContentPath(path)) throw ArgumentError.value(path, 'path');
    final root = base.toString().endsWith('/') ? base : Uri.parse('$base/');
    try {
      final response = await _client
          .get(root.resolve(path))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 404) throw const LessonContentNotFound();
      if (response.statusCode != 200 ||
          response.bodyBytes.length > 8 * 1024 * 1024) {
        throw const LessonContentUnavailable();
      }
      return utf8.decode(response.bodyBytes);
    } on SocketException {
      throw const LessonContentNetworkUnavailable();
    } on TimeoutException {
      throw const LessonContentNetworkUnavailable();
    } on http.ClientException {
      throw const LessonContentNetworkUnavailable();
    } on LessonContentUnavailable {
      rethrow;
    } on Object {
      throw const LessonContentUnavailable();
    }
  }
}

/// Download operation only. Upload/deploy credentials never belong to the app.
typedef LessonObjectDownload = Future<Uint8List?> Function(String object);

/// Reads one immutable, reviewed release; backend rules must enforce purchases.
/// A published server index may select another reader; draft releases are rejected.
class PublishedLessonContentReader extends LessonContentReader {
  PublishedLessonContentReader({
    required this.release,
    required this.download,
    required this.cache,
    required this.currentUser,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(release)) {
      throw ArgumentError.value(release, 'release');
    }
  }

  final String release;
  final LessonObjectDownload download;
  final SecureStorageService cache;
  final String? Function() currentUser;
  PublishedLessonContentReader forRelease(String publishedRelease) =>
      PublishedLessonContentReader(
        release: publishedRelease,
        download: download,
        cache: cache,
        currentUser: currentUser,
      );
  @override
  Object get cacheScope => (release, currentUser());
  @override
  Object get storageScope => ('published', release);
  final _manifests = <String, Future<Map<String, dynamic>>>{};
  String get prefix => 'content/releases/$release/';
  String _cachePrefix(String user) =>
      'lesson-content:${sha256.convert(utf8.encode(user))}:$release';

  /// Consults Storage even with a cached manifest. Published releases are
  /// immutable: selecting a different release requires a new explicit reader.
  Future<void> refreshManifest() async {
    final user = currentUser();
    if (user == null || user.isEmpty) throw const LessonContentUnavailable();
    final bytes = await download('${prefix}manifest.json');
    if (bytes == null || bytes.length > 1024 * 1024) {
      throw const LessonContentUnavailable();
    }
    final fresh = _parseManifest(utf8.decode(bytes));
    final previous = await (_manifests[user] ??= _loadManifest(user));
    String fingerprint(Map<String, dynamic> manifest) {
      final files = manifest['files'] as Map;
      final paths = files.keys.cast<String>().toList()..sort();
      return jsonEncode({
        for (final path in paths)
          path: {
            'bytes': (files[path] as Map)['bytes'],
            'sha256': (files[path] as Map)['sha256'],
          },
      });
    }

    if (fingerprint(previous) != fingerprint(fresh)) {
      throw const LessonContentUnavailable();
    }
    if (currentUser() != user) throw const LessonContentUnavailable();
  }

  Future<Map<String, dynamic>> _loadManifest(String user) async {
    final manifestKey = '${_cachePrefix(user)}:manifest';
    var raw = await cache.read(manifestKey);
    if (raw != null) {
      try {
        _parseManifest(raw);
      } on Object {
        await cache.delete(manifestKey);
        raw = null;
      }
    }
    if (raw == null) {
      final bytes = await download('${prefix}manifest.json');
      if (bytes == null || bytes.length > 1024 * 1024) {
        throw const LessonContentUnavailable();
      }
      raw = utf8.decode(bytes);
    }
    final json = _parseManifest(raw);
    if (currentUser() != user) throw const LessonContentUnavailable();
    await cache.write(manifestKey, raw);
    return json;
  }

  Map<String, dynamic> _parseManifest(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['format'] != 1 ||
        json['release'] != release ||
        json['status'] != 'published' ||
        json['files'] is! Map) {
      throw const LessonContentUnavailable();
    }
    return json;
  }

  @override
  Future<String> read(String path) async {
    if (!isLessonContentPath(path)) throw ArgumentError.value(path, 'path');
    final user = currentUser();
    if (user == null || user.isEmpty) throw const LessonContentUnavailable();
    try {
      final manifest = await (_manifests[user] ??= _loadManifest(user));
      final entry = (manifest['files'] as Map)[path];
      if (entry == null) throw const LessonContentNotFound();
      if (entry is! Map ||
          entry['sha256'] is! String ||
          entry['bytes'] is! int) {
        throw const LessonContentUnavailable();
      }
      final digest = entry['sha256'] as String;
      final length = entry['bytes'] as int;
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest) ||
          length < 0 ||
          length > 8 * 1024 * 1024) {
        throw const LessonContentUnavailable();
      }
      final key = '${_cachePrefix(user)}:$digest';
      final saved = await cache.read(key);
      if (saved != null) {
        final bytes = utf8.encode(saved);
        if (bytes.length == length &&
            sha256.convert(bytes).toString() == digest) {
          if (currentUser() != user) throw const LessonContentUnavailable();
          return saved;
        }
        await cache.delete(key);
      }
      // The manifest cannot redirect to draft paths, URLs or another release.
      final bytes = await download('$prefix$path');
      if (bytes == null ||
          bytes.length != length ||
          sha256.convert(bytes).toString() != digest) {
        throw const LessonContentUnavailable();
      }
      final text = utf8.decode(bytes);
      if (currentUser() != user) throw const LessonContentUnavailable();
      await cache.write(key, text);
      return text;
    } on SocketException {
      _manifests.remove(user);
      throw const LessonContentNetworkUnavailable();
    } on TimeoutException {
      _manifests.remove(user);
      throw const LessonContentNetworkUnavailable();
    } on FirebaseException catch (error) {
      _manifests.remove(user);
      if ([
        'retry-limit-exceeded',
        'network-request-failed',
      ].contains(error.code)) {
        throw const LessonContentNetworkUnavailable();
      }
      throw const LessonContentUnavailable();
    } on LessonContentUnavailable {
      _manifests.remove(user);
      rethrow;
    } on Object {
      _manifests.remove(user);
      throw const LessonContentUnavailable();
    }
  }
}

LessonContentAssets createLessonContentAssets({
  required bool releaseBuild,
  required bool firebase,
  String localUrl = '',
  String publishedRelease = '',
  LessonObjectDownload? download,
  SecureStorageService? cache,
  String? Function()? currentUser,
}) {
  if (localUrl.isNotEmpty) {
    if (releaseBuild) {
      throw StateError(
        'Local lesson content is restricted to development builds.',
      );
    }
    return LessonContentAssets(
      reader: LocalHttpLessonContentReader(Uri.parse(localUrl)),
    );
  }
  if (firebase && publishedRelease.isNotEmpty) {
    final read =
        download ??
        (String object) => FirebaseStorage.instance
            .ref(object)
            .getData(8 * 1024 * 1024)
            .timeout(const Duration(seconds: 20));
    return LessonContentAssets(
      reader: PublishedLessonContentReader(
        release: publishedRelease,
        download: read,
        cache: cache ?? DeviceSecureStorageService(),
        currentUser:
            currentUser ?? () => FirebaseAuth.instance.currentUser?.uid,
      ),
    );
  }
  return const LessonContentAssets();
}
