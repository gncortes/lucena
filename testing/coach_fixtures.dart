import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/domain/use_cases/coach/game_moves.dart';

/// Dados de exemplo do Treinador de partidas (T87), os mesmos do canvas
/// (`design/ferramentas/propostas/v2_treinador.py`): a derrota de Pretas na
/// Caro-Kann contra Tiago_Rook e mais quatro partidas da lista.
///
/// Ficam no formato do documento do Firestore (o mesmo que o servidor grava),
/// para os testes passarem pelo `fromJson`.
abstract final class CoachFixtures {
  static const username = 'gabriel_lucena';

  static const account = CoachAccount(
    platform: Platform.lichess,
    username: username,
  );

  static const idTiago = 'lichess_AbC12345';

  static const fenGreekGift =
      'r1b2rk1/pp1nqppp/2n1p3/2ppP3/3P4/2PB1N2/PP3PPP/R1BQK2R w KQ - 0 8';
  static const fenProphylaxis =
      'r1b2rk1/pp1nqppp/2n1p3/2ppP3/3P4/2PB1N2/PP3PPP/R1BQ1RK1 b - - 1 8';
  static const fenYourBest =
      '5r1k/5Rb1/p2P2Pp/1p5n/2p5/P4B1P/1pP5/5R1K b - - 2 32';
  static const fenEnding = '1r6/5kp1/7p/8/2p5/6P1/2R2PK1/8 b - - 0 51';

  static Map<String, Object?> exerciseJson(int n) => switch (n) {
    1 => {
      'n': 1,
      'tipo': 'adversario',
      'fen': fenGreekGift,
      'lance': 8,
      'solucao': 'd3h7',
      'jogado': 'O-O',
      'tema': 'sacrificio_h7',
      'estrelas': 2,
      'falas': {
        'enunciado':
            'Lance 8 das brancas. Tiago_Rook jogou 8.O-O, mas tinha um golpe. '
            'Ache o lance dele.',
        'acerto': 'Isso: 8.Bxh7+ abre o rei preto.',
        'erro': 'Não é esse. Procure um lance que dê xeque.',
        'solucao': 'O golpe era 8.Bxh7+: o bispo sai e o rei fica exposto.',
      },
    },
    2 => {
      'n': 2,
      'tipo': 'profilaxia',
      'fen': fenProphylaxis,
      'lance': 8,
      'solucao': 'f7f6',
      'jogado': 'b6',
      'tema': 'profilaxia',
      'estrelas': 2,
      'falas': {
        'enunciado': 'Agora é sua vez. O que as brancas ameaçam? Impeça.',
        'acerto': 'Certo: 8...f6 corta o golpe em h7.',
        'erro': 'As brancas ainda ganham com Bxh7+. Tente de novo.',
        'solucao': '8...f6 ataca o peão de e5 e fecha a diagonal do bispo.',
      },
    },
    3 => {
      'n': 3,
      'tipo': 'seu_melhor',
      'fen': fenYourBest,
      'lance': 32,
      'solucao': 'h5g3',
      'jogado': 'Txf7',
      'tema': 'xeque_duplo',
      'estrelas': 3,
      'falas': {
        'enunciado':
            'Lance 32. Você jogou 32...Txf7. Tinha coisa melhor: ache.',
        'acerto': 'Isso: 32...Cg3+ ganha a torre de f1.',
        'erro': 'Esse ainda deixa as brancas atacando. Procure um xeque.',
        'solucao': '32...Cg3+ dá xeque e ataca a torre de f1 ao mesmo tempo.',
      },
    },
    _ => {
      'n': 4,
      'tipo': 'decisivo',
      'fen': fenEnding,
      'lance': 51,
      'solucao': 'b8c8',
      'jogado': 'Re6',
      'tema': 'final_de_torres',
      'estrelas': 1,
      'falas': {
        'enunciado':
            'Lance 51. Você jogou 51...Re6. Ache o lance que mantém o peão '
            'de c4.',
        'acerto': 'Certo: 51...Tc8 defende o peão por trás.',
        'erro': 'Assim a torre branca ganha o peão de c4.',
        'solucao': '51...Tc8: a torre defende o peão de c4 por trás.',
      },
    },
  };

