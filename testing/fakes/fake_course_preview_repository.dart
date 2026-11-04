import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/domain/models/course_preview.dart';

/// Prévia inventada para testar layout e navegação sem currículo privado.
class FakeCoursePreviewRepository implements CoursePreviewRepository {
  FakeCoursePreviewRepository({this.preview});

  static CoursePreview example() => CoursePreview.fromJson({
    'sale': {
      'title': 'Curso de exemplo',
      'line': 'Uma prévia sintética para testar a interface.',
      'lessons': 30,
      'chapters': 10,
      'exercises': '100+',
      'speech': 'Conheça este exemplo de navegação.',
      'benefitsTitle': 'Benefícios de exemplo',
      'benefitsLine': 'Linha ilustrativa.',
      'benefits': [for (var i = 1; i <= 8; i++) _item('Benefício $i')],
      'plans': {
        'lifetime': 'Acesso de exemplo',
        'lifetimeNote': 'Nota ilustrativa.',
        'monthly': 'Prefere o mensal?',
        'unlock': 'Tudo liberado',
      },
      'cost': {
        'title': 'Custo de exemplo',
        'rows': [
          {'title': 'Opção A', 'value': r'R$ 100'},
          {'title': 'Opção B', 'value': r'R$ 200', 'summary': 'Nota B.'},
          {'title': 'Opção A + B', 'value': r'R$ 300 a R$ 1.000'},
        ],
        'ours': _item('Linha do curso'),
        'source': 'Fonte ilustrativa.',
      },
      'learn': [_item('Conteúdo ilustrativo')],
      'audience': _item('Público de exemplo'),
      'audienceItems': [_item('Uma descrição de público.')],
      'included': [_item('Item de exemplo')],
      'level': {
        ..._item('Nível de exemplo'),
        'examples': [
          {'title': 'Lição de exemplo', 'status': 'A estudar', 'tone': 'learn'},
        ],
      },
      'summaryNote': 'Toque numa parte para ver os capítulos e as lições.',
      'parts': [
        for (final (number, start, end) in [('I', 1, 6), ('II', 7, 10)])
          {
            'number': number,
            'title': 'Parte de exemplo $number',
            'lessons': (end - start + 1) * 3,
            'chapters': [
              for (var n = start; n <= end; n++)
                {
                  'number': n,
                  'title': 'Capítulo de exemplo $n',
                  'lessons': [for (var i = 1; i <= 3; i++) 'Exemplo $n.$i'],
                },
            ],
          },
      ],
      'openings': {
        'title': 'Aberturas',
        'line': 'Linha de aberturas.',
        'items': ['Abertura de exemplo'],
      },
      'faq': [
        for (var i = 1; i <= 8; i++)
          {
            'icon': 'help',
            'question': 'Pergunta de exemplo $i?',
            'answer': 'Resposta ilustrativa $i.',
          },
      ],
      'band': {
        'heading': 'Faixa de exemplo',
        'line': 'Valores ilustrativos',
        'chartTitle': 'Gráfico de exemplo',
        'chartNote': 'Dados sintéticos.',
        'ranges': ['Faixa A', 'Faixa B'],
        'themes': [
          {
            'name': 'Tema de exemplo',
            'values': [12.5, 25.0],
          },
        ],
        'source': 'Fixture de teste',
        'warning': _item('Aviso de exemplo'),
      },
    },
  });

  static Map<String, String> _item(String title) => {
    'icon': 'school',
    'title': title,
    'summary': 'Descrição ilustrativa.',
  };

  final CoursePreview? preview;

  @override
  Future<CoursePreview?> load() async => preview;
}
