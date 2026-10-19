import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';

import '../../../domain/use_cases/assessment_facts_provider.dart';
import '../../services/asset_service.dart';

/// A technical failure loading a trusted assessment definition. No fallback is
/// provided, and asset content is never included in the diagnostic.
final class AssessmentDefinitionRepositoryException implements Exception {
  const AssessmentDefinitionRepositoryException(this.reason);

  final String reason;

  @override
  String toString() => 'AssessmentDefinitionRepositoryException: $reason';
}

/// Authenticates exact asset bytes against a pin supplied by a trusted caller.
/// Source hashes identify content; they do not independently authenticate it.
final class AssetAssessmentDefinitionRepository {
  const AssetAssessmentDefinitionRepository(this._assets);

  final AssetService _assets;

  Future<AssessmentFactsDescriptor> load({
    required String path,
    required String expectedSha256,
    required String expectedLessonId,
    required String expectedExerciseId,
  }) async {
    if (!_assetPath(path) ||
        !_hash.hasMatch(expectedSha256) ||
        expectedLessonId.trim().isEmpty ||
        expectedExerciseId.trim().isEmpty) {
      throw const AssessmentDefinitionRepositoryException(
        'invalidTrustedInput',
      );
    }
    try {
      final bytes = await _assets.loadBytes(path);
      // Authentication must precede UTF-8 decoding and JSON parsing.
      if (sha256.convert(bytes).toString() != expectedSha256) {
        throw const AssessmentDefinitionRepositoryException('hashMismatch');
      }
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic>) {
        throw const FormatException();
      }
      if (value['schemaVersion'] is! int || value['schemaVersion'] != 1) {
        throw const FormatException();
      }
      final descriptorId = _string(value['descriptorId']);
      final factualVersion = _string(value['factualVersion']);
      final assessmentVersion = _string(value['assessmentVersion']);
      final lessonId = _string(value['lessonId']);
      final exerciseId = _string(value['exerciseId']);
      final initialFen = _string(value['initialFen']);
      final student = _side(value['student']);
      final orientation = _side(value['orientation']);
      final supportedCorner = _string(value['supportedCorner']);
      final sourceHashes = _strings(value['sourceHashes']);
      final contentIdentity = _strings(value['contentIdentity']);
      if (lessonId != expectedLessonId || exerciseId != expectedExerciseId) {
        throw const AssessmentDefinitionRepositoryException('consumerMismatch');
      }
      if (factualVersion != AssessmentRuntimeFactsProvider.version ||
          assessmentVersion != 'u1-relations-v3-runtime' ||
          !const ['a1', 'a8', 'h1', 'h8'].contains(supportedCorner) ||
          !_requiredSources.every(sourceHashes.containsKey) ||
          sourceHashes.entries.any(
            (entry) =>
                !_hash.hasMatch(entry.value) ||
                contentIdentity[entry.key] != entry.value,
          ) ||
          contentIdentity.length != sourceHashes.length + 2 ||
          contentIdentity['factualVersion'] != factualVersion ||
          contentIdentity['assessmentVersion'] != assessmentVersion) {
        throw const FormatException();
      }
      // FEN legality, material and supported-corner geometry belong to the
      // runtime facts provider, not to this serialization boundary.
      return AssessmentFactsDescriptor(
        descriptorId: descriptorId,
        factualVersion: factualVersion,
        assessmentVersion: assessmentVersion,
        lessonId: lessonId,
        exerciseId: exerciseId,
        initialFen: initialFen,
        student: student,
        orientation: orientation,
        supportedCorner: supportedCorner,
        contentIdentity: contentIdentity,
        sourceHashes: sourceHashes,
      );
    } on AssessmentDefinitionRepositoryException {
      rethrow;
    } on Object {
      throw const AssessmentDefinitionRepositoryException(
        'malformedOrUnavailableDefinition',
      );
    }
  }

  static final _hash = RegExp(r'^[0-9a-f]{64}$');
  static const _requiredSources = [
    'item',
    'teaching',
    'proofManifest',
    'contract',
    'runtimeContract',
    'spec',
  ];

  static bool _assetPath(String path) =>
      path.startsWith('assets/') &&
      path.endsWith('.json') &&
      !path.contains('\\') &&
      !path
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..');

  static String _string(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException();
    }
    return value;
  }

  static Map<String, String> _strings(Object? value) {
    if (value is! Map<String, dynamic>) throw const FormatException();
    return {
      for (final entry in value.entries)
        _string(entry.key): _string(entry.value),
    };
  }

  static Side _side(Object? value) => switch (value) {
    'white' => Side.white,
    'black' => Side.black,
    _ => throw const FormatException(),
  };
}
