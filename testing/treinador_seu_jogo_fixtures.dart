import 'package:lucena/domain/models/treinador/treinador.dart';

import 'treinador_fixtures.dart';

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
abstract final class SeuJogoFixtures {
  static final inicio = DateTime.utc(2026, 11, 8, 20);

  /// O "agora" dos testes: o dia seguinte à mais nova, de manhã.
  static final agora = DateTime.utc(2026, 11, 9, 12);

  static const fenAbertura =
      'rnbqkbnr/pp2pppp/2p5/3pP3/3P4/8/PPP2PPP/RNBQKBNR b KQkq - 0 3';

  static String id(int i) => 'lichess_sj${i.toString().padLeft(3, '0')}';

  static Map<String, Object?> partidaJson(int i) {
    final pretas = i.isOdd;
    final saiDaTeoria = pretas && i % 3 != 2;
    final lances = [
      for (var ply = 0; ply < 12; ply++)
        {
          'san': ply == 9 && saiDaTeoria ? 'c5' : 'a${ply % 8 + 1}',
          'fen': fenAbertura,
          'cp': 20,
          'classe': ply == (pretas ? 3 : 2) ? 'erro' : 'ok',
        },
      if (i % 4 == 0)
        {
          'san': 'Rc1',
          'fen': TreinadorFixtures.fenFinal,
          'cp': -300,
          'classe': 'grave',
        },
    ];
    return {
      'url': 'https://lichess.org/sj${i.toString().padLeft(5, '0')}',
      'jogadaEm': inicio.subtract(Duration(days: i)).toIso8601String(),
      'ritmo': const ['blitz', 'rapida', 'bullet'][i % 3],
      'cadencia': '5+0',
      'cor': pretas ? 'pretas' : 'brancas',
      'adversario': {'nome': 'rival_$i', 'rating': 1500 + i},
      'rating': 1580,
      'resultado': const ['vitoria', 'vitoria', 'empate', 'derrota'][i % 4],
      'abertura': pretas
          ? {'eco': 'B12', 'nome': 'Defesa Caro-Kann'}
          : {'eco': 'D02', 'nome': 'Sistema Londres'},
      'pgn': '1. e4 c6 *',
      'status': 'pronta',
      'precisao': 70 + i % 10,
      'lances': lances,
      if (saiDaTeoria)
        'teoria': {
          'lance': 9,
          'fen': fenAbertura,
          'candidatos': [
            {
              'san': 'Bf5',
              'partidas': 412000,
              'brancas': 48,
              'empates': 9,
              'pretas': 43,
              'linha': ['Bf5', 'Nf3', 'e6'],
            },
            {
              'san': 'c5',
              'partidas': 98000,
              'brancas': 52,
              'empates': 7,
              'pretas': 41,
            },
          ],
        },
      'analisadaEm': inicio.subtract(Duration(days: i)).toIso8601String(),
    };
  }

  static List<PartidaTreinador> partidas([int n = 60]) => [
    for (var i = 0; i < n; i++)
      PartidaTreinador.fromJson(id(i), partidaJson(i))!,
  ];

  /// Estatísticas do servidor: posições de garfo em 5 partidas, de final de
  /// torres em 2; estilo firme; a Caro-Kann ligada à parte 2 da Caro-Kann.
  static Map<String, Object?> estatisticasJson({String nivel = 'firme'}) => {
    'partidasAnalisadas': 60,
    'errosPorTema': {
      'garfo': [
        for (final i in [0, 2, 4, 6, 8])
          {'partida': id(i), 'lance': 12, 'fen': fenAbertura},
      ],
      'final_torres': [
        for (final i in [4, 8])
          {'partida': id(i), 'lance': 40, 'fen': TreinadorFixtures.fenFinal},
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
      'nivel': nivel,
      'fortes': [
        {'texto': 'Converte bem a vantagem de material.', 'partidas': 12},
      ],
      'acertar': [
        {'texto': 'Deixa garfos de cavalo.', 'partidas': 5, 'tema': 'garfo'},
      ],
    },
  };

  static EstatisticasTreinador estatisticas({String nivel = 'firme'}) =>
      EstatisticasTreinador.fromJson(estatisticasJson(nivel: nivel));
}
