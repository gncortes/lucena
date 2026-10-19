import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/assessment_definition_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/use_cases/assessment_facts_provider.dart';

class _DefinitionBundle extends CachingAssetBundle {
  _DefinitionBundle(this.bytes);

  final Uint8List? bytes;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    reads++;
    final data = bytes;
    if (data == null) throw StateError('Missing synthetic asset');
    return ByteData.sublistView(data);
  }
}

const _path = 'assets/assessments/synthetic.json';
const _lesson = 'synthetic.lesson';
const _exercise = 'synthetic.exercise';

Map<String, Object?> _definition() {
  final sources = <String, Object?>{
    for (final key in [
      'item',
      'teaching',
      'proofManifest',
      'contract',
      'runtimeContract',
      'spec',
    ])
      key: 'a' * 64,
  };
  return {
    'schemaVersion': 1,
    'descriptorId': 'synthetic-descriptor',
    'factualVersion': AssessmentRuntimeFactsProvider.version,
    'assessmentVersion': 'u1-relations-v3-runtime',
    'lessonId': _lesson,
    'exerciseId': _exercise,
    // Deliberately not chess data: geometry is validated by the provider.
    'initialFen': 'synthetic-position',
    'student': 'white',
    'orientation': 'white',
    'supportedCorner': 'a1',
    'sourceHashes': sources,
    'contentIdentity': {
      ...sources,
      'factualVersion': AssessmentRuntimeFactsProvider.version,
      'assessmentVersion': 'u1-relations-v3-runtime',
    },
  };
}

Uint8List _bytes(Object? value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));

Future<AssessmentFactsDescriptor> _load(
  Uint8List? bytes, {
  String? expectedSha256,
  String path = _path,
  String lesson = _lesson,
  String exercise = _exercise,
}) =>
    AssetAssessmentDefinitionRepository(
      AssetService(_DefinitionBundle(bytes)),
    ).load(
      path: path,
      expectedSha256: expectedSha256 ?? sha256.convert(bytes ?? []).toString(),
      expectedLessonId: lesson,
      expectedExerciseId: exercise,
    );

Matcher _failure(String reason) => throwsA(
  isA<AssessmentDefinitionRepositoryException>().having(
    (error) => error.reason,
    'reason',
    reason,
  ),
);

