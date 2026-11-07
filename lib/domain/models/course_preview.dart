/// Os textos da venda do Pilares do Xadrez (T85-D2, H-VEN-01/02), gerados
/// por `tools/export_pilares_venda.py` a partir dos quadros do canvas e do
/// currículo real. Os preços não estão aqui: vêm da loja.
class CoursePreview {
  const CoursePreview({required this.sale, required this.details});

  factory CoursePreview.fromJson(Map<String, dynamic> json) => CoursePreview(
    sale: CourseSale.fromJson(json['sale'] as Map<String, dynamic>),
    details: CourseDetails.fromJson(json['details'] as Map<String, dynamic>),
  );

  final CourseSale sale;

  /// "Sobre o Pilares" (H-VEN-02).
  final CourseDetails details;
}

/// Os textos do "Sobre o Pilares" (H-VEN-02, quadros `PropV1CursoDetalhes`,
/// `…Conteudo` e `…Duvidas`). O sumário e as aberturas do Conteúdo são os da
/// venda.
class CourseDetails {
  const CourseDetails({
    required this.steps,
    required this.coverLine,
    required this.parts,
    required this.openings,
    required this.progress,
    required this.audience,
    required this.result,
    required this.summaryLine,
    required this.faq,
  });

  factory CourseDetails.fromJson(Map<String, dynamic> json) => CourseDetails(
    steps: _list(json['steps'], CourseSaleItem.fromJson),
    coverLine: json['coverLine'] as String,
    parts: _list(json['parts'], CourseSaleItem.fromJson),
    openings: _list(json['openings'], CourseSaleItem.fromJson),
    progress: _list(json['progress'], CourseSaleItem.fromJson),
    audience: CourseSaleItem.fromJson(json['audience'] as Map<String, dynamic>),
    result: CourseSaleItem.fromJson(json['result'] as Map<String, dynamic>),
    summaryLine: json['summaryLine'] as String,
    faq: _list(json['faq'], CourseSaleFaq.fromJson),
  );

  /// "Como o curso funciona": os 5 passos, na ordem.
  final List<CourseSaleItem> steps;

  /// A frase de abertura de "O que o curso cobre".
  final String coverLine;

  /// Uma linha por parte, com o ícone e as lições.
  final List<CourseSaleItem> parts;
  final List<CourseSaleItem> openings;

  /// "Testes e progresso".
  final List<CourseSaleItem> progress;
  final CourseSaleItem audience;

  /// O cartão "Resultado do seu teste" do Conteúdo.
  final CourseSaleItem result;
  final String summaryLine;
  final List<CourseSaleFaq> faq;
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
/// capítulos de tema (as aberturas vêm no fim, iguais em todas as partes).
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

/// Um capítulo do sumário: o número (no curso todo) e as lições (n.1,
/// n.2…). O teste do capítulo, a última linha, vem do ARB.
class CourseSaleChapter {
  const CourseSaleChapter({
    required this.number,
    required this.title,
    required this.lessons,
  });

  factory CourseSaleChapter.fromJson(Map<String, dynamic> json) =>
      CourseSaleChapter(
        number: json['number'] as int,
        title: json['title'] as String,
        lessons: [
          for (final lesson in json['lessons'] as List) lesson as String,
        ],
      );

  final int number;
  final String title;
  final List<String> lessons;
}

/// Uma linha do comparativo "Quanto custa estudar xadrez por 3 meses".
class CourseSaleCost {
  const CourseSaleCost({required this.title, required this.value, this.note});

  factory CourseSaleCost.fromJson(Map<String, dynamic> json) => CourseSaleCost(
    title: json['title'] as String,
    value: json['value'] as String,
    note: json['summary'] as String?,
  );

  final String title;
  final String value;
  final String? note;
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

/// A tela "Para quem é" (canvas `PropV2CursoFaixa`): por que a faixa é larga,
/// com a frequência de cada tema em cada faixa de rating (em %).
class CourseSaleBand {
  const CourseSaleBand({
    required this.heading,
    required this.line,
    required this.chartTitle,
    required this.chartNote,
    required this.ranges,
    required this.themes,
    required this.source,
    required this.warning,
  });

  factory CourseSaleBand.fromJson(Map<String, dynamic> json) => CourseSaleBand(
    heading: json['heading'] as String,
    line: json['line'] as String,
    chartTitle: json['chartTitle'] as String,
    chartNote: json['chartNote'] as String,
    ranges: [for (final range in json['ranges'] as List) range as String],
    themes: [
      for (final item in json['themes'] as List)
        (
          name: (item as Map<String, dynamic>)['name'] as String,
          values: [
            for (final value in item['values'] as List)
              (value as num).toDouble(),
          ],
        ),
    ],
    source: json['source'] as String,
    warning: CourseSaleItem.fromJson(json['warning'] as Map<String, dynamic>),
  );

