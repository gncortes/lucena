import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'lesson_content_service.dart';
import 'lesson_package_index.dart';

class LessonPackageLease {
  LessonPackageLease._(this._service, this._user);
  final LessonPackageService _service;
  final String _user;
  bool _closed = false;
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _service._endSession(_user);
  }
}

class _Activation {
  const _Activation(
    this.user,
    this.folder,
    this.version,
    this.files,
    this.source,
    this.refresh,
  );
  final String user, version;
  final Directory folder;
  final Map<String, String> files;
  final LessonContentReader? source;
  final bool refresh;
}

/// Refresh keeps immutable versions behind an atomically replaced pointer.
/// Leases defer every activation for the account, including shared dictionaries.
class LessonPackageService extends LessonContentReader {
  LessonPackageService({
    required LessonContentReader source,
    required this.directory,
    required this.identity,
  }) : _source = source,
       _origin = source,
       _namespace = source.storageScope;
  LessonContentReader _source;
  final LessonContentReader _origin;
  final Object _namespace;
  LessonContentReader get source => _source;
  final Future<Directory> Function() directory;
  final String? Function() identity;
  final _pending = <String, Future<void>>{};
  final _loaded = <String, Map<String, String>>{};
  final _leases = <String, int>{};
  final _waiting = <String, _Activation>{};
  var _generation = 0;
  Future<void> _activationQueue = Future<void>.value();
  @override
  Object get cacheScope => (source.cacheScope, _generation);
  @override
  Object get storageScope => _namespace;
  String _digest(String value) => sha256.convert(utf8.encode(value)).toString();
  Future<Directory> _root(String user) async {
    final base = '${(await directory()).path}/lesson-packages';
    final current = Directory('$base/${_digest('$user:$_namespace')}');
    if (await current.exists()) return current;
    final legacy = Directory('$base/${_digest('$user:${_origin.cacheScope}')}');
    return await legacy.exists() ? legacy : current;
  }

  String _user() => identity() ?? (throw const LessonContentUnavailable());
  void _checkUser(String user) {
    if (identity() != user) throw const LessonContentUnavailable();
  }

  LessonPackageLease beginSession() {
    final user = _user();
    _leases[user] = (_leases[user] ?? 0) + 1;
    return LessonPackageLease._(this, user);
  }

  Future<void> _endSession(String user) async {
    final remaining = (_leases[user] ?? 1) - 1;
    if (remaining > 0) {
      _leases[user] = remaining;
      return;
    }
    _leases.remove(user);
    for (final entry in _waiting.entries.toList()) {
      if (entry.value.user != user) continue;
      _waiting.remove(entry.key);
      if (identity() == user) await _activate(entry.value);
    }
  }

