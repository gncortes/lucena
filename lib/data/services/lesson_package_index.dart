import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:crypto/crypto.dart';

import 'lesson_content_service.dart';

/// Proposed server index contract. The injected fetch MUST consult the server,
/// e.g. a Firestore document with Source.server, not an offline snapshot.
/// No collection/document is assumed to exist or be provisioned by this app.
class LessonPackageIndexSource {
  const LessonPackageIndexSource(this.fetchServer);
  factory LessonPackageIndexSource.firestore(
    String documentPath, {
    FirebaseFirestore? firestore,
  }) {
    final document = (firestore ?? FirebaseFirestore.instance).doc(
      documentPath,
    );
    return LessonPackageIndexSource(() async {
      try {
        final snapshot = await document.get(
          const GetOptions(source: Source.server),
        );
        return snapshot.data() ?? (throw const LessonContentUnavailable());
      } on FirebaseException catch (error) {
        if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
          throw const LessonContentNetworkUnavailable();
        }
        throw const LessonContentUnavailable();
      }
    });
  }
  final Future<Map<String, dynamic>> Function() fetchServer;
  Future<LessonPackageIndex> fetch() async =>
      LessonPackageIndex.fromJson(await fetchServer());
}

class LessonPackageIndex {
  const LessonPackageIndex(this.release, this.packages);
  final String release;
  final Map<String, LessonPackageDescriptor> packages;
  factory LessonPackageIndex.fromJson(Map<String, dynamic> json) {
    if (json['format'] != 1 ||
        json['status'] != 'published' ||
        json['release'] is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(json['release'] as String) ||
        json['packages'] is! Map) {
      throw const LessonContentUnavailable();
    }
    return LessonPackageIndex(
      json['release'] as String,
      Map.unmodifiable(
        (json['packages'] as Map).map(
          (key, value) => MapEntry(
            key as String,
            LessonPackageDescriptor.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          ),
        ),
      ),
    );
  }
}

/// The package digest is SHA-256 of UTF-8 JSON for the sorted file map:
/// {path: {"bytes": UTF8_LENGTH, "sha256": FILE_DIGEST}, ...}.
class LessonPackageDescriptor {
  LessonPackageDescriptor._(this.bytes, this.digest, this.files);
  final int bytes;
  final String digest;
  final Map<String, ({int bytes, String digest})> files;
  factory LessonPackageDescriptor.fromJson(Map<String, dynamic> json) {
    final files = <String, ({int bytes, String digest})>{};
    bool hash(Object? value) =>
        value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
    if (json['bytes'] is! int ||
        (json['bytes'] as int) < 0 ||
        !hash(json['sha256']) ||
        json['files'] is! Map) {
      throw const LessonContentUnavailable();
    }
    for (final entry in (json['files'] as Map).entries) {
      if (entry.key is! String ||
          !isLessonContentPath(entry.key as String) ||
          entry.value is! Map) {
        throw const LessonContentUnavailable();
      }
      final file = entry.value as Map;
      if (file['bytes'] is! int ||
          (file['bytes'] as int) < 0 ||
          (file['bytes'] as int) > 8 * 1024 * 1024 ||
          !hash(file['sha256'])) {
        throw const LessonContentUnavailable();
      }
      files[entry.key as String] = (
        bytes: file['bytes'] as int,
        digest: file['sha256'] as String,
      );
    }
    if (files.isEmpty ||
        files.values.fold(0, (n, f) => n + f.bytes) != json['bytes']) {
      throw const LessonContentUnavailable();
    }
    return LessonPackageDescriptor._(
      json['bytes'] as int,
      json['sha256'] as String,
      Map.unmodifiable(files),
    );
  }
  void verify(Map<String, String> content) {
    if (files.length != content.length) throw const LessonContentUnavailable();
    final paths = files.keys.toList()..sort();
    final actual = <String, Object>{};
    for (final path in paths) {
      final text = content[path];
      if (text == null) throw const LessonContentUnavailable();
      final raw = utf8.encode(text);
      final hash = sha256.convert(raw).toString();
      if (raw.length != files[path]!.bytes || hash != files[path]!.digest) {
        throw const LessonContentUnavailable();
      }
      actual[path] = {'bytes': raw.length, 'sha256': hash};
    }
    if (sha256.convert(utf8.encode(jsonEncode(actual))).toString() != digest) {
      throw const LessonContentUnavailable();
    }
  }
}
