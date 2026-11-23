import 'package:lucena/domain/models/lesson_video.dart';

/// Uma aula em vídeo mínima e neutra (formato 1), no molde do que o
/// `LessonVideoConverter` monta: quatro falas na linha principal, a segunda
/// com pergunta (espera o lance e2e4; a terceira é só do lance certo), e os
/// ramos de erro, de alternativa e de resposta (estes sem áudio: tempo de
/// leitura).
///
/// Tempos (voz, velocidade 1,0):
///  - fala 0: 0–2000 voz, pausa 500 → fim 2500 (marca e4 desde a palavra 3);
///  - fala 1: 2500–4500 voz (pergunta: para em 4500), pausa 500 → 5000;
///  - fala 2 (só do lance certo): lance e2e4 (400 ms) → voz 5400–7400,
///    pausa 600 → 8000;
///  - fala 3: voz 8000–9000, sem pausa → fim 9000.
const lessonVideoJson = <String, dynamic>{
  'formato': 1,
  'licao': 'exemplo.licao',
  'parte': 'parte',
  'idioma': 'pt',
  'voz': 'viktor',
  'capitulos': [
    {'id': 'ideia.ex1', 'etapa': 'ideia', 'fala': 0, 'vira': false},
  ],
  'falas': [
    {
      'id': 'ideia.ex1.e.1',
      't': 'rot.e1',
      'texto': 'Olhe a casa e4 agora.',
      'audio': 'audio/pt/viktor/aaaa.opus',
      'ms': 2000,
      'palavras': [
        [0, 4, 0, 500],
        [5, 6, 500, 800],
        [7, 11, 800, 1200],
        [12, 15, 1200, 1500],
        [16, 21, 1500, 2000],
      ],
      'depois': 500,
      'tabuleiro': {'fen': '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1', 'salto': true},
      'marcas': [
        {'casa': 'e4', 'desde': 3},
        {'casa': 'e2'},
      ],
    },
    {
      'id': 'ideia.ex1.p',
      't': 'rot.p',
      'texto': 'Qual é o lance?',
      'audio': 'audio/pt/viktor/bbbb.opus',
      'ms': 2000,
      'palavras': [
        [0, 4, 0, 1000],
        [5, 15, 1000, 2000],
      ],
      'depois': 500,
      'tabuleiro': {'fen': '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1'},
      'setas': [
        {'de': 'e2', 'para': 'e4', 'cor': 'g'},
      ],
      'vez': {
        'pecas': ['e2'],
        'certos': ['e2e4'],
        'fora': 'ideia.ex1.fora',
        'revela': 'ideia.ex1.revela',
        'certo': 1,
        'saidas': {
          'e2e3': {'ramo': 'ideia.ex1.err.e2e3', 'depois': 'repete'},
          'e1d1': {'ramo': 'ideia.ex1.alt.e1d1', 'depois': 'segue'},
        },
      },
    },
    {
      'id': 'ideia.ex1.certo.1',
      't': 'rot.certo',
      'texto': 'Isso: o peão anda duas.',
      'audio': 'audio/pt/viktor/cccc.opus',
      'ms': 2000,
      'depois': 600,
      'tabuleiro': {'fen': '4k3/8/8/8/4P3/8/8/4K3 b - - 0 1', 'lance': 'e2e4'},
    },
    {
      'id': 'ideia.ex1.l.1',
      't': 'rot.l1',
      'texto': 'Agora o rei.',
      'audio': 'audio/pt/viktor/dddd.opus',
      'ms': 1000,
      'depois': 0,
      'tabuleiro': {'fen': '4k3/8/8/8/4P3/8/8/4K3 b - - 0 1'},
    },
  ],
  'ramos': {
    'ideia.ex1.err.e2e3': [
      {
        'id': 'ideia.ex1.err.e2e3.1',
        't': 'rot.err',
        'texto': 'Só uma casa: devagar.',
        'audio': null,
        'ms': 1500,
        'depois': 500,
        'tabuleiro': {
          'fen': '4k3/8/8/8/8/4P3/8/4K3 b - - 0 1',
          'lance': 'e2e3',
        },
      },
    ],
    'ideia.ex1.fora': [
      {
        'id': 'ideia.ex1.fora.1',
        't': 'rot.fora',
        'texto': 'Mova o peão.',
        'audio': null,
        'ms': 1200,
        'depois': 500,
        'tabuleiro': {'fen': '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1'},
      },
    ],
    'ideia.ex1.alt.e1d1': [
      {
        'id': 'ideia.ex1.alt.e1d1.1',
        't': 'rot.alt',
        'texto': 'Também serve.',
        'audio': null,
        'ms': 1200,
        'depois': 500,
        'tabuleiro': {
          'fen': '4k3/8/8/8/8/8/4P3/3K4 b - - 1 1',
          'lance': 'e1d1',
        },
      },
    ],
    'ideia.ex1.revela': [
      {
        'id': 'ideia.ex1.revela.1',
        't': 'rot.revela',
        'texto': 'O lance é e4.',
        'audio': null,
        'ms': 1200,
        'depois': 500,
        'tabuleiro': {
          'fen': '4k3/8/8/8/4P3/8/8/4K3 b - - 0 1',
          'lance': 'e2e4',
        },
      },
    ],
  },
};

LessonVideo sampleLessonVideo() => LessonVideo.fromJson(lessonVideoJson);
