import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';

/// Um mapa pequeno, no formato do contrato da T52, para os testes de
/// diagnóstico e de roteiro.
final smallSkillsJson = <String, dynamic>{
  'nodes': [
    {
      'id': 'rules.rook',
      'group': 'rules',
      'band': 'beginner',
      'requires': <String>[],
      'lessons': [
        {'id': 'pieces.rook', 'kind': 'school'},
      ],
    },
    {
      'id': 'rules.bishop',
      'group': 'rules',
      'band': 'beginner',
      'lessons': [
        {'id': 'pieces.bishop', 'kind': 'school'},
      ],
    },
    {
      'id': 'rules.queen',
      'group': 'rules',
      'band': 'beginner',
      'requires': ['rules.rook', 'rules.bishop'],
      'lessons': [
        {'id': 'pieces.queen', 'kind': 'school'},
      ],
    },
    {
      'id': 'mate.queen',
      'group': 'mates',
      'band': 'beginner',
      'requires': ['rules.queen'],
      'lessons': [
        {'id': 'mates.queen', 'kind': 'school'},
        {'id': 'basics.queenMate', 'kind': 'endgame'},
      ],
    },
    {
      'id': 'pawns.opposition',
      'group': 'pawns',
      'band': 'casual',
      'lessons': [
        {'id': 'technique.opposition', 'kind': 'school'},
      ],
    },
    {
      'id': 'rook.lucena',
      'group': 'queenRook',
      'band': 'intermediate',
      'requires': ['mate.queen'],
      'lessons': [
        {'id': 'rook.lucena', 'kind': 'endgame'},
      ],
    },
    {
      'id': 'rook.philidor',
      'group': 'queenRook',
      'band': 'intermediate',
      'requires': ['rook.lucena'],
      'lessons': [
        {'id': 'rook.philidor', 'kind': 'endgame'},
      ],
    },
    {
      'id': 'pawns.reti',
      'group': 'pawns',
      'band': 'advanced',
      'requires': ['pawns.opposition'],
      'lessons': [
        {'id': 'pawns.reti', 'kind': 'catalog'},
      ],
    },
    {
      'id': 'tactics.basic',
      'group': 'tactics',
      'band': 'casual',
      'lessons': [
        {'id': 'tricks.*', 'kind': 'school'},
      ],
      'midgameTactic': true,
    },
    {
      'id': 'tactics.endgame',
      'group': 'tactics',
      'band': 'advanced',
      'requires': ['tactics.basic'],
      'lessons': [
        {'id': 'tactics.endgameTricks', 'kind': 'new'},
      ],
    },
  ],
};

SkillMap smallSkills() => SkillMap.fromJson(smallSkillsJson);

const smallSchool = [
  'pieces.rook',
  'pieces.bishop',
  'pieces.queen',
  'mates.queen',
  'tricks.scholarsMate',
  'tricks.foolsMate',
  'technique.opposition',
];

const smallEndgames = ['basics.queenMate', 'rook.lucena', 'rook.philidor'];

/// Um resultado com estes estados (o resto fica desconhecido).
PlacementResult resultWith(Map<String, NodeStatus> nodes, {int theta = 1450}) =>
    PlacementResult(
      theta: theta,
      low: theta - 100,
      high: theta + 100,
      nodes: nodes,
      takenAt: DateTime.utc(2026, 10, 8),
    );

const mastered = NodeStatus(NodeState.mastered, confirmed: true);
const likely = NodeStatus(NodeState.likely);
const gap = NodeStatus(NodeState.gap, confirmed: true);
const unknown = NodeStatus.unknown;

/// Uma pergunta de [node] com dificuldade [difficulty].
PlacementItem item(
  String id,
  String node,
  int difficulty, {
  PlacementItemType type = PlacementItemType.move,
}) => PlacementItem(
  id: id,
  node: node,
  type: type,
  difficulty: difficulty,
  fen: '8/8/8/8/8/8/8/8 w - - 0 1',
  prompt: 'placementTest',
  options: type == PlacementItemType.choice ? const ['win', 'draw'] : const [],
  answer: type == PlacementItemType.choice ? 'win' : null,
);

/// Uma resposta já dada (para montar estados à mão).
PlacementAnswer answered(
  String itemId,
  String node, {
  required int index,
  bool correct = true,
  int difficulty = 1200,
}) => PlacementAnswer(
  itemId: itemId,
  node: node,
  difficulty: difficulty,
  outcome: correct ? PlacementOutcome.correct : PlacementOutcome.wrong,
  phase: PlacementPhase.of(index),
);

/// O meio de cada faixa, para os testes falarem em faixas.
int mid(RatingLevel level) => level.rating;
