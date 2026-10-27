/// Um roteiro pequeno para os testes (T70): duas etapas de pergunta e uma de
/// prática, com as falas à parte. Não depende dos assets da lição.
library;

import 'package:lucena/domain/models/lesson_script.dart';

const exampleOneFen = '4k3/8/8/8/8/3K2P1/8/8 w - - 0 1';
const afterKe4 = '4k3/8/8/8/4K3/6P1/8/8 b - - 1 1';
const afterKd4 = '4k3/8/8/8/3K4/6P1/8/8 b - - 1 1';
const afterKd4Ke7 = '8/4k3/8/8/3K4/6P1/8/8 w - - 2 2';
const afterKe4Kf7 = '8/5k2/8/8/4K3/6P1/8/8 w - - 2 2';
const afterKc3 = '4k3/8/8/8/8/2K3P1/8/8 b - - 1 1';
const exampleTwoFen = '4k3/8/8/8/8/4K1P1/8/8 b - - 0 1';
const afterKe7 = '8/4k3/8/8/8/4K1P1/8/8 w - - 1 2';
const afterKf7 = '8/5k2/8/8/8/4K1P1/8/8 w - - 1 2';
const afterKf8 = '5k2/8/8/8/8/4K1P1/8/8 w - - 1 2';
const practiceFen = '4k3/8/8/8/8/1P3K2/8/8 w - - 0 1';
const practiceTwoFen = '8/1k6/8/8/8/8/2K3P1/8 b - - 0 1';

Map<String, dynamic> _step(
  String fen,
  String t, {
  String? lance,
  bool salto = false,
  List<String> marcas = const [],
}) => {
  'fen': fen,
  't': t,
  'lance': ?lance,
  if (salto) 'salto': true,
  'marcas': marcas,
  'setas': const [],
};

Map<String, dynamic> scriptJson() => {
  'licao': 'pawns.test',
  'parte': 'distant',
  'etapas': [
    {
      'id': 'ideia',
      'exemplos': [
        {
          'id': 'ex1',
          'fen': exampleOneFen,
          'vira': false,
          'objetivo': 'ganhar',
          'curiosidades': {
            't': 'cur.t',
            'citacao': {'t': 'cur.q', 'autor': 'Alguém'},
            'referencias': [
              'book1',
              {'kind': 'player', 'name': 'Ada Lovelace', 'url': 'https://x.y'},
            ],
          },
          'entrada': [
            _step(exampleOneFen, 'e1'),
            _step(exampleOneFen, 'e2', marcas: ['d3']),
            _step(exampleOneFen, 'e3', marcas: ['f5']),
          ],
          'pergunta': {
            't': 'q',
            'certos': ['d3e4'],
            'certo': _step(afterKe4, 'ok', lance: 'd3e4'),
            'revela': _step(afterKe4, 'rev', lance: 'd3e4'),
            'alternativos': <String, dynamic>{},
            'erros': {
              'd3d4': [
                _step(afterKd4, 'err1', lance: 'd3d4'),
                _step(afterKd4Ke7, 'err2', lance: 'e8e7'),
              ],
            },
            'livre': {
              'maquina': 'b',
              'fala': 'free',
              'fins': {'capturado': 'fin.cap'},
              'volta': 'back',
            },
          },
          'linha': [
            _step(afterKe4, 'l1'),
            _step(afterKe4Kf7, 'l2', lance: 'e8f7'),
            _step(afterKe4Kf7, 'l3'),
          ],
          'fim': 'proximo',
        },
        {
          'id': 'ex2',
          'fen': exampleTwoFen,
          'vira': true,
          'objetivo': 'empatar',
          'entrada': [_step(exampleTwoFen, 'x1')],
          'pergunta': {
            't': 'q2',
            'certos': ['e8e7'],
            'certo': _step(afterKe7, 'okB', lance: 'e8e7'),
            'revela': _step(afterKe7, 'revB', lance: 'e8e7'),
            'alternativos': {
              'e8f7': [
                _step(afterKf7, 'altA', lance: 'e8f7'),
                _step(exampleTwoFen, 'altBack', salto: true),
              ],
            },
            'erros': {
              'e8f8': [_step(afterKf8, 'errB', lance: 'e8f8')],
            },
            'livre': {
              'maquina': 'w',
              'fala': 'freeB',
              'fins': <String, dynamic>{},
              'volta': 'backB',
            },
          },
          'linha': [_step(afterKe7, 'lB1')],
          'fim': 'etapa',
        },
      ],
    },
    {
      'id': 'demos',
      'exemplos': [
        {
          'id': 'd1',
          'fen': exampleOneFen,
          'vira': false,
          'objetivo': 'ganhar',
          'entrada': [_step(exampleOneFen, 'd1a'), _step(exampleOneFen, 'd1b')],
          'linha': [_step(afterKe4, 'd1c', lance: 'd3e4')],
          'fim': 'etapa',
        },
      ],
    },
    {
      'id': 'pratica',
      'exemplos': [
        {
          'id': 'p1',
          'fen': practiceFen,
          'vira': false,
          'objetivo': 'ganhar',
          'pratica': {'t': 'p.t', 'maquina': 'b', 'limite': 40, 'fim': 'p.fim'},
          'entrada': <dynamic>[],
          'linha': <dynamic>[],
          'fim': 'proximo',
        },
        {
          'id': 'p2',
          'fen': practiceTwoFen,
          'vira': true,
          'objetivo': 'empatar',
          'pratica': {'t': 'p2.t', 'maquina': 'w', 'limite': 40},
          'entrada': <dynamic>[],
          'linha': <dynamic>[],
          'fim': 'etapa',
        },
      ],
    },
  ],
};

