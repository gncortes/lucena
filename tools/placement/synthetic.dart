// MAPA E BANCO SINTÉTICOS, só para a simulação da T52 (Parte 4.5) enquanto o
// `assets/placement/skills.json` e o `items.json` de verdade não chegam. Os
// nós, faixas, pré-requisitos e aulas copiam as tabelas 2.1 a 2.7 da T52; as
// perguntas são inventadas (sem posição): só nó, tipo, opções e dificuldade.
// Nada daqui vai para o app.
import 'dart:math';

/// As aulas da escola que existem hoje (`assets/lessons/course.json`), na
/// ordem do curso.
const schoolLessons = [
  'pieces.rook',
  'pieces.bishop',
  'pieces.queen',
  'pieces.king',
  'pieces.knight',
  'pieces.pawn',
  'pieces.check',
  'pieces.stalemate',
  'notation.coordinates',
  'notation.moves',
  'notation.read',
  'mates.twoRooks',
  'mates.queen',
  'tricks.scholarsMate',
  'tricks.defendScholar',
  'tricks.foolsMate',
  'tricks.principles',
  'technique.opposition',
  'technique.zugzwang',
  'technique.rookCut',
  'technique.rookMate',
  'pawns.kingPawn',
  'pawns.square',
  'pawns.rookPawn',
  'pawns.rookTwoPawns',
  'minor.rookBishop',
  'minor.rookKnight',
  'minor.rookTwoBishops',
  'minor.rookTwoKnights',
  'minor.rookBishopKnight',
  'minor.twoRooksVsKnight',
  'graduation.twoBishops',
];

/// As aulas de finais feitas (`assets/lessons/endgames/index.json`).
const endgameLessons = [
  'basics.queenMate',
  'basics.rookMate',
  'basics.twoBishops',
  'basics.kingPawn',
  'mates.bishopKnight.w',
  'mates.bishopKnight.edge',
  'mates.bishopKnight.full',
  'pawns.keySquares',
  'pawns.distantOpposition',
  'queen.vsPawn',
  'queen.vsRook.philidor',
  'queen.vsRook.approach',
  'queen.vsRook.thirdRank',
  'rookPawns.vsPawn',
  'rook.lucena',
  'rook.philidor',
  'rook.backRank',
  'rook.shortSide',
];

const _pieces = [
  'rules.rook',
  'rules.bishop',
  'rules.queen',
  'rules.king',
  'rules.knight',
  'rules.pawn',
];