  Future<Map<String, String>?> _load(Directory folder) async {
    try {
      final metadata = jsonDecode(
        await File('${folder.path}/package.json').readAsString(),
      ) as Map;
      if (metadata['format'] != 1 || metadata['files'] is! Map) return null;
      final result = <String, String>{};
      for (final entry in (metadata['files'] as Map).entries) {
        final path = entry.key as String;
        if (!isLessonContentPath(path)) return null;
        final text = await File('${folder.path}/$path').readAsString();
        if (_digest(text) != entry.value) return null;
        result[path] = text;
      }
      return result.isEmpty ? null : result;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<Directory> _active(Directory folder) async {
    final pointer = File('${folder.path}/active');
    if (!await pointer.exists()) return folder;
    final raw = await pointer.readAsString();
    final version = raw.startsWith('{')
        ? (jsonDecode(raw) as Map)['version'] as String
        : raw;
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(version)) {
      throw const LessonContentUnavailable();
    }
    return Directory('${folder.path}/.versions/$version');
  }

  Future<Map<String, String>?> _committed(Directory folder) async {
    final active = await _active(folder);
    if (_loaded[active.path] case final files?) return files;
    final files = await _load(active);
    if (files != null) _loaded[active.path] = files;
    return files;
  }

  Future<bool> installed(String key) async {
    final user = _user();
    final root = await _root(user);
    final files = await _committed(Directory('${root.path}/${_digest(key)}'));
    _checkUser(user);
    return files != null;
  }

  Future<bool> contains(String key, String path) async {
    if (!isLessonContentPath(path)) throw ArgumentError.value(path, 'path');
    final user = _user();
    final root = await _root(user);
    final files = await _committed(Directory('${root.path}/${_digest(key)}'));
    _checkUser(user);
    return files?.containsKey(path) == true;
  }

  Future<void> install(
    String key,
    Future<Map<String, String>> Function() files, {
    LessonPackageDescriptor? descriptor,
  }) => _download(key, files, refresh: false, descriptor: descriptor);
  Future<void> refresh(
    String key,
    Future<Map<String, String>> Function() files, {
    LessonContentReader? candidateSource,
    LessonPackageDescriptor? descriptor,
  }) => _download(
    key,
    files,
    refresh: true,
    candidateSource: candidateSource,
    descriptor: descriptor,
  );
  Future<void> _download(
    String key,
    Future<Map<String, String>> Function() files, {
    required bool refresh,
    LessonContentReader? candidateSource,
    LessonPackageDescriptor? descriptor,
  }) {
    final user = _user();
    final operationKey = '$user:$key';
    return _pending.putIfAbsent(operationKey, () async {
      Directory? staging;
      var bytes = descriptor?.bytes ?? 0;
      try {
        final root = await _root(user);
        final folder = Directory('${root.path}/${_digest(key)}');
        if (!refresh && await _committed(folder) != null) return;
        final content = await files();
        if (content.isEmpty) throw const LessonContentUnavailable();
        descriptor?.verify(content);
        bytes = content.values.fold(
          0,
          (n, text) => n + utf8.encode(text).length,
        );
        final hashes = <String, String>{};
        for (final entry in content.entries) {
          if (!isLessonContentPath(entry.key)) {
            throw ArgumentError.value(entry.key, 'path');
          }
          hashes[entry.key] = _digest(entry.value);
        }
        final paths = hashes.keys.toList()..sort();
        final version = _digest(
          jsonEncode({for (final path in paths) path: hashes[path]}),
        );
        final destination = Directory('${folder.path}/.versions/$version');
        await folder.create(recursive: true);
        staging = await folder.createTemp('.staging-');
        for (final entry in content.entries) {
          _checkUser(user);
          final file = File('${staging.path}/${entry.key}');
          await file.parent.create(recursive: true);
          await file.writeAsString(entry.value, flush: true);
        }
        await File('${staging.path}/package.json').writeAsString(
          jsonEncode({'format': 1, 'files': hashes}),
          flush: true,
        );
        if (await _load(staging) == null) {
          throw const LessonContentUnavailable();
        }
        _checkUser(user);
        await destination.parent.create(recursive: true);
        if (await destination.exists() && await _load(destination) == null) {
          await destination.delete(recursive: true);
        }
        if (!await destination.exists()) await staging.rename(destination.path);
        final activation = _Activation(
          user,
          folder,
          version,
          Map.unmodifiable(content),
          candidateSource,
          refresh,
        );
        if (refresh && (_leases[user] ?? 0) > 0) {
          _waiting[folder.path] = activation;
        } else {
          await _activate(activation);
        }
      } on FileSystemException catch (error) {
        if ([28, 112].contains(error.osError?.errorCode)) {
          throw LessonContentStorageUnavailable(bytes);
        }
        rethrow;
      } finally {
        if (staging != null && await staging.exists()) {
          await staging.delete(recursive: true);
        }
        _pending.remove(operationKey);
      }
    });
  }

  Future<void> _activate(_Activation activation) {
    final operation = _activationQueue.then(
      (_) => _performActivation(activation),
    );
    _activationQueue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _performActivation(_Activation activation) async {
    _checkUser(activation.user);
    if (activation.refresh && (_leases[activation.user] ?? 0) > 0) {
      _waiting[activation.folder.path] = activation;
      return;
    }
    final pointer = File('${activation.folder.path}/active');
    if ((await _active(activation.folder)).path
            .endsWith('/${activation.version}') &&
        activation.source == null) {
      return;
    }
    final counter = File('${activation.folder.parent.path}/sequence');
    final sequence =
        (await counter.exists() ? int.parse(await counter.readAsString()) : 0) +
        1;
    final nextCounter = File('${counter.path}.next');
    await nextCounter.writeAsString('$sequence', flush: true);
    await nextCounter.rename(counter.path);
    final temporary = File('${activation.folder.path}/.active-next');
    await temporary.writeAsString(
      jsonEncode({'version': activation.version, 'sequence': sequence}),
      flush: true,
    );
    _checkUser(activation.user);
    if (activation.refresh && (_leases[activation.user] ?? 0) > 0) {
      _waiting[activation.folder.path] = activation;
      return;
    }
    await temporary.rename(pointer.path);
    _loaded['${activation.folder.path}/.versions/${activation.version}'] =
        activation.files;
    if (activation.source case final source?) _source = source;
    ++_generation;
  }

  @override
  Future<String> read(String path) async {
    if (!isLessonContentPath(path)) throw ArgumentError.value(path, 'path');
    final user = _user();
    final root = await _root(user);
    String? selected;
    var newest = -1;
    if (await root.exists()) {
      await for (final entry in root.list()) {
        if (entry is! Directory || entry.path.split('/').last.startsWith('.')) {
          continue;
        }
        final content = await _committed(entry);
        if (content?[path] case final String text) {
          final pointer = File('${entry.path}/active');
          final raw = await pointer.exists()
              ? await pointer.readAsString()
              : '';
          final sequence = raw.startsWith('{')
              ? (jsonDecode(raw) as Map)['sequence'] as int
              : 0;
          if (sequence > newest) {
            newest = sequence;
            selected = text;
          }
        }
      }
    }
    if (selected != null) {
      _checkUser(user);
      return selected;
    }
    final text = await source.read(path);
    _checkUser(user);
    return text;
  }
}