LessonScript scriptFixture() => LessonScript.fromJson(scriptJson());

/// Demonstração sintética de quatro lances seguida da prática da fixture.
/// Mantém o contrato de navegação e da posição final sem ler um roteiro real.
Map<String, dynamic> demoToPractice() {
  const start = '8/4k3/8/8/8/8/5P2/3K4 w - - 0 1';
  const second = '8/4k3/8/8/8/8/3K1P2/8 b - - 1 1';
  const third = '8/8/3k4/8/8/8/3K1P2/8 w - - 2 2';
  const fourth = '8/8/3k4/8/8/3K4/5P2/8 b - - 3 2';
  const end = '8/8/8/3k4/8/3K4/5P2/8 w - - 4 3';
  final json = scriptJson();
  return {
    ...json,
    'etapas': [
      {
        'id': 'demos',
        'exemplos': [
          {
            'id': 'demo',
            'fen': start,
            'vira': false,
            'objetivo': 'ganhar',
            'entrada': [_step(start, 'demo.inicio')],
            'linha': [
              _step(second, 'demo.1', lance: 'd1d2'),
              _step(third, 'demo.2', lance: 'e7d6'),
              _step(fourth, 'demo.3', lance: 'd2d3'),
              _step(end, 'demo.4', lance: 'd6d5'),
              _step(end, 'demo.ponte'),
            ],
            'fim': 'etapa',
          },
        ],
      },
      (json['etapas'] as List).last,
    ],
  };
}

/// Todas as falas que o roteiro de [scriptFixture] pede, com o próprio texto
/// igual à chave (`'e1'` fala `'e1'`), mais as genéricas.
Map<String, String> scriptTexts([Map<String, dynamic>? json]) {
  final keys = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      for (final MapEntry(:key, :value) in node.entries) {
        if ((key == 't' || key == 'fala' || key == 'volta' || key == 'fora') &&
            value is String) {
          keys.add(value);
        }
        if (key == 'fins' && value is Map) keys.addAll(value.values.cast());
        // `fim` do exemplo é 'proximo'/'etapa'; o da prática é uma fala.
        if (key == 'fim' &&
            value is String &&
            value != 'proximo' &&
            value != 'etapa') {
          keys.add(value);
        }
        walk(value);
      }
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  walk(json ?? scriptJson());
  return {
    for (final key in keys) key: key,
    for (final goal in ['ganhar', 'empatar']) ...{
      'gen.foraPerde.$goal': 'foraPerde.$goal',
      'gen.foraMantem.$goal': 'foraMantem.$goal',
      'gen.segueBem.$goal': 'segueBem.$goal',
      'gen.estragou.$goal': 'estragou.$goal',
      'gen.pratica.errado.$goal': 'errado.$goal',
      'gen.pratica.refuta.$goal': 'refuta.$goal {lance} {lado} {resposta}',
      'gen.pratica.sucesso.$goal': 'sucesso.$goal',
    },
    'gen.voltaIdeia': 'voltaIdeia',
    'gen.principal': 'principal',
    for (final goal in ['ganhar', 'empatar'])
      'gen.verLinha.$goal': 'verLinha.$goal {linhaPrincipal}',
    'gen.pratica.certo': 'certo',
    'gen.lado.white': 'brancas',
    'gen.lado.black': 'pretas',
    'gen.pratica.sucesso.mate': 'sucesso.mate',
    for (final end in [
      'coroa',
      'capturado',
      'afogado',
      'repeticao',
      'limite',
      'insuficiente',
    ])
      'gen.fim.$end': 'fim.$end',
  };
}