// (id, grupo, faixa, requer, aulas "id:kind", tática de meio-jogo)
const _nodes = <(String, String, String, List<String>, List<String>, bool)>[
  // 2.1 Regras
  ('rules.rook', 'rules', 'beginner', [], ['pieces.rook:school'], false),
  ('rules.bishop', 'rules', 'beginner', [], ['pieces.bishop:school'], false),
  (
    'rules.queen',
    'rules',
    'beginner',
    ['rules.rook', 'rules.bishop'],
    ['pieces.queen:school'],
    false,
  ),
  ('rules.king', 'rules', 'beginner', [], ['pieces.king:school'], false),
  ('rules.knight', 'rules', 'beginner', [], ['pieces.knight:school'], false),
  ('rules.pawn', 'rules', 'beginner', [], ['pieces.pawn:school'], false),
  (
    'rules.capture',
    'rules',
    'beginner',
    _pieces,
    ['rules.captureProtect:new'],
    false,
  ),
  ('rules.check', 'rules', 'beginner', _pieces, ['pieces.check:school'], false),
  (
    'rules.outOfCheck',
    'rules',
    'beginner',
    ['rules.check'],
    ['rules.outOfCheck:new'],
    false,
  ),
  (
    'rules.stalemate',
    'rules',
    'beginner',
    ['rules.check'],
    ['pieces.stalemate:school'],
    false,
  ),
  (
    'rules.castling',
    'rules',
    'beginner',
    ['rules.king', 'rules.rook'],
    ['rules.castling:new'],
    false,
  ),
  (
    'rules.enPassant',
    'rules',
    'casual',
    ['rules.pawn'],
    ['rules.enPassant:new'],
    false,
  ),
  (
    'rules.draws',
    'rules',
    'casual',
    ['rules.stalemate'],
    ['rules.draws:new'],
    false,
  ),
  (
    'rules.pieceValue',
    'rules',
    'beginner',
    ['rules.capture'],
    ['rules.pieceValue:new'],
    false,
  ),
  (
    'notation.squares',
    'rules',
    'beginner',
    [],
    ['notation.coordinates:school'],
    false,
  ),
  (
    'notation.moves',
    'rules',
    'casual',
    ['notation.squares'],
    ['notation.moves:school', 'notation.read:school'],
    false,
  ),
  // 2.2 Mates
  (
    'mate.inOne',
    'mates',
    'beginner',
    ['rules.check'],
    ['tricks.*:school', 'tactics.matePatterns:new'],
    false,
  ),
  (
    'mate.twoRooks',
    'mates',
    'beginner',
    ['rules.check'],
    ['mates.twoRooks:school'],
    false,
  ),
  (
    'mate.queen',
    'mates',
    'beginner',
    ['mate.twoRooks', 'rules.stalemate'],
    ['mates.queen:school', 'basics.queenMate:endgame'],
    false,
  ),
  (
    'mate.rook',
    'mates',
    'casual',
    ['mate.queen', 'pawns.opposition'],
    [
      'technique.rookCut:school',
      'technique.rookMate:school',
      'basics.rookMate:endgame',
    ],
    false,
  ),
  (
    'mate.patterns',
    'mates',
    'casual',
    ['mate.inOne'],
    ['tactics.matePatterns:new'],
    false,
  ),
  (
    'mate.twoBishops',
    'mates',
    'intermediate',
    ['mate.rook'],
    ['graduation.twoBishops:school', 'basics.twoBishops:endgame'],
    false,
  ),
  (
    'mate.bishopKnight',
    'mates',
    'expert',
    ['mate.twoBishops'],
    [
      'mates.bishopKnight.w:endgame',
      'mates.bishopKnight.edge:endgame',
      'mates.bishopKnight.full:endgame',
    ],
    false,
  ),
  (
    'mate.twoKnightsPawn',
    'mates',
    'master',
    ['mate.bishopKnight'],
    ['mates.twoKnightsPawn:catalog'],
    false,
  ),
  // 2.3 Rei e peões
  (
    'pawns.square',
    'pawns',
    'casual',
    ['rules.pawn'],
    ['pawns.square:school'],
    false,
  ),
  (
    'pawns.opposition',
    'pawns',
    'casual',
    ['rules.king'],
    ['technique.opposition:school', 'technique.zugzwang:school'],
    false,
  ),
  (
    'pawns.kingPawn',
    'pawns',
    'casual',
    ['pawns.opposition'],
    ['pawns.kingPawn:school', 'basics.kingPawn:endgame'],
    false,
  ),
  (
    'pawns.rookPawnDraw',
    'pawns',
    'intermediate',
    ['pawns.kingPawn'],
    ['pawns.rookPawn:school', 'pawns.rookPawn:catalog'],
    false,
  ),
  (
    'pawns.keySquares',
    'pawns',
    'intermediate',
    ['pawns.kingPawn'],
    ['pawns.keySquares:endgame'],
    false,
  ),
  (
    'pawns.distantOpposition',
    'pawns',
    'intermediate',
    ['pawns.opposition'],
    ['pawns.distantOpposition:endgame'],
    false,
  ),
  (
    'pawns.race',
    'pawns',
    'intermediate',
    ['pawns.square'],
    ['pawns.race:catalog'],
    false,
  ),
  (
    'pawns.triangulation',
    'pawns',
    'advanced',
    ['pawns.keySquares'],
    ['pawns.triangulation:catalog'],
    false,
  ),
  (
    'pawns.reti',
    'pawns',
    'advanced',
    ['pawns.square'],
    ['pawns.reti:catalog'],
    false,
  ),
  (
    'pawns.shoulder',
    'pawns',
    'advanced',
    ['pawns.opposition'],
    ['pawns.shoulder:catalog'],
    false,
  ),
  (
    'pawns.breakthrough',
    'pawns',
    'advanced',
    ['pawns.race'],
    ['pawns.breakthrough:catalog'],
    false,
  ),
  (
    'pawns.outsidePasser',
    'pawns',
    'advanced',
    ['pawns.keySquares'],
    ['pawns.outsidePasser:catalog'],
    false,
  ),
  (
    'pawns.protectedPasser',
    'pawns',
    'advanced',
    ['pawns.keySquares'],
    ['pawns.protectedPasser:catalog'],
    false,
  ),
  (
    'pawns.trebuchet',
    'pawns',
    'expert',
    ['pawns.triangulation'],
    ['pawns.minedSquares:catalog'],
    false,
  ),
  (
    'pawns.spareTempi',
    'pawns',
    'expert',
    ['pawns.trebuchet'],
    ['pawns.spareTempi:catalog'],
    false,
  ),
  (
    'pawns.correspondingSquares',
    'pawns',
    'master',
    ['pawns.trebuchet'],
    ['pawns.correspondingSquares:catalog'],
    false,
  ),
  // 2.4 Dama
  (
    'queen.vsPawn',
    'queenRook',
    'intermediate',
    ['mate.queen'],
    ['queen.vsPawn:endgame'],
    false,
  ),
  (
    'queen.vsPawnDraws',
    'queenRook',
    'advanced',
    ['queen.vsPawn'],
    ['queen.vsPawn.draws:catalog'],
    false,
  ),
  (
    'queen.vsRook',
    'queenRook',
    'expert',
    ['queen.vsPawn'],
    [
      'queen.vsRook.philidor:endgame',
      'queen.vsRook.approach:endgame',
      'queen.vsRook.thirdRank:endgame',
    ],
    false,
  ),
  (
    'queen.vsRookPawn',
    'queenRook',
    'master',
    ['queen.vsRook'],
    ['queen.vsRookPawn:catalog'],
    false,
  ),
  (
    'queen.pawnVsQueen',
    'queenRook',
    'master',
    ['queen.vsPawn'],
    ['queen.pawnVsQueen:catalog'],
    false,
  ),
  // 2.5 Torre
  (
    'rook.vsPawn',
    'queenRook',
    'intermediate',
    ['mate.rook'],
    ['rookPawns.vsPawn:endgame'],
    false,
  ),
  (
    'rook.saavedra',
    'queenRook',
    'advanced',
    ['rook.vsPawn', 'rules.stalemate'],
    ['tactics.saavedra:new'],
    false,
  ),
  (
    'rook.vsTwoPawns',
    'queenRook',
    'advanced',
    ['rook.vsPawn'],
    ['rookPawns.vsTwo:catalog'],
    false,
  ),
  (
    'rook.lucena',
    'queenRook',
    'intermediate',
    ['mate.rook'],
    ['rook.lucena:endgame'],
    false,
  ),
  (
    'rook.philidor',
    'queenRook',
    'intermediate',
    ['rook.lucena'],
    ['rook.philidor:endgame'],
    false,
  ),
  (
    'rook.backRank',
    'queenRook',
    'advanced',
    ['rook.philidor'],
    ['rook.backRank:endgame'],
    false,
  ),
  (
    'rook.shortSide',
    'queenRook',
    'advanced',
    ['rook.philidor'],
    ['rook.shortSide:endgame'],
    false,
  ),
  (
    'rook.cutOff',
    'queenRook',
    'advanced',
    ['rook.lucena'],
    ['rook.cutOff:catalog'],
    false,
  ),
  (
    'rook.frontal',
    'queenRook',
    'advanced',
    ['rook.cutOff'],
    ['rook.frontal:catalog'],
    false,
  ),
  (
    'rook.rookPawn',
    'queenRook',
    'expert',
    ['rook.philidor'],
    ['rook.rookPawn.kingFront:catalog', 'rook.rookPawn.seventh:catalog'],
    false,
  ),
  (
    'rook.vancura',
    'queenRook',
    'expert',
    ['rook.rookPawn'],
    ['rook.vancura:catalog'],
    false,
  ),
  (
    'rook.behindPasser',
    'queenRook',
    'advanced',
    ['rook.lucena'],
    ['rook.behindPasser:catalog'],
    false,
  ),
  (
    'rook.twoPawns',
    'queenRook',
    'expert',
    ['rook.lucena'],
    ['rook.twoPawns:catalog'],
    false,
  ),
  (
    'rook.practical',
    'queenRook',
    'expert',
    ['rook.behindPasser'],
    [
      'rook.activity:catalog',
      'rook.fourVsThree:catalog',
      'rook.outsidePasser:catalog',
    ],
    false,
  ),
  // 2.6 Peças menores
  (
    'minor.wrongBishop',
    'minor',
    'intermediate',
    ['pawns.rookPawnDraw'],
    ['minor.wrongBishop:catalog'],
    false,
  ),
  (
    'minor.knightVsPawn',
    'minor',
    'intermediate',
    ['rules.knight'],
    ['minor.knightVsPawn:catalog'],
    false,
  ),
  (
    'minor.bishopVsPawns',
    'minor',
    'advanced',
    ['minor.wrongBishop'],
    ['minor.bishopVsPawns:catalog'],
    false,
  ),
  (
    'minor.oppositeBishops',
    'minor',
    'advanced',
    ['minor.bishopVsPawns'],
    ['minor.oppositeBishops.*:catalog'],
    false,
  ),
  (
    'minor.centurini',
    'minor',
    'expert',
    ['minor.oppositeBishops'],
    ['minor.centurini:catalog'],
    false,
  ),
  (
    'minor.knightEndings',
    'minor',
    'expert',
    ['minor.knightVsPawn'],
    ['minor.knightPawnVsKnight:catalog'],
    false,
  ),
  (
    'minor.bishopVsKnight',
    'minor',
    'expert',
    ['minor.oppositeBishops'],
    ['minor.bishopVsKnight:catalog', 'minor.goodBadBishop:catalog'],
    false,
  ),
  (
    'rookMinor.vsMinor',
    'minor',
    'expert',
    ['mate.rook'],
    ['rookMinor.vsBishop:catalog', 'rookMinor.vsKnight:catalog'],
    false,
  ),
  (
    'rookMinor.exchange',
    'minor',
    'master',
    ['rookMinor.vsMinor'],
    ['rookMinor.exchange:catalog'],
    false,
  ),
  (
    'rookMinor.vsRook',
    'minor',
    'master',
    ['rookMinor.vsMinor'],
    ['rookMinor.knightVsRook:catalog'],
    false,
  ),
  (
    'school.minorMates',
    'minor',
    'casual',
    ['mate.rook'],
    ['minor.*:school'],
    false,
  ),
  // 2.7 Tática
  (
    'tactics.basic',
    'tactics',
    'casual',
    ['rules.pieceValue'],
    ['tricks.*:school'],
    true,
  ),
  (
    'tactics.endgame',
    'tactics',
    'advanced',
    ['tactics.basic'],
    ['tactics.endgameTricks:new'],
    false,
  ),
];

