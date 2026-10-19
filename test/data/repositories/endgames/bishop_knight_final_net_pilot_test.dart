import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';

import '../../../../testing/fakes/fake_school_repositories.dart';

const _lessonId = 'mates.bishopKnight.deletang';
const _partId = 'finalNet';
const _scriptPath =
    'assets/lessons/roteiros/mates.bishopKnight.deletang/finalNet.json';

/// Real checkout files through the production asset repository; no engine mock.
class _CheckoutBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await io.File(key).readAsBytes());
}

/// Diagnostic registration only: the app's index/review assets stay unchanged.
/// Descriptor, texts and chapter are read unchanged from the real checkout.
class _DiagnosticReviewBundle extends _CheckoutBundle {
  @override
  Future<ByteData> load(String key) async {
    final fixture = switch (key) {
      AssetEndgameLessonRepository.indexPath => {
        'modules': [
          {
            'id': 'mates',
            'lessons': [_lessonId],
          },
        ],
      },
      AssetEndgameLessonRepository.reviewPath => {
        'lessons': [_lessonId],
        'failed': <String>[],
      },
      _ => null,
    };
    return fixture == null
        ? super.load(key)
        : ByteData.sublistView(utf8.encode(jsonEncode(fixture)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'pilot stays unregistered; diagnostic review fixture loads real assets',
    () async {
      final actualRepository = AssetEndgameLessonRepository(
        AssetService(_CheckoutBundle()),
        school: FakeLessonRepository(),
      );
      final actualTrail = await actualRepository.trail();
      expect(actualTrail.lesson(_lessonId), isNull);
      expect(VisibleLessons.trail(actualTrail).lesson(_lessonId), isNull);
      final review = jsonDecode(
        await io.File(AssetEndgameLessonRepository.reviewPath).readAsString(),
      ) as Map<String, dynamic>;
      expect(review['lessons'] as List, isNot(contains(_lessonId)));
      // Registration is a test fixture, not a change to the app catalogue.
      final repository = AssetEndgameLessonRepository(
        AssetService(_DiagnosticReviewBundle()),
        school: FakeLessonRepository(),
      );
      final trail = await repository.trail();
      final pilot = trail.lesson(_lessonId)!;
      expect(pilot.inReview, isTrue);
      expect(pilot.failed, isFalse); // No audit verdict has been invented.
      expect(pilot.lesson.parts.map((part) => part.id), [_partId]);
      expect(pilot.lesson.parts.single.script, _scriptPath);
      // Execution-only candidate remains outside the public catalogue.
      // This item does not certify the other two objectives of the chapter.
      expect(pilot.exercises.single.id, 'finalNetAssessment01');
      expect(pilot.exercises.single.completion, ExerciseCompletion.checkmate);
      expect(pilot.maxScore, 1);
      expect(pilot.passScore, pilot.maxScore);
      expect(VisibleLessons.trail(trail).lesson(_lessonId), isNull);
      expect(VisibleLessons.endgameLessonIds, isNot(contains(_lessonId)));
      final texts = await repository.texts('pt');
      expect(texts.lessonTitle(_lessonId), isNot(_lessonId));
    },
  );

  test(
    'native script resolves every authored PT key and preserves the route',
    () async {
      final repository = AssetLessonScriptRepository(
        AssetService(_CheckoutBundle()),
      );
      final script = await repository.script(_scriptPath);
      final texts = await repository.texts(_lessonId, 'pt');
      expect(script.lessonId, _lessonId);
      expect(script.partId, _partId);
      expect(script.stages.map((stage) => stage.id), [
        'ideia',
        'demos',
        'pratica',
      ]);
      expect(script.stages.map((stage) => stage.examples.length), [2, 1, 1]);
      final used = <String>{};
      for (final stage in script.stages) {
        for (final example in stage.examples) {
          expect(example.flip, isFalse);
          expect(example.student, Side.white);
          expect(example.goal, ScriptGoal.mate);
          var position = GameRules.fromFen(example.fen)!;
          for (final step in [...example.entry, ...example.line]) {
            for (final uci in step.moves) {
              final played = GameRules.play(position, Move.parse(uci)!);
              expect(played, isNotNull, reason: '$stage/${example.id}/$uci');
              position = played!.position;
            }
            expect(position.fen, step.fen); // Includes all six FEN fields.
            used.add(step.t);
          }
          final practice = example.practice;
          if (practice != null) {
            used.add(practice.t);
            used.add(practice.end!);
            used.addAll(practice.ends.values);
            expect(practice.kind, PracticeKind.jogo);
            expect(practice.machine, Side.black);
            expect(
              practice.line,
              isEmpty,
            ); // No restrictive accepted-move list.
            expect(practice.errors, isEmpty);
            expect(practice.errorsAt, isEmpty);
            expect(example.entry, isEmpty);
            expect(example.line, isEmpty);
          }
        }
      }
      expect(used, hasLength(19));
      for (final key in used) {
        expect(key, startsWith('rot.finalNet.'));
        expect(texts.say(key), isNot(key), reason: key);
        expect(texts.say(key).trim(), isNotEmpty, reason: key);
      }
      final preparation = script.stages.first.examples.last;
      final conclusion = script.stages[1].examples.single;
      expect(conclusion.fen, preparation.line.last.fen);
      final practice = script.stages.last.examples.single;
      expect(practice.id, 'transfer01');
      final shown = {
        for (final stage in script.stages.take(2))
          for (final example in stage.examples) ...[
            example.fen,
            ...example.entry.map((step) => step.fen),
            ...example.line.map((step) => step.fen),
          ],
      };
      expect(shown, isNot(contains(practice.fen)));
    },
  );

  test(
    'both frozen instructional lines end in real mate with the student winner',
    () async {
      final repository = AssetLessonScriptRepository(
        AssetService(_CheckoutBundle()),
      );
      final script = await repository.script(_scriptPath);
      final e13 = script.stages.first.examples.first;
      final e15 = script.stages.first.examples.last;
      final conclusion = script.stages[1].examples.single;
      for (final (fen, steps) in [
        (e13.fen, e13.line),
        (e15.fen, [...e15.line, ...conclusion.line]),
      ]) {
        var position = GameRules.fromFen(fen)!;
        for (final step in steps) {
          for (final uci in step.moves) {
            position = GameRules.play(position, Move.parse(uci)!)!.position;
          }
        }
        expect(position.isCheckmate, isTrue);
        expect(GameRules.endOf(position, repetitions: 1)?.winner, Side.white);
      }
    },
  );

  test(
    'Flutter bundle registers the chapter and all PT chapter text',
    () async {
      final repository = AssetLessonScriptRepository(const AssetService());
      final script = await repository.script(_scriptPath);
      final pt = await repository.texts(_lessonId, 'pt');
      final raw = jsonDecode(
        await rootBundle.loadString(
          'assets/lessons/pt/endgames/$_lessonId.$_partId.rot.json',
        ),
      ) as Map<String, dynamic>;
      expect(script.partId, _partId);
      for (final key in raw.keys) {
        expect(pt.say(key), raw[key], reason: key);
      }
    },
  );

  test(
    'independent practice short line legally mates without a move whitelist',
    () async {
      final repository = AssetLessonScriptRepository(
        AssetService(_CheckoutBundle()),
      );
      final script = await repository.script(_scriptPath);
      final example = script.stages.last.examples.single;
      expect(example.id, 'transfer01');
      expect(example.fen, '8/k1K5/1N6/8/8/8/4B3/8 w - - 0 1');
      expect(example.practice!.line, isEmpty);
      expect(example.practice!.errors, isEmpty);
      expect(example.practice!.errorsAt, isEmpty);
      expect(example.entry, isEmpty);
      expect(example.line, isEmpty);
      var position = GameRules.fromFen(example.fen)!;
      expect(position.isCheckmate, isFalse);
      for (final uci in ['b6c8', 'a7a8', 'e2f3']) {
        final played = GameRules.play(position, Move.parse(uci)!);
        expect(played, isNotNull, reason: uci);
        position = played!.position;
      }
      expect(position.isCheckmate, isTrue);
      expect(
        GameRules.endOf(position, repetitions: 1)?.winner,
        example.student,
      );
    },
  );
}