  /// A partida contra Tiago_Rook já analisada (a das telas do canvas).
  static Map<String, Object?> tiagoJson({
    String status = 'pronta',
    int exercises = 4,
  }) => {
    'url': 'https://lichess.org/AbC12345',
    'jogadaEm': '2026-11-08T21:14:00.000Z',
    'ritmo': 'blitz',
    'cadencia': '5+0',
    'cor': 'pretas',
    'adversario': {'nome': 'Tiago_Rook', 'rating': 1612},
    'rating': 1580,
    'resultado': 'derrota',
    'abertura': {'eco': 'B12', 'nome': 'Defesa Caro-Kann'},
    'pgn': pgnTiago,
    'status': status,
    if (status == 'pronta') ...{
      'resumo': 'Você perdeu no lance 51, num final de torres que empatava.',
      'precisao': 78,
      'exercicios': [for (var n = 1; n <= exercises; n++) exerciseJson(n)],
      'lances': movesTiago(),
      'teoria': {
        'lance': 5,
        'fen': 'rnbqkbnr/pp2pppp/2p5/3pP3/3P4/8/PPP2PPP/RNBQKBNR b KQkq - 0 3',
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
      'fases': {'abertura': 91, 'meio': 74, 'final': 62},
      'temas': [
        'sacrificio_h7',
        'profilaxia',
        'xeque_duplo',
        'final_de_torres',
      ],
      'analisadaEm': '2026-11-08T21:20:00.000Z',
    },
  };

  /// Os 14 meio-lances do PGN da partida contra Tiago_Rook, com 6...Qb6
  /// marcado como erro do usuário (o comentário que a análise mostra).
  static List<Map<String, Object?>> movesTiago() => [
    for (final (i, l) in GameMoves.of(pgnTiago).indexed)
      {
        'san': l.san,
        'fen': l.fen,
        'cp': i == 11 ? 120 : 30,
        'classe': i == 11 ? 'erro' : 'ok',
        if (i == 11) ...{
          'melhor': 'Bd7',
          'comentario':
              'A dama sai cedo e vira alvo. 6...Bd7 terminava o '
              'desenvolvimento.',
        },
      },
  ];

  static const pgnTiago =
      '1. e4 c6 2. d4 d5 3. e5 c5 4. c3 Nc6 5. Nf3 e6 6. Bd3 Qb6 '
      '7. O-O cxd4 *';

  /// As cinco partidas da lista do canvas (da mais nova).
  static Map<String, Map<String, Object?>> jsonList() => {
    idTiago: tiagoJson(),
    'lichess_DeF67890': _simple(
      when_: '2026-11-08T19:02:00.000Z',
      opponent: 'lmatos88',
      rating: 1544,
      timeControl: 'rapida',
      cadence: '10+0',
      color: 'brancas',
      result: 'vitoria',
      eco: 'C50',
      opening: 'Giuoco Piano',
      status: 'nova',
    ),
    'lichess_GhI13579': _simple(
      when_: '2026-11-07T22:40:00.000Z',
      opponent: 'Carla_Fx',
      rating: 1630,
      timeControl: 'blitz',
      cadence: '3+2',
      color: 'pretas',
      result: 'empate',
      eco: 'B12',
      opening: 'Defesa Caro-Kann',
      status: 'analisando',
    ),
    'lichess_JkL24680': _simple(
      when_: '2026-11-06T20:15:00.000Z',
      opponent: 'pedrohsilva',
      rating: 1498,
      timeControl: 'bullet',
      cadence: '1+0',
      color: 'brancas',
      result: 'derrota',
      eco: 'D02',
      opening: 'Sistema Londres',
      status: 'nova',
    ),
    'lichess_MnO11223': _simple(
      when_: '2026-11-05T18:30:00.000Z',
      opponent: 'zugzwang_br',
      rating: 1575,
      timeControl: 'rapida',
      cadence: '15+10',
      color: 'brancas',
      result: 'vitoria',
      eco: 'D02',
      opening: 'Sistema Londres',
      status: 'nova',
    ),
  };

  static Map<String, Object?> _simple({
    required String when_,
    required String opponent,
    required int rating,
    required String timeControl,
    required String cadence,
    required String color,
    required String result,
    required String eco,
    required String opening,
    required String status,
  }) => {
    'jogadaEm': when_,
    'ritmo': timeControl,
    'cadencia': cadence,
    'cor': color,
    'adversario': {'nome': opponent, 'rating': rating},
    'rating': 1580,
    'resultado': result,
    'abertura': {'eco': eco, 'nome': opening},
    'status': status,
  };

  static CoachGame tiago({String status = 'pronta', int exercises = 4}) =>
      CoachGame.fromJson(
        idTiago,
        tiagoJson(status: status, exercises: exercises),
      )!;

  static List<CoachGame> list() {
    final games = [
      for (final e in jsonList().entries) CoachGame.fromJson(e.key, e.value)!,
    ];
    games.sort((a, b) => b.moveAt.compareTo(a.moveAt));
    return games;
  }

  static Map<String, Object?> statsJson() => {
    'partidasAnalisadas': 12,
    'precisaoSemanas': [
      {'semana': '2026-10-19', 'precisao': 71},
      {'semana': '2026-10-26', 'precisao': 74},
      {'semana': '2026-11-02', 'precisao': 78},
    ],
    'errosPorFase': {'abertura': 3, 'meio': 9, 'final': 6},
    'errosPorTema': {
      'final_de_torres': [
        {'partida': idTiago, 'lance': 51, 'fen': fenEnding},
      ],
      'sacrificio_h7': [
        {'partida': idTiago, 'lance': 8, 'fen': fenGreekGift},
      ],
    },
    'aberturas': [
      {
        'nome': 'Defesa Caro-Kann',
        'eco': 'B12',
        'cor': 'pretas',
        'partidas': 6,
        'vitorias': 2,
        'saidaTeoria': {'lance': 5, 'vezes': 4},
      },
      {
        'nome': 'Sistema Londres',
        'eco': 'D02',
        'cor': 'brancas',
        'partidas': 4,
        'vitorias': 3,
      },
    ],
    'estilo': {
      'nivel': 'primeira',
      'fortes': [
        {'texto': 'Ataca bem quando o rei adversário fica no centro.'},
      ],
      'acertar': [
        {
          'texto': 'Perde finais de torres que empatavam.',
          'partidas': 3,
          'tema': 'final_de_torres',
        },
      ],
    },
  };

  static CoachStats stats() => CoachStats.fromJson(statsJson());
}