/// O `skills.json` sintético, no formato do contrato.
Map<String, dynamic> syntheticSkillsJson() => {
  'nodes': [
    for (final (id, group, band, requires, lessons, midgame) in _nodes)
      {
        'id': id,
        'group': group,
        'band': band,
        'requires': requires,
        'lessons': [
          for (final lesson in lessons)
            {
              'id': lesson.substring(0, lesson.lastIndexOf(':')),
              'kind': lesson.substring(lesson.lastIndexOf(':') + 1),
            },
        ],
        'midgameTactic': midgame,
      },
  ],
};

/// O centro de dificuldade de cada faixa e a meia-largura do sorteio.
const _center = {
  'beginner': (700, 300),
  'casual': (1150, 200),
  'intermediate': (1450, 200),
  'advanced': (1750, 200),
  'expert': (2050, 200),
  'master': (2400, 200),
};

/// Nós cujas perguntas são de tocar casas (as peças).
const _squaresNodes = {..._pieces, 'notation.squares'};

/// Nós de regra com pergunta de opções ("é mate, afogamento ou nada?").
const _choiceRules = {
  'rules.check',
  'rules.outOfCheck',
  'rules.stalemate',
  'rules.castling',
  'rules.enPassant',
  'rules.draws',
  'rules.pieceValue',
};

