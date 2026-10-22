/// Sim, talvez ou não: o curso (passo 1) e o treinador (passo 2) do "Você
/// pagaria?" (E1.26).
enum WouldPayAnswer {
  yes,
  maybe,
  no;

  /// O código gravado e mandado (estável, não o texto).
  String get code => name;

  static WouldPayAnswer? byCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// A faixa de preço do curso, pagamento único.
enum CoursePrice {
  none('none'),
  upTo29('upTo29'),
  from30To59('30to59'),
  from60To99('60to99'),
  from100('100plus');

  const CoursePrice(this.code);

  final String code;

  static CoursePrice? byCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// A faixa de preço da mensalidade do treinador.
enum MonthPrice {
  none('none'),
  upTo9('upTo9'),
  from10To19('10to19'),
  from20To39('20to39'),
  from40('40plus');

  const MonthPrice(this.code);

  final String code;

  static MonthPrice? byCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// "A estrutura do app está fazendo você aprender?"
enum LearnAnswer {
  yes,
  some,
  no;

  String get code => name;

  static LearnAnswer? byCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Os ids estáveis dos chips do passo 3 (o texto vem do .arb).
abstract final class WouldPayOptions {
  static const why = ['learn', 'tournament', 'rating', 'teach', 'curious'];
  static const levels = ['beginner', 'middle', 'advanced'];
}

/// As respostas do "Você pagaria?". Os campos de escolha só mudam para um
/// valor; o texto vazio vira nulo.
class WouldPayAnswers {
  const WouldPayAnswers({
    this.course,
    this.coursePrice,
    this.coach,
    this.coachPrice,
    this.learn,
    this.next,
    this.why = const {},
    this.level,
  });

  factory WouldPayAnswers.fromJson(Map<String, Object?> json) =>
      WouldPayAnswers(
        course: WouldPayAnswer.byCode(json['course']),
        coursePrice: CoursePrice.byCode(json['coursePrice']),
        coach: WouldPayAnswer.byCode(json['coach']),
        coachPrice: MonthPrice.byCode(json['coachPrice']),
        learn: LearnAnswer.byCode(json['learn']),
        next: clip(json['next'] is String ? json['next'] as String : null),
        why: {
          if (json['why'] case final List<Object?> list)
            for (final id in list)
              if (WouldPayOptions.why.contains(id)) id! as String,
        },
        level: WouldPayOptions.levels.contains(json['level'])
            ? json['level'] as String?
            : null,
      );

  /// O tamanho máximo do "próximo final".
  static const maxNext = 200;

  final WouldPayAnswer? course;
  final CoursePrice? coursePrice;
  final WouldPayAnswer? coach;
  final MonthPrice? coachPrice;
  final LearnAnswer? learn;

  /// O final que a pessoa quer aprender em seguida (opcional).
  final String? next;

  /// Por que baixou o app (ids de [WouldPayOptions.why]).
  final Set<String> why;

  /// O nível escolhido no passo 3 (ids de [WouldPayOptions.levels]), quando o
  /// perfil ainda não tem nível.
  final String? level;

  /// O texto sem espaços nas pontas, até [maxNext] letras; vazio vira nulo.
  static String? clip(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length > maxNext ? trimmed.substring(0, maxNext) : trimmed;
  }

  WouldPayAnswers copyWith({
    WouldPayAnswer? course,
    CoursePrice? coursePrice,
    WouldPayAnswer? coach,
    MonthPrice? coachPrice,
    LearnAnswer? learn,
    String? next,
    Set<String>? why,
    String? level,
    bool clearLevel = false,
  }) => WouldPayAnswers(
    course: course ?? this.course,
    coursePrice: coursePrice ?? this.coursePrice,
    coach: coach ?? this.coach,
    coachPrice: coachPrice ?? this.coachPrice,
    learn: learn ?? this.learn,
    next: next == null ? this.next : clip(next),
    why: why ?? this.why,
    level: clearLevel ? null : level ?? this.level,
  );

  /// Os códigos estáveis, sem os campos vazios (o rascunho e o envio).
  Map<String, Object?> toJson() => {
    'course': ?course?.code,
    'coursePrice': ?coursePrice?.code,
    'coach': ?coach?.code,
    'coachPrice': ?coachPrice?.code,
    'learn': ?learn?.code,
    'next': ?clip(next),
    'why': [
      for (final id in WouldPayOptions.why)
        if (why.contains(id)) id,
    ],
    'level': ?level,
  };
}

/// O rascunho: o passo (a partir de 0) e as respostas até ali.
class WouldPayDraft {
  const WouldPayDraft({required this.step, required this.answers});

  factory WouldPayDraft.fromJson(Map<String, Object?> json) {
    final answers = json['answers'];
    if (answers is! Map<String, Object?>) {
      throw const FormatException('rascunho inválido');
    }
    return WouldPayDraft(
      step: json['step'] is int ? json['step'] as int : 0,
      answers: WouldPayAnswers.fromJson(answers),
    );
  }

  final int step;
  final WouldPayAnswers answers;

  Map<String, Object?> toJson() => {'step': step, 'answers': answers.toJson()};
}
