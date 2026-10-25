/// A prévia do curso Pilares do Xadrez (T82): só os textos estáticos das
/// telas de venda, do mapa e de um capítulo, exportados do canvas por
/// `tools/export_pilares_preview.py`. Não há lição real nem compra.
class CoursePreview {
  const CoursePreview({
    required this.sale,
    required this.map,
    required this.chapter,
  });

  factory CoursePreview.fromJson(Map<String, dynamic> json) => CoursePreview(
    sale: CourseSale.fromJson(json['sale'] as Map<String, dynamic>),
    map: CourseMapPreview.fromJson(json['map'] as Map<String, dynamic>),
    chapter: CourseChapterPreview.fromJson(
      json['chapter'] as Map<String, dynamic>,
    ),
  );

  final CourseSale sale;
  final CourseMapPreview map;
  final CourseChapterPreview chapter;
}

List<T> _list<T>(Object? json, T Function(Map<String, dynamic>) parse) => [
  for (final item in (json as List? ?? const []))
    parse(item as Map<String, dynamic>),
];

/// Um item com ícone (nome do Material Icons), título e frase opcional.
class CourseSaleItem {
  const CourseSaleItem({required this.title, this.icon, this.summary});

  factory CourseSaleItem.fromJson(Map<String, dynamic> json) => CourseSaleItem(
    icon: json['icon'] as String?,
    title: json['title'] as String,
    summary: json['summary'] as String?,
  );

  final String? icon;
  final String title;
  final String? summary;
}

/// Uma parte do sumário: o número romano, o título, quantas lições tem e os
/// capítulos (o último é o das aberturas).
class CourseSalePart {
  const CourseSalePart({
    required this.number,
    required this.title,
    required this.lessons,
    required this.chapters,
  });

  factory CourseSalePart.fromJson(Map<String, dynamic> json) => CourseSalePart(
    number: json['number'] as String,
    title: json['title'] as String,
    lessons: json['lessons'] as int,
    chapters: [
      for (final chapter in json['chapters'] as List)
        CourseSaleChapter.fromJson(chapter as Map<String, dynamic>),
    ],
  );

  final String number;
  final String title;
  final int lessons;
  final List<CourseSaleChapter> chapters;
}

/// Um capítulo do sumário: o número (no curso todo), o título, as lições
/// (n.1, n.2…) e, se tiver, os exercícios práticos, o último item numerado.
class CourseSaleChapter {
  const CourseSaleChapter({
    required this.number,
    required this.title,
    required this.lessons,
    this.exercises,
  });

  factory CourseSaleChapter.fromJson(Map<String, dynamic> json) =>
      CourseSaleChapter(
        number: json['number'] as int,
        title: json['title'] as String,
        lessons: [
          for (final lesson in json['lessons'] as List) lesson as String,
        ],
        exercises: json['exercises'] as String?,
      );

  final int number;
  final String title;
  final List<String> lessons;
  final String? exercises;

  /// As linhas numeradas: as lições e, por último, os exercícios.
  List<String> get items => [...lessons, ?exercises];
}

/// Uma pergunta da aba Dúvidas.
class CourseSaleFaq {
  const CourseSaleFaq({
    required this.icon,
    required this.question,
    required this.answer,
  });

  factory CourseSaleFaq.fromJson(Map<String, dynamic> json) => CourseSaleFaq(
    icon: json['icon'] as String,
    question: json['question'] as String,
    answer: json['answer'] as String,
  );

  final String icon;
  final String question;
  final String answer;
}

/// A página de venda (canvas `PropV2CursoApresentacao` e as abas).
class CourseSale {
  const CourseSale({
    required this.overline,
    required this.title,
    required this.line,
    required this.lessons,
    required this.exercises,
    required this.price,
    required this.priceNote,
    required this.speech,
    required this.how,
    required this.learn,
    required this.audience,
    required this.audienceItems,
    required this.included,
    required this.app,
    required this.level,
    required this.levelExamples,
    required this.summaryNote,
    required this.parts,
    required this.faq,
  });

  factory CourseSale.fromJson(Map<String, dynamic> json) {
    final level = json['level'] as Map<String, dynamic>;
    return CourseSale(
      overline: json['overline'] as String,
      title: json['title'] as String,
      line: json['line'] as String,
      lessons: json['lessons'] as int,
      exercises: json['exercises'] as String,
      price: json['price'] as String,
      priceNote: json['priceNote'] as String,
      speech: json['speech'] as String,
      how: _list(json['how'], CourseSaleItem.fromJson),
      learn: _list(json['learn'], CourseSaleItem.fromJson),
      audience: CourseSaleItem.fromJson(
        json['audience'] as Map<String, dynamic>,
      ),
      audienceItems: _list(json['audienceItems'], CourseSaleItem.fromJson),
      included: _list(json['included'], CourseSaleItem.fromJson),
      app: _list(json['app'], CourseSaleItem.fromJson),
      level: CourseSaleItem.fromJson(level),
      levelExamples: [
        for (final item in level['examples'] as List)
          (
            title: (item as Map<String, dynamic>)['title'] as String,
            status: item['status'] as String,
            tone: item['tone'] as String,
          ),
      ],
      summaryNote: json['summaryNote'] as String,
      parts: _list(json['parts'], CourseSalePart.fromJson),
      faq: _list(json['faq'], CourseSaleFaq.fromJson),
    );
  }