/// O `items.json` sintético: 6 perguntas por nó das tabelas 2.1 a 2.3 e 4
/// das 2.4 a 2.7 (as cotas mínimas da Parte 3.3), dificuldade sorteada em
/// volta do centro da faixa do nó, entre 400 e 2600.
Map<String, dynamic> syntheticItemsJson({int seed = 52}) {
  final random = Random(seed);
  final items = <Map<String, dynamic>>[];
  for (final (id, group, band, _, _, _) in _nodes) {
    final count = const {'rules', 'mates', 'pawns'}.contains(group) ? 6 : 4;
    final (center, spread) = _center[band]!;
    for (var i = 0; i < count; i++) {
      // Espalhadas de ponta a ponta da faixa, com um pouco de ruído.
      final offset = -spread + 2 * spread * (i + 0.5) / count;
      final difficulty = (center + offset + random.nextInt(81) - 40)
          .clamp(400, 2600)
          .round();
      final String type;
      if (_squaresNodes.contains(id)) {
        type = 'squares';
      } else if (_choiceRules.contains(id)) {
        type = i.isEven ? 'choice' : 'move';
      } else if (group == 'pawns' || group == 'queenRook' || group == 'minor') {
        type = i % 3 == 2 ? 'choice' : 'move';
      } else {
        type = 'move';
      }
      final options = type != 'choice'
          ? const <String>[]
          : (id == 'rules.stalemate' || i % 2 == 1)
          ? const ['mate', 'stalemate', 'none']
          : const ['win', 'draw'];
      items.add({
        'id': 'synthetic.$id.${i + 1}',
        'node': id,
        'type': type,
        'difficulty': difficulty,
        'fen': '8/8/8/8/8/8/8/8 w - - 0 1',
        'prompt': 'placementSynthetic',
        if (options.isNotEmpty) 'options': options,
        if (options.isNotEmpty) 'answer': options.first,
        'source': 'own',
      });
    }
  }
  return {'items': items};
}
