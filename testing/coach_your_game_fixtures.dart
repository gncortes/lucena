import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/models/coach/coach.dart';

import 'coach_fixtures.dart';

/// 60 partidas prontas para a aba Seu jogo (T87), no formato do Firestore.
///
/// - Uma por dia, da mais nova (8/11/2026, 20h UTC) para trás.
/// - Ritmo em rodízio: blitz, rápida, bullet.
/// - Pares de Brancas (Sistema Londres, D02); ímpares de Pretas (Defesa
///   Caro-Kann, B12).
/// - Nas Caro-Kann fora de i ≡ 2 (mod 3), ele sai da teoria com 5...c5
///   (meio lance 9): 20 de 30 partidas. Dá o foco na abertura.
/// - Um erro na abertura em toda partida; um grave no final nas múltiplas
///   de 4.
/// - Resultado em rodízio: vitória, vitória, empate, derrota.
abstract final class YourGameFixtures {
  static final start = DateTime.utc(2026, 11, 8, 20);

  /// O "agora" dos testes: o dia seguinte à mais nova, de manhã.
  static final currentTime = DateTime.utc(2026, 11, 9, 12);

  /// Depois de 1.e4 c6 2.d4 d5 3.e5 (Caro-Kann, variante do Avanço).
  static const fenOpening =
      'rnbqkbnr/pp2pppp/2p5/3pP3/3P4/8/PPP2PPP/RNBQKBNR b KQkq - 0 3';

  /// A posição da saída: 1.e4 c6 2.d4 d5 3.e5 Bf5 4.Nf3 e6 5.Be2, pretas
  /// no 5º lance (c5 e Nd7 legais).
  static const fenTheory =
      'rn1qkbnr/pp3ppp/2p1p3/3pPb2/3P4/5N2/PPP1BPPP/RNBQK2R b KQkq - 1 5';

  /// Caro-Kann em que ele sai da teoria com 5...c5.
  static const _caroKannLeaves = [
    'e4', 'c6', 'd4', 'd5', 'e5', 'Bf5', //
    'Nf3', 'e6', 'Be2', 'c5', 'Be3', 'cxd4',
  ];

  /// Caro-Kann na teoria: 5...Nd7 6.O-O Ne7.
  static const _caroKannTheory = [
    'e4', 'c6', 'd4', 'd5', 'e5', 'Bf5', //
    'Nf3', 'e6', 'Be2', 'Nd7', 'O-O', 'Ne7',
  ];

  /// Sistema Londres das brancas.
  static const _london = [
    'd4', 'd5', 'Nf3', 'Nf6', 'Bf4', 'e6', //
    'e3', 'c5', 'c3', 'Nc6', 'Nbd2', 'Bd6',
  ];

  /// Cada lance com o FEN depois dele (dartchess garante a legalidade).
  static List<({String san, String fen})> _play(List<String> sans) {
    Position pos = Chess.initial;
    return [
      for (final san in sans)
        (san: san, fen: (pos = pos.play(pos.parseSan(san)!)).fen),
    ];
  }

  static String _pgn(List<String> sans) => [
    for (final (i, san) in sans.indexed) i.isEven ? '${i ~/ 2 + 1}. $san' : san,
    '*',
  ].join(' ');

  static String id(int i) => 'lichess_sj${i.toString().padLeft(3, '0')}';

  static Map<String, Object?> gameJson(int i) {
    final black = i.isOdd;
    final leavesTheory = black && i % 3 != 2;
    final sans = !black
        ? _london
        : (leavesTheory ? _caroKannLeaves : _caroKannTheory);
    final moves = [
      for (final (ply, l) in _play(sans).indexed)
        {
          'san': l.san,
          'fen': l.fen,
          'cp': 20,
          'classe': ply == (black ? 3 : 2) ? 'erro' : 'ok',
        },
      if (i % 4 == 0)
        {
          'san': 'Rc1',
          'fen': CoachFixtures.fenEnding,
          'cp': -300,
          'classe': 'grave',
        },
    ];
    return {
      'url': 'https://lichess.org/sj${i.toString().padLeft(5, '0')}',
      'jogadaEm': start.subtract(Duration(days: i)).toIso8601String(),
      'ritmo': const ['blitz', 'rapida', 'bullet'][i % 3],
      'cadencia': '5+0',
      'cor': black ? 'pretas' : 'brancas',
      'adversario': {'nome': 'rival_$i', 'rating': 1500 + i},
      'rating': 1580,
      'resultado': const ['vitoria', 'vitoria', 'empate', 'derrota'][i % 4],
      'abertura': black
          ? {'eco': 'B12', 'nome': 'Defesa Caro-Kann'}
          : {'eco': 'D02', 'nome': 'Sistema Londres'},
      'pgn': _pgn(sans),
      'status': 'pronta',
      'precisao': 70 + i % 10,
      'lances': moves,
      if (leavesTheory)
        'teoria': {
          'lance': 9,
          'fen': fenTheory,
          'candidatos': [
            {
              'san': 'Nd7',
              'partidas': 412000,
              'brancas': 48,
              'empates': 9,
              'pretas': 43,
              'linha': ['Nd7', 'O-O', 'Ne7'],
            },
            {
              'san': 'c5',
              'partidas': 98000,
              'brancas': 52,
              'empates': 7,
              'pretas': 41,
              'linha': ['c5', 'Be3', 'Qb6'],
            },
          ],
        },
      'analisadaEm': start.subtract(Duration(days: i)).toIso8601String(),
    };
  }

  static List<CoachGame> games([int n = 60]) => [
    for (var i = 0; i < n; i++) CoachGame.fromJson(id(i), gameJson(i))!,
  ];

  /// Estatísticas do servidor: posições de garfo em 5 partidas, de final de
  /// torres em 2; estilo firme; a Caro-Kann ligada à parte 2 da Caro-Kann.
  static Map<String, Object?> statsJson({String level = 'firme'}) => {
    'partidasAnalisadas': 60,
    'errosPorTema': {
      'garfo': [
        for (final i in [0, 2, 4, 6, 8])
          {'partida': id(i), 'lance': 12, 'fen': fenOpening},
      ],
      'final_torres': [
        for (final i in [4, 8])
          {'partida': id(i), 'lance': 40, 'fen': CoachFixtures.fenEnding},
      ],
    },
    'aberturas': [
      {
        'nome': 'Defesa Caro-Kann',
        'eco': 'B12',
        'cor': 'pretas',
        'partidas': 30,
        'vitorias': 15,
        'saidaTeoria': {'lance': 5, 'vezes': 10},
        'curso': {'id': 'pilares.ab2.caroKann2', 'parte': 2},
      },
    ],
    'estilo': {
      'nivel': level,
      'fortes': [
        {'texto': 'Converte bem a vantagem de material.', 'partidas': 12},
      ],
      'acertar': [
        {'texto': 'Deixa garfos de cavalo.', 'partidas': 5, 'tema': 'garfo'},
      ],
    },
  };

  static CoachStats stats({String level = 'firme'}) =>
      CoachStats.fromJson(statsJson(level: level));
}