  final String heading;
  final String line;
  final String chartTitle;
  final String chartNote;

  /// As faixas da legenda, na ordem dos valores de cada tema.
  final List<String> ranges;
  final List<({String name, List<double> values})> themes;
  final String source;
  final CourseSaleItem warning;
}

/// A venda (canvas `PropV2CursoApresentacao` e as abas).
class CourseSale {
  const CourseSale({
    required this.title,
    required this.line,
    required this.lessons,
    required this.chapters,
    required this.exercises,
    required this.speech,
    required this.benefitsTitle,
    required this.benefitsLine,
    required this.benefits,
    required this.lifetimeTitle,
    required this.lifetimeNote,
    required this.monthlyQuestion,
    required this.unlock,
    required this.costTitle,
    required this.costs,
    required this.ours,
    required this.costSource,
    required this.learn,
    required this.audience,
    required this.audienceItems,
    required this.included,
    required this.level,
    required this.levelExamples,
    required this.summaryNote,
    required this.parts,
    required this.openings,
    required this.faq,
    required this.band,
  });

  factory CourseSale.fromJson(Map<String, dynamic> json) {
    final level = json['level'] as Map<String, dynamic>;
    final plans = json['plans'] as Map<String, dynamic>;
    final cost = json['cost'] as Map<String, dynamic>;
    final openings = json['openings'] as Map<String, dynamic>;
    return CourseSale(
      title: json['title'] as String,
      line: json['line'] as String,
      lessons: json['lessons'] as int,
      chapters: json['chapters'] as int,
      exercises: json['exercises'] as String,
      speech: json['speech'] as String,
      benefitsTitle: json['benefitsTitle'] as String,
      benefitsLine: json['benefitsLine'] as String,
      benefits: _list(json['benefits'], CourseSaleItem.fromJson),
      lifetimeTitle: plans['lifetime'] as String,
      lifetimeNote: plans['lifetimeNote'] as String,
      monthlyQuestion: plans['monthly'] as String,
      unlock: plans['unlock'] as String,
      costTitle: cost['title'] as String,
      costs: _list(cost['rows'], CourseSaleCost.fromJson),
      ours: CourseSaleItem.fromJson(cost['ours'] as Map<String, dynamic>),
      costSource: cost['source'] as String,
      learn: _list(json['learn'], CourseSaleItem.fromJson),
      audience: CourseSaleItem.fromJson(
        json['audience'] as Map<String, dynamic>,
      ),
      audienceItems: _list(json['audienceItems'], CourseSaleItem.fromJson),
      included: _list(json['included'], CourseSaleItem.fromJson),
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
      openings: (
        title: openings['title'] as String,
        line: openings['line'] as String,
        items: [for (final item in openings['items'] as List) item as String],
      ),
      faq: _list(json['faq'], CourseSaleFaq.fromJson),
      band: CourseSaleBand.fromJson(json['band'] as Map<String, dynamic>),
    );
  }

  /// O nome do curso, na app bar.
  final String title;
  final String line;
  final int lessons;
  final int chapters;

  /// Já com o sinal ("850+").
  final String exercises;
  final String speech;
  final String benefitsTitle;
  final String benefitsLine;

  /// "Mais que um curso de xadrez": os 8 itens, na ordem.
  final List<CourseSaleItem> benefits;
  final String lifetimeTitle;
  final String lifetimeNote;
  final String monthlyQuestion;
  final String unlock;
  final String costTitle;
  final List<CourseSaleCost> costs;

  /// A linha do Pilares no comparativo (o preço vem da loja).
  final CourseSaleItem ours;
  final String costSource;
  final List<CourseSaleItem> learn;
  final CourseSaleItem audience;
  final List<CourseSaleItem> audienceItems;
  final List<CourseSaleItem> included;
  final CourseSaleItem level;

  /// O exemplo do teste de nível: a parte, a situação e a cor da pílula
  /// (`mastered`, `review` ou `learn`).
  final List<({String title, String status, String tone})> levelExamples;
  final String summaryNote;
  final List<CourseSalePart> parts;

  /// As aberturas no fim de cada parte (as mesmas 4 linhas genéricas).
  final ({String title, String line, List<String> items}) openings;
  final List<CourseSaleFaq> faq;
  final CourseSaleBand band;
}
