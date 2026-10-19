import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/tablebase/exercise_judge_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/exercise_judge.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.bytes);
  final Uint8List bytes;
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(bytes);
}

void main() {
  const fen = '8/k1K5/3N4/8/8/8/8/5B2 w - - 0 1';
  const hash =
      '95507b845908630c15307c028e32b60eccfdaac52336bb97d95774f3bd60c10b';
  // Exact public API response copied from the cache declared by U1-e13.
  // Integrity is checked against these pinned original bytes, not a fake WDL.
  final raw = io.File(
    'test/data/repositories/tablebase/fixtures/e13.response.json',
  ).readAsBytesSync();
  final envelope = <String, Object>{
    'version': 1,
    'queryFen': fen,
    'source': Uri.https('tablebase.lichess.ovh', '/standard', {
      'fen': fen,
    }).toString(),
    'rawSha256': hash,
    'raw': utf8.decode(raw),
  };
  Future<bool> verify(Uint8List bytes, String digest) async =>
      digest == hash &&
      bytes.length == raw.length &&
      Iterable<int>.generate(raw.length).every((i) => bytes[i] == raw[i]);
  AssetExerciseJudgeRepository repository([Map<String, Object>? data]) =>
      AssetExerciseJudgeRepository.bytes(
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(data ?? envelope))),
        verify: verify,
        queryFen: fen,
        rawSha256: hash,
      );

  test(
    'real root and legal immediate children preserve FEN6 and perspective',
    () async {
      final provider = repository();
      final root = await provider.lookup(fen) as ExerciseKnown;
      expect(root.wdl, Wdl.win);
      expect(root.perspective, Side.white);
      expect(root.sourceSha256, hash);
      for (final move in ['d6c8', 'd6b5']) {
        final child = GameRules.play(
          GameRules.fromFen(fen)!,
          Move.parse(move)!,
        )!.position;
        final result = await provider.lookup(child.fen) as ExerciseKnown;
        expect(result.wdl, Wdl.loss);
        expect(result.perspective, Side.black);
        expect(result.fen, child.fen);
        for (final side in Side.values) {
          final judged = await ExerciseJudge(provider).evaluate(
            ExerciseJudgeRequest(
              initialFen: fen,
              fen: child.fen,
              student: side,
              played: [move],
              historyComplete: true,
            ),
          ) as ExerciseKnown;
          expect(judged.wdl, side == Side.white ? Wdl.win : Wdl.loss);
        }
      }
      final drawn = GameRules.play(
        GameRules.fromFen(fen)!,
        Move.parse('f1a6')!,
      )!.position;
      expect((await provider.lookup(drawn.fen) as ExerciseKnown).wdl, Wdl.draw);
    },
  );

  test('AssetService loads the same original proof bytes', () async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    final provider = AssetExerciseJudgeRepository(
      assets: AssetService(_Bundle(bytes)),
      path: 'proof.json',
      verify: verify,
      queryFen: fen,
      rawSha256: hash,
    );
    expect((await provider.lookup(fen) as ExerciseKnown).wdl, Wdl.win);
  });

  // SYNTHETIC NEGATIVES ONLY: corrupt response fields to exercise rejection
  // inside _result. Authentication is explicitly faked below, not WDL. These
  // payloads are not chess evidence and must never produce ExerciseKnown.
  for (final category in [
    'cursed-win',
    'blessed-loss',
    'maybe-win',
    'maybe-loss',
    'unknown',
    null,
  ]) {
    test('synthetic negative: unsupported category $category', () async {
      await expectSyntheticRejection(
        fen: fen,
        originalRaw: raw,
        category: category,
        dtz: 3,
        reason: 'unsupportedCategoryOrDtz',
      );
    });
  }

  test('synthetic negative: missing precise DTZ', () async {
    await expectSyntheticRejection(
      fen: fen,
      originalRaw: raw,
      category: 'win',
      dtz: null,
      reason: 'unsupportedCategoryOrDtz',
    );
  });

  for (final sample in [
    (category: 'win', dtz: -3),
    (category: 'win', dtz: 0),
    (category: 'loss', dtz: 3),
    (category: 'loss', dtz: 0),
    (category: 'draw', dtz: 3),
  ]) {
    test('synthetic negative: inconsistent DTZ sign $sample', () async {
      await expectSyntheticRejection(
        fen: fen,
        originalRaw: raw,
        category: sample.category,
        dtz: sample.dtz,
        reason: 'unprovedFiftyMoveConditions',
      );
    });
  }

  for (final sample in [
    (category: 'win', dtz: 3),
    (category: 'loss', dtz: -3),
  ]) {
    test(
      'synthetic negative: DTZ exceeds remaining fifty-move budget $sample',
      () async {
        await expectSyntheticRejection(
          fen: fen.replaceFirst('0 1', '99 1'),
          originalRaw: raw,
          category: sample.category,
          dtz: sample.dtz,
          reason: 'unprovedFiftyMoveConditions',
        );
      },
    );
  }

  test('unmatched clocks, missing proof, malformed bytes and provenance fail closed', () async {
    final provider = repository();
    expect(
      await provider.lookup(fen.replaceFirst('0 1', '1 1')),
      isA<ExerciseIndeterminate>(),
    );
    expect(
      await provider.lookup(fen.replaceFirst('0 1', '0 2')),
      isA<ExerciseIndeterminate>(),
    );
    for (final data in [
      {...envelope, 'rawSha256': '0' * 64},
      {...envelope, 'raw': '${envelope['raw']} '},
      {...envelope, 'version': 2},
      {
        ...envelope,
        'queryFen': fen.replaceFirst('0 1', '1 1'),
        'source': Uri.https('tablebase.lichess.ovh', '/standard', {
          'fen': fen.replaceFirst('0 1', '1 1'),
        }).toString(),
      },
      {...envelope, 'source': 'https://tablebase.lichess.ovh/standard?fen=bad'},
      <String, Object>{},
    ]) {
      expect(await repository(data).lookup(fen), isA<ExerciseIndeterminate>());
    }
    final bad = AssetExerciseJudgeRepository.bytes(
      bytes: Uint8List.fromList([1, 2]),
      verify: verify,
      queryFen: fen,
      rawSha256: hash,
    );
    expect(await bad.lookup(fen), isA<ExerciseIndeterminate>());
  });
}

