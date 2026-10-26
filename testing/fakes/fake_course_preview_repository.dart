import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/domain/models/course_preview.dart';

/// Prévia inventada para testar layout e navegação sem currículo privado.
class FakeCoursePreviewRepository implements CoursePreviewRepository {
  FakeCoursePreviewRepository({this.preview});

  static CoursePreview example() => CoursePreview.fromJson({
    'sale': {
      'overline': 'EXEMPLO',
      'title': 'Curso de exemplo',
      'line': 'Uma prévia sintética para testar a interface.',
      'lessons': 30,
      'exercises': '+10',
      'price': 'R\$ 10,00',
      'priceNote': 'Preço ilustrativo.',
      'speech': 'Conheça este exemplo de navegação.',
      'how': [_item('Etapa de exemplo')],
      'learn': [_item('Conteúdo ilustrativo')],
      'audience': _item('Público de exemplo'),
      'audienceItems': [_item('Uma descrição de público.')],
      'included': [_item('Item de exemplo')],
      'app': [_item('Recurso de exemplo')],
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
                  if (n != end) 'exercises': 'Exercícios',
                },
            ],
          },
      ],
      'faq': [
        for (var i = 1; i <= 2; i++)
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
    'map': {
      'continue': {
        'part': 'Parte I',
        'number': 5,
        'title': 'Capítulo de exemplo 5',
        'summary': 'Próxima etapa de exemplo.',
      },
      'test': 'Teste de exemplo',
      'part': {
        'label': 'Parte I',
        'title': 'Parte de exemplo',
        'done': 1,
        'total': 6,
      },
      'chapters': [
        for (var i = 1; i <= 6; i++)
          {
            'id': 'example.$i',
            'state': i == 5 ? 'next' : 'open',
            'title': 'Capítulo de exemplo $i',
            'summary': 'Resumo de exemplo $i.',
          },
      ],
    },
    'chapter': {
      'part': 'Parte I',
      'number': 5,
      'count': 6,
      'title': 'Capítulo de exemplo 5',
      'lessons': [
        for (var i = 1; i <= 3; i++)
          {
            'id': 'example.5.$i',
            'kind': i == 1 ? 'recommended' : 'other',
            'number': '5.$i',
            'title': 'Exemplo 5.$i',
            'summary': 'Resumo ilustrativo.',
          },
      ],
      'exercises': {'number': '5.4', 'count': 3},
      'start': '5.1',
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
