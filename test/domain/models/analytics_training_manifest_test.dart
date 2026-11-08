import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/analytics_event.dart';

import 'analytics_event_training_test.dart' show trainingAnalyticsSamples;

void main() {
  // tools/ belongs to lucena-utils and is linked in local working checkouts.
  // The app-only CI still runs factory/catalog tests without this optional tool.
  final available = File('tools/analytics/export_treino.dart').existsSync();
  test(
    'GA4 manifest matches app catalog and all training factories',
    () async {
      final manifest = jsonDecode(
        File('tools/analytics/treino_manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final events = manifest['events'] as Map<String, dynamic>;
      final samples = trainingAnalyticsSamples('pilares');
      expect(events.keys.toSet(), samples.map((e) => e.name).toSet());
      for (final event in samples) {
        expect(events[event.name], AnalyticsCatalog.app[event.name]);
        expect(events[event.name], containsAll(event.params.keys));
      }
      expect(manifest['dimensions'], contains('curso'));
      expect(manifest['metrics'], contains('tempo_s'));
      final result = await Process.run('dart', [
        'run',
        'tools/analytics/export_treino.dart',
        '--check',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    skip: available
        ? false
        : 'lucena-utils tooling not linked in this checkout',
  );
}
