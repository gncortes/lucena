import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/domain/models/exercise_error_feedback.dart';

class _Assets extends AssetService {
  _Assets(this.data);
  final Map<String, dynamic> data;
  int reads = 0;
  @override
  Future<String> loadString(String path) async {
    reads++;
    return jsonEncode(data);
  }
}

void main() {
  test(
    'review namespaces parent and context across decisions with local IDs',
    () async {
      const origin = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
      final root = ExplanationVariation(
        id: 'A',
        label: 'A',
        outcome: VariationOutcome.accepted,
        texts: const [],
        originFen: origin,
        movesUci: ['d2d4'],
        movesSan: ['1.d4'],
        validated: true,
      );
      final data = {
        'lesson': 'lesson',
        'positions': [
          for (final turn in [1, 2])
            {
              'kind': 'exercise',
              'id': 'e',
              'turn': turn,
              'fen': origin,
              'explanations': {
                'en': {
                  'positionId': 'exercise/e.$turn',
                  'state': 'review',
                  'explanations': [
                    {
                      'id': 'main',
                      'kind': 'main_solution',
                      'variations': [
                        {
                          'id': 'A',
                          'label': 'A',
                          'contextId': 'local',
                          'outcome': 'accepted',
                          'originFen': origin,
                          'movesUci': ['d2d4'],
                          'movesSan': ['1.d4'],
                          'validated': true,
                        },
                        {
                          'id': 'A.1',
                          'label': 'A.1',
                          'contextId': 'local',
                          'parentId': 'A',
                          'parentPly': 1,
                          'outcome': 'accepted',
                          'originFen': root.open()!.fen,
                          'movesUci': ['g8f7'],
                          'movesSan': ['1...Kf7'],
                          'validated': true,
                        },
                      ],
                    },
                  ],
                },
              },
            },
        ],
      };
      final repo = AssetExerciseFeedbackRepository(_Assets(data));
      final review = (await repo.findExerciseReview(
        lessonId: 'lesson',
        exerciseId: 'e',
        language: 'en',
      ))!;
      expect(review.variations, hasLength(4));
      for (final turn in [1, 2]) {
        final child = review.variations.singleWhere(
          (v) => v.id == 'exercise/e.$turn:A.1',
        );
        expect(child.label, 'A.1');
        expect(child.parentId, 'exercise/e.$turn:A');
        expect(child.contextId, 'exercise/e.$turn:local');
        expect(child.parentPly, 1);
        expect(review.openVariation(child), isNotNull);
        expect(review.parentCursor(child)!.variation.id, 'exercise/e.$turn:A');
      }
      final positions = data['positions'] as List;
      ((positions.last as Map)['explanations']['en'] as Map)['positionId'] =
          'exercise/e.1';
      final ambiguous = AssetExerciseFeedbackRepository(_Assets(data));
      expect(
        await ambiguous.findExerciseReview(
          lessonId: 'lesson',
          exerciseId: 'e',
          language: 'en',
        ),
        isNull,
      );
    },
  );
  test('existing pilot legacy rows still supply contextual feedback', () async {
    const id = 'pawns.distantOpposition';
    final json = jsonDecode(
      File(AssetExerciseFeedbackRepository.assetPath(id)).readAsStringSync(),
    ) as Map<String, dynamic>;
    final rows = (json['rows'] as List).cast<Map<String, dynamic>>();
    for (final row in rows) {
      ExerciseErrorFeedback.fromJson(id, row);
    }
    final row = rows.first;
    final repository = AssetExerciseFeedbackRepository(
      _Assets({'lesson': id, 'rows': rows}),
    );
    Future<ExplanationPayload?> throughBase(
      ExerciseFeedbackRepository repository,
    ) => repository.findPayload(
      lessonId: id,
      exerciseId: row['id'] as String,
      kind: row['kind'] as String,
      turn: row['turn'] as int,
      fen: row['fen'] as String,
      language: 'pt',
      state: ExplanationState.incorrect,
      playedUci: row['uci'] as String,
    );
    final result = await throughBase(repository);
    expect(result, isNotNull);
    expect(result!.explanations.expand((b) => b.texts), [row['pt']]);
  });
  test(
    'real e14 review keeps every decision in turn order with unique ids',
    () async {
      const lessonId = 'pawns.distantOpposition';
      final data = jsonDecode(
        File(AssetExerciseFeedbackRepository.assetPath(lessonId))
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final assets = _Assets(data);
      ExerciseFeedbackRepository repository = AssetExerciseFeedbackRepository(
        assets,
      );
      final review = (await repository.findExerciseReview(
        lessonId: lessonId,
        exerciseId: 'e14',
        language: 'pt',
      ))!;
      final solutions = review.explanations
          .where((b) => b.kind == ExplanationKind.mainSolution)
          .toList();
      expect(solutions.length, 7);
      expect(
        solutions.map((b) => b.id),
        List.generate(7, (i) => 'exercise/e14.${i + 1}:main_solution'),
      );
      final blockIds = review.explanations.map((b) => b.id).toList();
      final variants = review.explanations.expand((b) => b.variations).toList();
      expect(blockIds.toSet().length, blockIds.length);
      expect(variants.map((v) => v.id).toSet().length, variants.length);
      final positions =
          (data['positions'] as List)
              .cast<Map<String, dynamic>>()
              .where((p) => p['kind'] == 'exercise' && p['id'] == 'e14')
              .toList()
            ..sort((a, b) => (a['turn'] as int).compareTo(b['turn'] as int));
      for (var turn = 0; turn < positions.length; turn++) {
        final authored = ExplanationPayload.fromJson(
          Map<String, dynamic>.from(positions[turn]['explanations']['pt']),
        );
        final originals = authored.explanations
            .singleWhere((b) => b.kind == ExplanationKind.mainSolution)
            .variations;
        expect(solutions[turn].variations.length, originals.length);
        for (final original in originals) {
          final namespace = authored.positionId;
          final line = solutions[turn].variations.singleWhere(
            (v) => v.id == '$namespace:${original.id}',
          );
          expect(line.originFen, original.originFen);
          expect(line.movesUci, original.movesUci);
          expect(line.movesSan, original.movesSan);
          expect(line.texts, original.texts);
          expect(line.explanationByPly, original.explanationByPly);
          expect(line.outcome, original.outcome);
          expect(
            line.parentId,
            original.parentId == null
                ? null
                : '$namespace:${original.parentId}',
          );
          expect(line.parentPly, original.parentPly);
          expect(review.openVariation(line), isNotNull);
        }
      }
      final again = await repository.findExerciseReview(
        lessonId: lessonId,
        exerciseId: 'e14',
        language: 'pt',
      );
      expect(again!.explanations.map((b) => b.id), blockIds);
      expect(assets.reads, 1);
      expect(
        await const EmptyExerciseFeedbackRepository().findExerciseReview(
          lessonId: lessonId,
          exerciseId: 'e14',
          language: 'pt',
        ),
        isNull,
      );
    },
  );

  test('all real counterexamples keep authored consequence separately from reply outcome', () async {
    const lessonId = 'pawns.distantOpposition';
    final data = jsonDecode(
      File(AssetExerciseFeedbackRepository.assetPath(lessonId))
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final repository = AssetExerciseFeedbackRepository(_Assets(data));
    final positions = (data['positions'] as List)
        .cast<Map<String, dynamic>>()
        .where((p) => (p['id'] as String).startsWith('err_'))
        .toList();
    expect(positions.length, 17);
    for (final position in positions) {
      for (final language in ['pt', 'en']) {
        final payload = (await repository.findPayload(
          lessonId: lessonId,
          exerciseId: position['id'],
          kind: position['kind'],
          turn: position['turn'],
          fen: position['fen'],
          language: language,
          state: ExplanationState.review,
        ))!;
        final block = payload.explanations.singleWhere(
          (b) => b.variations.isNotEmpty,
        );
        expect(
          block.title,
          language == 'pt'
              ? 'Por que a tentativa anterior falha'
              : 'Why the previous attempt fails',
        );
        final variant = block.variations.single;
        expect(variant.outcomeText, variant.texts.first);
        expect(
          variant.outcomeText,
          startsWith(
            language == 'pt'
                ? 'Refutação da tentativa anterior:'
                : 'Refutation of the previous attempt:',
          ),
        );
      }
    }
  });

  const fen = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
  final payload = {
    'positionId': 'p',
    'state': 'review',
    'explanations': [
      {
        'id': 'context',
        'kind': 'context',
        'texts': ['First.', 'Second.'],
      },
      {
        'id': 'main',
        'kind': 'main_solution',
        'texts': ['Main.'],
      },
      {
        'id': 'failed',
        'kind': 'failed_alternatives',
        'variations': [
          {
            'id': 'error',
            'label': '1.Kh2',
            'outcome': 'does_not_meet_goal',
            'texts': ['Authored reason.', 'Consequence.'],
            'originFen': fen,
            'movesUci': ['h1h2'],
            'movesSan': ['Kh2'],
            'validated': true,
          },
        ],
      },
    ],
  };

  test('exact position, fallback English, arrays and authored precedence over legacy rows', () async {
    final assets = _Assets({
      'lesson': 'lesson',
      'positions': [
        {
          'kind': 'think',
          'id': 'decision',
          'turn': 1,
          'fen': fen,
          'explanations': {'en': payload},
        },
      ],
      'rows': [
        {
          'kind': 'move',
          'id': 'decision',
          'turn': 1,
          'fen': fen,
          'uci': 'h1h2',
          'en': 'Legacy.',
        },
      ],
    });
    final repository = AssetExerciseFeedbackRepository(assets);
    Future<ExplanationPayload?> lookup({
      String position = fen,
      String kind = 'think',
      int turn = 1,
      ExplanationState state = ExplanationState.incorrect,
    }) => repository.findPayload(
      lessonId: 'lesson',
      exerciseId: 'decision',
      kind: kind,
      turn: turn,
      fen: position,
      language: 'es',
      state: state,
      playedUci: 'h1h2',
    );
    final result = (await lookup())!;
    expect(result.explanations.first.kind, ExplanationKind.playedIncorrect);
    expect(result.explanations.first.texts, [
      'Authored reason.',
      'Consequence.',
    ]);
    expect(
      result.explanations.first.variations.single.outcome,
      VariationOutcome.doesNotMeetGoal,
    );
    expect(
      result.explanations.expand((b) => b.texts),
      isNot(contains('Legacy.')),
    );
    expect(
      (await lookup(state: ExplanationState.intro))!.explanations.single.texts,
      ['First.', 'Second.'],
    );
    expect(await lookup(position: fen.replaceFirst('0 1', '1 1')), isNull);
    expect(await lookup(turn: 2), isNull);
    expect(await lookup(kind: 'demo'), isNull);
    expect(assets.reads, 1);
  });

  test('legacy row preserves PV, objective/evidence and paragraph arrays without validating implicitly', () {
    final row = ExerciseErrorFeedback.fromJson('lesson', {
      'kind': 'move',
      'id': 'd',
      'turn': 1,
      'fen': fen,
      'uci': 'd2d3',
      'pt': ['Primeiro.', 'Segundo.'],
      'en': 'Fallback.',
      'pv': [
        {
          'fen': fen,
          'uci': 'd2d3',
          'san': 'd3',
          'turn': 'white',
          'fullmove': 1,
        },
      ],
      'objective': {'result_mover': 'draw'},
      'evidence': {'file': 'proof.json'},
    });
    expect(row.payload('pt')!.explanations.single.texts, [
      'Primeiro.',
      'Segundo.',
    ]);
    expect(row.pv.single['uci'], 'd2d3');
    expect(row.objective['result_mover'], 'draw');
    expect(row.evidence['file'], 'proof.json');
    expect(row.payload('pt')!.explanations.single.variations, isEmpty);
    expect(row.text('es'), 'Fallback.');
  });
}
