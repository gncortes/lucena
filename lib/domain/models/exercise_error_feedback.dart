import 'explanation.dart';

/// A frozen explanation supplied by lesson authors for one rejected move.
/// Used by both exercises and move steps; it never evaluates moves.
class ExerciseErrorFeedback {
  ExerciseErrorFeedback({
    required this.lessonId,
    required this.exerciseId,
    required this.kind,
    required this.turn,
    required this.fen,
    required this.uci,
    required Map<String, String> texts,
    this.payloads = const {},
    this.paragraphs = const {},
    this.pv = const [],
    this.objective = const {},
    this.evidence = const {},
  }) : texts = Map.unmodifiable(texts);

  final Map<String, ExplanationPayload> payloads;
  final Map<String, List<String>> paragraphs;
  final List<Map<String, dynamic>> pv;
  final Map<String, dynamic> objective, evidence;
  ExplanationPayload? payload(String language) =>
      payloads[language] ??
      payloads['en'] ??
      ExplanationPayload.context(
        paragraphs[language] ?? paragraphs['en'] ?? [?text(language)],
      );

  final String lessonId;

  /// Authored row id: exercise id for `exercise`, step id for `move`.
  final String exerciseId;
  final String kind;
  final int turn;
  final String fen;
  final String uci;
  final Map<String, String> texts;

  factory ExerciseErrorFeedback.fromJson(
    String lessonId,
    Map<String, dynamic> row,
  ) {
    if ((row['kind'] != 'exercise' && row['kind'] != 'move') ||
        row['turn'] is! int ||
        (row['turn'] as int) < 1) {
      throw const FormatException('Invalid feedback decision');
    }
    final fen = row['fen'] as String;
    if (positionKey(fen) == null) {
      throw const FormatException('Invalid feedback FEN');
    }
    return ExerciseErrorFeedback(
      lessonId: lessonId,
      exerciseId: row['id'] as String,
      kind: row['kind'] as String,
      turn: row['turn'] as int,
      fen: fen,
      uci: row['uci'] as String,
      payloads: {
        for (final e in ((row['explanations'] as Map?) ?? {}).entries)
          e.key as String: ExplanationPayload.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          ),
      },
      paragraphs: {
        for (final language in const ['pt', 'en'])
          language: explanationTexts(row[language]),
      },
      pv: [
        for (final v in row['pv'] as List? ?? [])
          Map<String, dynamic>.unmodifiable(v as Map),
      ],
      objective: Map<String, dynamic>.unmodifiable(
        row['objective'] as Map? ?? {},
      ),
      evidence: Map<String, dynamic>.unmodifiable(
        row['evidence'] as Map? ?? {},
      ),
      texts: {
        for (final language in const ['pt', 'en'])
          if (row[language] is String) language: row[language] as String,
      },
    );
  }

  /// The full authoring FEN, including both counters. Only whitespace is
  /// canonicalized; incomplete runtime FENs intentionally have no match.
  static String? positionKey(String fen) {
    final fields = fen.trim().split(RegExp(r'\s+'));
    if (fields.length != 6 ||
        (fields[1] != 'w' && fields[1] != 'b') ||
        fields[0].split('/').length != 8 ||
        (int.tryParse(fields[4]) ?? -1) < 0 ||
        (int.tryParse(fields[5]) ?? 0) < 1) {
      return null;
    }
    return fields.join(' ');
  }

  bool matches({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String uci,
  }) =>
      positionKey(fen) != null &&
      this.lessonId == lessonId &&
      this.exerciseId == exerciseId &&
      this.kind == kind &&
      this.turn == turn &&
      this.uci == uci &&
      positionKey(this.fen) == positionKey(fen);

  /// Match the lesson text repository's English fallback for other languages.
  String? text(String language) => texts[language] ?? texts['en'];
}
