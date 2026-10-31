@Tags(['private-content'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/use_cases/training/play_training_opening.dart';

void main() {
  final folder = Directory('assets/lessons/treino/aberturas');
  test(
    'all current repertoire parts compile, count unique student moves and finish',
    () {
      final checked = <String>{};
      for (final file in folder.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.json'),
      )) {
        final bank =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final raw in bank['trechos'] as List) {
          final part = OpeningTrecho.fromJson({
            'cor': bank['cor'],
            ...Map<String, dynamic>.from(raw as Map),
          });
          if (part.lines.isEmpty || !checked.add(part.id)) continue;
          final expected = <String>{};
          for (final line in part.lines) {
            for (var ply = part.black ? 1 : 0; ply < line.length; ply += 2) {
              expected.add(line.take(ply + 1).join(' '));
            }
          }
          final play = PlayTrainingOpening(part);
          expect(play.studentMoves, expected.length, reason: part.id);
          var cursor = play.initialCursor, attempts = 0;
          while (!play.isComplete(cursor)) {
            final step = play.play(cursor, play.acceptedAt(cursor).first);
            expect(step.correct, true, reason: part.id);
            cursor = step.cursor;
            attempts++;
          }
          expect(attempts, expected.length, reason: part.id);
        }
      }
      expect(checked.length, 38);
    },
    skip: !folder.existsSync()
        ? 'Private training content is not configured.'
        : false,
  );
}
