@Tags(['private-content'])
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/opening_trecho_rules.dart';
import 'package:lucena/domain/use_cases/training/play_training_opening.dart';

import '../../../../testing/fakes/fake_now.dart';

String boardState(String fen) => fen.split(' ').take(3).join(' ');

void finish(PlayTrainingOpening line, int cursor, String reason) {
  var remaining = 0;
  while (!line.isComplete(cursor)) {
    expect(remaining++, lessThan(1000), reason: reason);
    final result = line.play(cursor, line.acceptedAt(cursor).first);
    expect(result.correct, true, reason: reason);
    cursor = result.cursor;
  }
}

void main() {
  final root = io.Platform.environment['LUCENA_PRIVATE_ASSETS'];
  test(
    'every authored opening example compiles and all accepted paths finish',
    () {
      var examples = 0;
      var authoredQuestions = 0;
      var questionCandidatesPlayed = 0;
      var practiceExamples = 0;
      var practiceTurnsPlayed = 0;
      final scripts = io.Directory('$root/lessons/roteiros')
          .listSync(recursive: true)
          .whereType<io.File>()
          .where(
            (file) =>
                file.path.contains('pilares.ab') && file.path.endsWith('.json'),
          );
      for (final file in scripts) {
        final script =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final stage in script['etapas'] as List) {
          for (final raw in stage['exemplos'] as List) {
            final example = raw as Map<String, dynamic>;
            final trecho = OpeningTrecho.fromJson({
              'id': '${stage['id']}.${example['id']}',
              'titulo': '',
              'cor': example['vira'] == true ? 'pretas' : 'brancas',
              'fen': example['fen'],
              'exemplo': example,
            });
            final line = PlayTrainingOpening(trecho);
            final reason = '${file.path}/${trecho.id}';
            expect(line.studentMoves, greaterThan(0), reason: reason);
            final authoredQuestion = trecho.script!.question;
            if (authoredQuestion != null) {
              authoredQuestions++;
              expect(
                line.acceptedAt(line.initialCursor),
                unorderedEquals({
                  ...authoredQuestion.right,
                  ...authoredQuestion.alternatives.keys,
                }),
                reason: reason,
              );
              expect(
                boardState(line.fens[line.initialCursor]),
                boardState(trecho.script!.questionFen),
                reason: reason,
              );
            }
            final practice = trecho.script!.practice;
            if (practice != null) {
              practiceExamples++;
              expect(line.studentMoves, practice.line.length, reason: reason);
            }
            var cursor = line.initialCursor;
            var questions = 0;
            while (!line.isComplete(cursor)) {
              expect(line.questionIndex(cursor), questions, reason: reason);
              final accepted = line.acceptedAt(cursor);
              if (practice != null) {
                expect(
                  accepted,
                  practice.line[questions].right,
                  reason: reason,
                );
                practiceTurnsPlayed++;
              }
              // Validate each candidate independently, including terminal branches.
              for (final uci in accepted) {
                final branch = PlayTrainingOpening(trecho);
                var before = branch.initialCursor;
                while (before < cursor) {
                  before = branch
                      .play(before, branch.acceptedAt(before).first)
                      .cursor;
                }
                final played = GameRules.play(
                  GameRules.fromFen(branch.fens[cursor])!,
                  Move.parse(uci)!,
                )!;
                final result = branch.play(cursor, uci);
                expect(result.correct, true, reason: '$reason: $uci');
                expect(branch.moveAt(cursor), uci, reason: reason);
                expect(branch.san[cursor], played.san, reason: reason);
                expect(
                  boardState(branch.fens[cursor + 1]),
                  boardState(played.position.fen),
                  reason: reason,
                );
                if (authoredQuestion != null && questions == 0) {
                  questionCandidatesPlayed++;
                }
                finish(branch, result.cursor, '$reason: $uci');
                final results = List<bool>.filled(branch.studentMoves, true);
                final completed =
                    OpeningTrechoRules(FakeNow(DateTime(2026, 10, 29)))
                        .complete(
                          OpeningTrack(
                            lessonId: 'opening',
                            startedOn: '2026-10-28',
                          ),
                          trecho,
                          results,
                        );
                expect(completed.firstTry[trecho.id], results, reason: reason);
              }
              questions++;
              cursor = line.play(cursor, accepted.first).cursor;
            }
            expect(questions, line.studentMoves);
            examples++;
          }
        }
      }
      expect(examples, 457);
      expect(authoredQuestions, 67);
      expect(questionCandidatesPlayed, 70);
      expect(practiceExamples, 122);
      expect(practiceTurnsPlayed, 235);
    },
    skip: root == null
        ? 'Set LUCENA_PRIVATE_ASSETS to local authored assets'
        : false,
  );
}