Future<void> expectSyntheticRejection({
  required String fen,
  required Uint8List originalRaw,
  required String? category,
  required int? dtz,
  required String reason,
}) async {
  final response = jsonDecode(utf8.decode(originalRaw)) as Map<String, dynamic>;
  response['category'] = category;
  if (dtz == null) {
    response.remove('precise_dtz');
  } else {
    response['precise_dtz'] = dtz;
  }
  final syntheticRaw = jsonEncode(response);
  // Deliberate non-cryptographic placeholder, valid only for these rejection
  // tests. The production integrity boundary is replaced to reach _result.
  final fakeDigest = 'a' * 64;
  var authenticationCalls = 0;
  final provider = AssetExerciseJudgeRepository.bytes(
    bytes: Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'version': 1,
          'queryFen': fen,
          'source': Uri.https('tablebase.lichess.ovh', '/standard', {
            'fen': fen,
          }).toString(),
          'rawSha256': fakeDigest,
          'raw': syntheticRaw,
        }),
      ),
    ),
    queryFen: fen,
    rawSha256: fakeDigest,
    verify: (bytes, digest) async {
      authenticationCalls++;
      expect(bytes, orderedEquals(utf8.encode(syntheticRaw)));
      expect(digest, fakeDigest);
      return true; // Infrastructure fake only; never returns a WDL.
    },
  );
  final result = await provider.lookup(fen);
  expect(authenticationCalls, 1);
  // Only _result emits these reasons: this assertion rules out rejection at
  // the provenance/hash/JSON boundaries before the intended guard is reached.
  expect(
    result,
    isA<ExerciseIndeterminate>().having(
      (result) => result.reason,
      'reason from _result',
      reason,
    ),
  );
}
