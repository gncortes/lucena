import 'package:freezed_annotation/freezed_annotation.dart';

part 'survey.freezed.dart';

/// Qual questionário: o das aulas de finais (2 passos) ou o da Escola
/// (3 passos). Vem da origem, a pessoa nunca escolhe.
enum SurveyKind {
  endgames,
  school;

  /// O nome na rota e nas chaves gravadas.
  String get code => name;

  static SurveyKind? byCode(String code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// O interesse num curso completo.
enum SurveyInterest {
  yes,
  maybe,
  no;

  static SurveyInterest? byCode(String? code) {
    for (final interest in values) {
      if (interest.name == code) return interest;
    }
    return null;
  }
}

/// Os ids estáveis dos chips (o texto vem do .arb).
abstract final class SurveyOptions {
  static const improveEndgames = [
    'viktor',
    'voice',
    'examples',
    'exercises',
    'boardMarks',
    'difficulty',
    'length',
  ];

  static const improveSchool = [
    'viktor',
    'voice',
    'examples',
    'exercises',
    'difficulty',
    'length',
    'notation',
  ];

  static const topics = [
    'solidOpenings',
    'aggressiveOpenings',
    'tactics',
    'positional',
    'endgames',
    'tournament',
    'annotatedGames',
  ];

  static const difficulties = [
    'afterOpening',
    'hangingPieces',
    'missTactics',
    'plan',
    'convertWin',
    'endgames',
    'clock',
  ];

  static List<String> improveOf(SurveyKind kind) => switch (kind) {
    SurveyKind.endgames => improveEndgames,
    SurveyKind.school => improveSchool,
  };
}

/// As respostas do questionário. O que não foi respondido fica nulo ou vazio.
@Freezed(fromJson: false, toJson: false)
abstract class SurveyAnswers with _$SurveyAnswers {
  const SurveyAnswers._();

  const factory SurveyAnswers({
    /// A nota, de 1 a 5.
    int? rating,
    @Default(<String>{}) Set<String> improve,
    String? improveText,
    SurveyInterest? interest,
    bool? reReview,
    String? wishText,
    @Default(<String>{}) Set<String> topics,
    @Default(<String>{}) Set<String> difficulties,
    String? difficultyText,
  }) = _SurveyAnswers;

  factory SurveyAnswers.fromJson(Map<String, Object?> json) => SurveyAnswers(
    rating: switch (json['rating']) {
      final int value when value >= 1 && value <= 5 => value,
      _ => null,
    },
    improve: _set(json['improve']),
    improveText: _text(json['improveText']),
    interest: SurveyInterest.byCode(json['interest'] as String?),
    reReview: json['reReview'] as bool?,
    wishText: _text(json['wishText']),
    topics: _set(json['topics']),
    difficulties: _set(json['difficulties']),
    difficultyText: _text(json['difficultyText']),
  );

  /// O máximo de caracteres de um texto livre.
  static const maxText = 500;

  /// Texto livre: corta em [maxText], tira as pontas; vazio vira nulo.
  static String? cleanText(String? text) {
    if (text == null) return null;
    final cut = text.length > maxText ? text.substring(0, maxText) : text;
    final trimmed = cut.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Set<String> _set(Object? value) => {
    if (value is List)
      for (final item in value)
        if (item is String) item,
  };

  static String? _text(Object? value) =>
      value is String ? SurveyAnswers.cleanText(value) : null;

  /// Os textos livres já limpos (corte em 500, `trim`, vazio vira nulo): o que
  /// vai na resposta enviada.
  SurveyAnswers get cleaned => copyWith(
    improveText: SurveyAnswers.cleanText(improveText),
    wishText: SurveyAnswers.cleanText(wishText),
    difficultyText: SurveyAnswers.cleanText(difficultyText),
  );

  Map<String, Object?> toJson() => {
    'rating': ?rating,
    'improve': improve.toList()..sort(),
    'improveText': ?improveText,
    'interest': ?interest?.name,
    'reReview': ?reReview,
    'wishText': ?wishText,
    'topics': topics.toList()..sort(),
    'difficulties': difficulties.toList()..sort(),
    'difficultyText': ?difficultyText,
  };
}

/// O questionário aberto e ainda não enviado: de qual [kind], em que [step]
/// (a partir de 0) e com o que já foi respondido.
class SurveyDraft {
  const SurveyDraft({
    required this.kind,
    required this.step,
    required this.answers,
  });

  factory SurveyDraft.fromJson(Map<String, Object?> json) {
    final kind = SurveyKind.byCode(json['kind'] as String? ?? '');
    final answers = json['answers'];
    if (kind == null || answers is! Map<String, Object?>) {
      throw const FormatException('rascunho inválido');
    }
    return SurveyDraft(
      kind: kind,
      step: json['step'] is int ? json['step'] as int : 0,
      answers: SurveyAnswers.fromJson(answers),
    );
  }

  final SurveyKind kind;
  final int step;
  final SurveyAnswers answers;

  Map<String, Object?> toJson() => {
    'v': 1,
    'kind': kind.code,
    'step': step,
    'answers': answers.toJson(),
  };
}

/// A resposta enviada, guardada no aparelho (a E1.03 define o envio).
class SurveyResponse {
  const SurveyResponse({
    required this.kind,
    required this.answers,
    required this.answeredAt,
  });

  factory SurveyResponse.fromJson(Map<String, Object?> json) {
    final kind = SurveyKind.byCode(json['kind'] as String? ?? '');
    final answers = json['answers'];
    final at = DateTime.tryParse(json['answeredAt'] as String? ?? '');
    if (kind == null || answers is! Map<String, Object?> || at == null) {
      throw const FormatException('resposta inválida');
    }
    return SurveyResponse(
      kind: kind,
      answers: SurveyAnswers.fromJson(answers),
      answeredAt: at,
    );
  }

  final SurveyKind kind;
  final SurveyAnswers answers;
  final DateTime answeredAt;

  Map<String, Object?> toJson() => {
    'v': 1,
    'kind': kind.code,
    'answers': answers.toJson(),
    'answeredAt': answeredAt.toUtc().toIso8601String(),
  };
}
