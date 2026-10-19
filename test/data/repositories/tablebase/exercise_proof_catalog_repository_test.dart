import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/tablebase/exercise_proof_catalog_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/exercise_judge.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

import '../../../../testing/test_dependencies.dart';

class _CatalogBundle extends CachingAssetBundle {
  _CatalogBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final value = files[key];
    if (value == null) throw StateError('Missing test asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

void main() {
  const fen = '8/k1K5/3N4/8/8/8/8/5B2 w - - 0 1';
  const hash =
      '95507b845908630c15307c028e32b60eccfdaac52336bb97d95774f3bd60c10b';
  const manifestPath = AssetExerciseProofCatalogRepository.defaultPath;
  const proofPath = 'assets/tablebase/exercises/e13.json';
  final raw = io.File(
    'test/data/repositories/tablebase/fixtures/e13.response.json',
  ).readAsStringSync();
  final entry = <String, Object>{
    'path': proofPath,
    'queryFen': fen,
    'rawSha256': hash,
  };
  final envelope = <String, Object>{
    'version': 1,
    'queryFen': fen,
    'source': Uri.https('tablebase.lichess.ovh', '/standard', {
      'fen': fen,
    }).toString(),
    'rawSha256': hash,
    'raw': raw,
  };
  Map<String, String> files() => {
    manifestPath: jsonEncode({
      'version': 1,
      'entries': [entry],
    }),
    proofPath: jsonEncode(envelope),
  };
  AssetExerciseProofCatalogRepository catalog(Map<String, String> data) =>
      AssetExerciseProofCatalogRepository(
        AssetService(_CatalogBundle(data)),
        path: manifestPath,
      );
  Matcher indeterminate(String reason) => isA<ExerciseIndeterminate>().having(
    (value) => value.reason,
    'reason',
    reason,
  );

  test(
    'real SHA256 verifies public e13 root and legally clocked child',
    () async {
      final provider = catalog(files());
      final root = await provider.lookup(fen) as ExerciseKnown;
      expect(root.wdl, Wdl.win);
      expect(root.perspective, Side.white);
      expect(root.sourceSha256, hash);
      final child = GameRules.play(
        GameRules.fromFen(fen)!,
        Move.parse('d6c8')!,
      )!.position;
      final result = await provider.lookup(child.fen) as ExerciseKnown;
      expect(result.wdl, Wdl.loss);
      expect(result.perspective, Side.black);
      expect(result.fen, child.fen);
    },
  );

  test(
    'real SHA256 rejects tampered bytes despite unchanged provenance',
    () async {
      final data = files();
      data[proofPath] = jsonEncode({...envelope, 'raw': '$raw '});
      expect(
        await catalog(data).lookup(fen),
        indeterminate('proofHashMismatch'),
      );
    },
  );

  test(
    'missing manifest and envelope fail without a fabricated result',
    () async {
      expect(
        await catalog({}).lookup(fen),
        indeterminate('proofCatalogUnavailable'),
      );
      final data = files()..remove(proofPath);
      expect(
        await catalog(data).lookup(fen),
        indeterminate('malformedOrUnavailableProof'),
      );
    },
  );

  test('malformed catalog and envelope remain indeterminate', () async {
    for (final malformed in [
      '{',
      'null',
      '{"version":2,"entries":[]}',
      '{"version":1,"entries":{}}',
    ]) {
      final data = files()..[manifestPath] = malformed;
      expect(
        await catalog(data).lookup(fen),
        indeterminate('proofCatalogUnavailable'),
      );
    }
    final data = files()..[proofPath] = '{';
    expect(
      await catalog(data).lookup(fen),
      indeterminate('malformedOrUnavailableProof'),
    );
  });

  test('unmatched FEN6 clocks and empty catalog have no exact proof', () async {
    expect(
      await catalog(files()).lookup(fen.replaceFirst('0 1', '1 1')),
      indeterminate('noExactProof'),
    );
    expect(
      await catalog({manifestPath: '{"version":1,"entries":[]}'}).lookup(fen),
      indeterminate('noExactProof'),
    );
    expect(await catalog(files()).lookup('bad'), indeterminate('invalidFen6'));
  });

  test(
    'duplicate and conflicting manifest pins are rejected as a whole',
    () async {
      for (final duplicate in [
        entry,
        {...entry, 'path': 'assets/tablebase/exercises/duplicate.json'},
        {
          ...entry,
          'path': 'assets/tablebase/exercises/conflict.json',
          'rawSha256': '0' * 64,
        },
      ]) {
        final data = files();
        data[manifestPath] = jsonEncode({
          'version': 1,
          'entries': [entry, duplicate],
        });
        expect(
          await catalog(data).lookup(fen),
          indeterminate('proofCatalogUnavailable'),
        );
      }
    },
  );

  test('invalid manifest pins and asset paths are rejected', () async {
    for (final invalid in [
      {...entry, 'path': '../e13.json'},
      {...entry, 'path': 'assets/../e13.json'},
      {...entry, 'queryFen': 'bad'},
      {...entry, 'rawSha256': 'not-a-digest'},
    ]) {
      final data = files();
      data[manifestPath] = jsonEncode({
        'version': 1,
        'entries': [invalid],
      });
      expect(
        await catalog(data).lookup(fen),
        indeterminate('proofCatalogUnavailable'),
      );
    }
  });

  test('legacy dependency composition keeps the strict port optional', () {
    expect(testDependencies().exerciseJudge, isNull);
  });
}
