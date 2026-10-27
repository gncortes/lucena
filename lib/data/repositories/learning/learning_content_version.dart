import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../services/asset_service.dart';
import '../../../domain/models/lesson_content.dart';

/// Fingerprint of the chapter definition, available scripts and PT/EN texts.
/// Missing optional content is explicit; transport failures abort observation, never mint a
/// plausible but incorrect version. No global cache survives content changes.
class LearningContentVersion {
  LearningContentVersion(this.assets);
  final AssetService assets;
  Future<String?> call(bool endgame, String id) async {
    try {
      final path = endgame
          ? 'assets/lessons/endgames/$id.json'
          : 'assets/lessons/course.json';
      final raw = await assets.loadString(path);
      var json = jsonDecode(raw);
      if (!endgame) {
        Object? find(Object? node) {
          if (node is Map) {
            if (node['id'] == id) return node;
            for (final value in node.values) {
              final match = find(value);
              if (match != null) return match;
            }
          } else if (node is List) {
            for (final value in node) {
              final match = find(value);
              if (match != null) return match;
            }
          }
          return null;
        }

        json = find(json);
        if (json == null) return null;
      }
      final files = <String, String>{path: jsonEncode(json)};
      final paths = <String>{
        for (final language in ['en', 'pt']) ...[
          if (endgame)
            'assets/lessons/$language/endgames/$id.json'
          else
            'assets/lessons/$language/lessons.json',
        ],
        if (!endgame) 'assets/lessons/roteiros/$id.json',
      };
      void scripts(Object? node) {
        if (node is Map) {
          if (node['roteiro'] case final String script) paths.add(script);
          for (final value in node.values) {
            scripts(value);
          }
        } else if (node is List) {
          for (final value in node) {
            scripts(value);
          }
        }
      }

      scripts(json);
      if (endgame && json is Map && json['parts'] is List) {
        for (final part in json['parts'] as List) {
          if (part is Map && part['id'] is String) {
            for (final language in ['en', 'pt']) {
              paths.add(
                'assets/lessons/$language/endgames/$id.${part['id']}.rot.json',
              );
            }
          }
        }
      }
      for (final path in paths.toList()..sort()) {
        try {
          files[path] = await assets.loadString(path);
        } on LessonContentNotFound {
          files[path] = '<absent>';
        }
      }
      if (!endgame) {
        final referenced = <String>{};
        void references(Object? node) {
          if (node is String) {
            referenced.add(node);
          } else if (node is Map) {
            for (final value in node.values) {
              references(value);
            }
          } else if (node is List) {
            for (final value in node) {
              references(value);
            }
          }
        }

        references(json);
        for (final entry in files.entries) {
          if (!entry.key.endsWith('/lessons.json') &&
              entry.value != '<absent>') {
            references(jsonDecode(entry.value));
          }
        }
        for (final language in ['en', 'pt']) {
          final textPath = 'assets/lessons/$language/lessons.json';
          final rawTexts = files[textPath];
          if (rawTexts == null || rawTexts == '<absent>') continue;
          final texts = jsonDecode(rawTexts) as Map<String, dynamic>;
          final keys =
              texts.keys
                  .where(
                    (key) => key.startsWith('$id.') || referenced.contains(key),
                  )
                  .toList()
                ..sort();
          files[textPath] = jsonEncode({
            for (final key in keys) key: texts[key],
          });
        }
      }
      return sha256.convert(utf8.encode(jsonEncode(files))).toString();
    } on Object {
      // Progress remains available when optional telemetry cannot be versioned.
      return null;
    }
  }
}