void main() {
  test('authenticated definition returns immutable copied maps', () async {
    final input = _definition();
    final bytes = _bytes(input);
    final result = await _load(bytes);
    expect(result.descriptorId, 'synthetic-descriptor');
    expect(result.lessonId, _lesson);
    expect(result.exerciseId, _exercise);
    expect(result.student, Side.white);
    expect(result.orientation, Side.white);
    expect(result.initialFen, 'synthetic-position');
    (input['sourceHashes']! as Map<String, Object?>)['item'] = 'b' * 64;
    bytes.fillRange(0, bytes.length, 0);
    expect(result.sourceHashes['item'], 'a' * 64);
    expect(result.contentIdentity['item'], 'a' * 64);
    expect(
      () => result.sourceHashes['item'] = 'b' * 64,
      throwsUnsupportedError,
    );
    expect(() => result.contentIdentity.clear(), throwsUnsupportedError);
  });

  test(
    'exact byte pin rejects whitespace tampering before JSON parsing',
    () async {
      final bytes = _bytes(_definition());
      final pin = sha256.convert(bytes).toString();
      expect(
        _load(Uint8List.fromList([...bytes, 32]), expectedSha256: pin),
        _failure('hashMismatch'),
      );
      expect(
        _load(Uint8List.fromList([255]), expectedSha256: pin),
        _failure('hashMismatch'),
      );
    },
  );

  test('missing asset and invalid encodings fail technically', () async {
    expect(_load(null), _failure('malformedOrUnavailableDefinition'));
    for (final bytes in [
      Uint8List.fromList([255]),
      Uint8List.fromList(utf8.encode('{')),
      _bytes(null),
      _bytes([]),
    ]) {
      expect(_load(bytes), _failure('malformedOrUnavailableDefinition'));
    }
  });

  test('trusted inputs are checked before asset access', () async {
    final bundle = _DefinitionBundle(_bytes(_definition()));
    final repository = AssetAssessmentDefinitionRepository(
      AssetService(bundle),
    );
    for (final pin in ['', 'A' * 64, 'a' * 63]) {
      expect(
        repository.load(
          path: _path,
          expectedSha256: pin,
          expectedLessonId: _lesson,
          expectedExerciseId: _exercise,
        ),
        _failure('invalidTrustedInput'),
      );
    }
    expect(bundle.reads, 0);
    for (final path in [
      '../x.json',
      'assets/../x.json',
      'assets//x.json',
      'assets/x.txt',
    ]) {
      expect(_load(bundle.bytes, path: path), _failure('invalidTrustedInput'));
    }
    expect(_load(bundle.bytes, lesson: ' '), _failure('invalidTrustedInput'));
    expect(_load(bundle.bytes, exercise: ''), _failure('invalidTrustedInput'));
  });

  test(
    'authenticated definition must match both expected consumer IDs',
    () async {
      final bytes = _bytes(_definition());
      expect(_load(bytes, lesson: 'other'), _failure('consumerMismatch'));
      expect(_load(bytes, exercise: 'other'), _failure('consumerMismatch'));
    },
  );

  test(
    'required fields reject absent, empty and wrongly typed values',
    () async {
      for (final field in _definition().keys) {
        final missing = _definition()..remove(field);
        expect(
          _load(_bytes(missing)),
          _failure('malformedOrUnavailableDefinition'),
        );
        final wrongType = _definition()..[field] = [];
        expect(
          _load(_bytes(wrongType)),
          _failure('malformedOrUnavailableDefinition'),
        );
      }
      for (final field in [
        'descriptorId',
        'initialFen',
        'lessonId',
        'exerciseId',
      ]) {
        expect(
          _load(_bytes(_definition()..[field] = ' ')),
          _failure('malformedOrUnavailableDefinition'),
        );
      }
    },
  );

  test(
    'schema, supported versions, sides and corner syntax are strict',
    () async {
      for (final entry in <String, Object?>{
        'schemaVersion': 1.0,
        'factualVersion': 'future',
        'assessmentVersion': 'future',
        'student': 'White',
        'orientation': 0,
        'supportedCorner': 'b2',
      }.entries) {
        expect(
          _load(_bytes(_definition()..[entry.key] = entry.value)),
          _failure('malformedOrUnavailableDefinition'),
        );
      }
      expect(
        _load(_bytes(_definition()..['schemaVersion'] = 2)),
        _failure('malformedOrUnavailableDefinition'),
      );
      final black = await _load(
        _bytes(_definition()..['orientation'] = 'black'),
      );
      expect(black.orientation, Side.black);
    },
  );

  test(
    'source hashes and content identity must be complete and consistent',
    () async {
      final mutations = <void Function(Map<String, Object?>)>[
        (d) => (d['sourceHashes']! as Map).remove('spec'),
        (d) => (d['sourceHashes']! as Map)['item'] = 'A' * 64,
        (d) => (d['sourceHashes']! as Map)['item'] = 1,
        (d) => (d['sourceHashes']! as Map)[''] = 'a' * 64,
        (d) => (d['contentIdentity']! as Map)['item'] = 'b' * 64,
        (d) => (d['contentIdentity']! as Map).remove('item'),
        (d) => (d['contentIdentity']! as Map)['extra'] = 'a' * 64,
        (d) => (d['contentIdentity']! as Map)['factualVersion'] = 'other',
        (d) => (d['contentIdentity']! as Map)['assessmentVersion'] = 'other',
      ];
      for (final mutate in mutations) {
        final input = _definition();
        mutate(input);
        expect(
          _load(_bytes(input)),
          _failure('malformedOrUnavailableDefinition'),
        );
      }
    },
  );
}