  final String overline;
  final String title;
  final String line;
  final int lessons;

  /// Já com o sinal ("+750").
  final String exercises;
  final String price;
  final String priceNote;
  final String speech;
  final List<CourseSaleItem> how;
  final List<CourseSaleItem> learn;
  final CourseSaleItem audience;
  final List<CourseSaleItem> audienceItems;
  final List<CourseSaleItem> included;
  final List<CourseSaleItem> app;
  final CourseSaleItem level;

  /// O exemplo do teste de nível: a lição, a situação e a cor da pílula
  /// (`mastered`, `review` ou `learn`).
  final List<({String title, String status, String tone})> levelExamples;
  final String summaryNote;
  final List<CourseSalePart> parts;
  final List<CourseSaleFaq> faq;
}

/// Um capítulo do mapa: o estado (nome de `CourseItemState`), título, resumo
/// e a faixa da medalha (nome de `ExerciseGrade`) ou nada.
class CourseMapChapter {
  const CourseMapChapter({
    required this.id,
    required this.state,
    required this.title,
    required this.summary,
    this.medal,
  });

  factory CourseMapChapter.fromJson(Map<String, dynamic> json) =>
      CourseMapChapter(
        id: json['id'] as String,
        state: json['state'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        medal: json['medal'] as String?,
      );

  final String id;
  final String state;
  final String title;
  final String summary;
  final String? medal;
}

/// O mapa do curso (canvas `PropV2CursoMapa`).
class CourseMapPreview {
  const CourseMapPreview({
    required this.continuePart,
    required this.continueNumber,
    required this.continueTitle,
    required this.continueSummary,
    required this.test,
    required this.partLabel,
    required this.partTitle,
    required this.done,
    required this.total,
    required this.chapters,
  });

  factory CourseMapPreview.fromJson(Map<String, dynamic> json) {
    final next = json['continue'] as Map<String, dynamic>;
    final part = json['part'] as Map<String, dynamic>;
    return CourseMapPreview(
      continuePart: next['part'] as String,
      continueNumber: next['number'] as int,
      continueTitle: next['title'] as String,
      continueSummary: next['summary'] as String,
      test: json['test'] as String,
      partLabel: part['label'] as String,
      partTitle: part['title'] as String,
      done: part['done'] as int,
      total: part['total'] as int,
      chapters: _list(json['chapters'], CourseMapChapter.fromJson),
    );
  }

  final String continuePart;
  final int continueNumber;
  final String continueTitle;
  final String continueSummary;
  final String test;
  final String partLabel;
  final String partTitle;
  final int done;
  final int total;
  final List<CourseMapChapter> chapters;
}

/// Uma lição do capítulo: o tipo da linha (nome de `ChapterRowKind`).
class CourseChapterLesson {
  const CourseChapterLesson({
    required this.id,
    required this.kind,
    required this.number,
    required this.title,
    required this.summary,
  });

  factory CourseChapterLesson.fromJson(Map<String, dynamic> json) =>
      CourseChapterLesson(
        id: json['id'] as String,
        kind: json['kind'] as String,
        number: json['number'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
      );

  final String id;
  final String kind;
  final String number;
  final String title;
  final String summary;
}

/// O capítulo (canvas `PropV2CursoLicao`).
class CourseChapterPreview {
  const CourseChapterPreview({
    required this.part,
    required this.number,
    required this.count,
    required this.title,
    required this.lessons,
    required this.exercisesNumber,
    required this.exercisesCount,
    required this.start,
  });

  factory CourseChapterPreview.fromJson(Map<String, dynamic> json) {
    final exercises = json['exercises'] as Map<String, dynamic>;
    return CourseChapterPreview(
      part: json['part'] as String,
      number: json['number'] as int,
      count: json['count'] as int,
      title: json['title'] as String,
      lessons: _list(json['lessons'], CourseChapterLesson.fromJson),
      exercisesNumber: exercises['number'] as String,
      exercisesCount: exercises['count'] as int,
      start: json['start'] as String,
    );
  }

  final String part;
  final int number;
  final int count;
  final String title;
  final List<CourseChapterLesson> lessons;
  final String exercisesNumber;
  final int exercisesCount;

  /// O número da lição do botão "Começar a lição".
  final String start;
}
