import 'rating_level.dart';

// O teste de nível (T52): o mapa de habilidades, o banco de perguntas, o teste
// em andamento e o resultado. Os formatos de `skills.json` e `items.json` são
// os do "Contrato entre as partes" em `docs/tasks/T52.md`.

/// A área de um nó do mapa. Também é a coluna do blueprint do teste.
enum SkillGroup {
  rules,
  mates,
  pawns,
  queenRook,
  minor,
  tactics;

  static SkillGroup parse(String code) =>
      values.asNameMap()[code] ??
      (throw FormatException('grupo de habilidade desconhecido: $code'));
}

/// De onde vem uma aula ligada a um nó.
enum SkillLessonKind {
  /// Aula da Escola do Viktor.
  school('school'),

  /// Aula de finais já feita.
  endgame('endgame'),

  /// Aula de finais do catálogo, ainda não feita.
  catalog('catalog'),

  /// Aula proposta na Parte 6 da T52, ainda não feita.
  proposed('new');

  const SkillLessonKind(this.code);

  /// O nome no `skills.json`.
  final String code;

  static SkillLessonKind parse(String code) => values.firstWhere(
    (kind) => kind.code == code,
    orElse: () => throw FormatException('tipo de aula desconhecido: $code'),
  );
}

/// Uma aula que ensina um nó. O id pode terminar em `.*` (`tricks.*`): vale
/// para todas as aulas com esse prefixo.
class SkillLesson {
  const SkillLesson({required this.id, required this.kind});

  factory SkillLesson.fromJson(Map<String, dynamic> json) => SkillLesson(
    id: json['id'] as String,
    kind: SkillLessonKind.parse(json['kind'] as String),
  );

  final String id;
  final SkillLessonKind kind;

  /// Se [lessonId] é esta aula (ou uma das do prefixo, quando o id tem `.*`).
  bool matches(String lessonId) => id.endsWith('.*')
      ? lessonId.startsWith(id.substring(0, id.length - 1))
      : lessonId == id;

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind.code};
}

/// Um nó do mapa de habilidades: o que o jogador sabe ou não.
class SkillNode {
  const SkillNode({
    required this.id,
    required this.group,
    required this.band,
    this.requires = const [],
    this.lessons = const [],
    this.midgameTactic = false,
  });

  factory SkillNode.fromJson(Map<String, dynamic> json) => SkillNode(
    id: json['id'] as String,
    group: SkillGroup.parse(json['group'] as String),
    band: RatingLevel.values.byName(json['band'] as String),
    requires: [for (final id in json['requires'] as List? ?? []) id as String],
    lessons: [
      for (final lesson in json['lessons'] as List? ?? [])
        SkillLesson.fromJson(lesson as Map<String, dynamic>),
    ],
    midgameTactic: json['midgameTactic'] as bool? ?? false,
  );

  /// `rules.bishop`, `pawns.reti`... O nome na tela vem do `.arb`
  /// (`skillRulesBishop`).
  final String id;
  final SkillGroup group;

  /// A faixa em que se espera o domínio do nó.
  final RatingLevel band;

  /// Os pré-requisitos diretos.
  final List<String> requires;
  final List<SkillLesson> lessons;

  /// Tática de meio-jogo: a lacuna fica registrada no resultado, mas o
  /// roteiro nunca manda para ela (decisão do Gabriel, 2026-10-08).
  final bool midgameTactic;

  Map<String, dynamic> toJson() => {
    'id': id,
    'group': group.name,
    'band': band.name,
    'requires': requires,
    'lessons': [for (final lesson in lessons) lesson.toJson()],
    'midgameTactic': midgameTactic,
  };
}

/// O mapa de habilidades, com os nós em ordem topológica (todo nó depois dos
/// seus pré-requisitos; empate pela ordem do arquivo).
class SkillMap {
  SkillMap._(this.nodes, this._index);

  /// Monta o mapa e confere: ids únicos, pré-requisitos existentes e nenhum
  /// ciclo. Lança [FormatException] se algo falhar.
  factory SkillMap(List<SkillNode> nodes) {
    final byId = <String, SkillNode>{};
    for (final node in nodes) {
      if (byId.containsKey(node.id)) {
        throw FormatException('nó repetido no mapa: ${node.id}');
      }
      byId[node.id] = node;
    }
    for (final node in nodes) {
      for (final id in node.requires) {
        if (!byId.containsKey(id)) {
          throw FormatException('${node.id} requer um nó que não existe: $id');
        }
      }
    }
    // Kahn, sempre pegando o primeiro pronto na ordem do arquivo.
    final sorted = <SkillNode>[];
    final done = <String>{};
    while (sorted.length < nodes.length) {
      final ready = nodes.where(
        (node) => !done.contains(node.id) && node.requires.every(done.contains),
      );
      if (ready.isEmpty) {
        final left = nodes.where((node) => !done.contains(node.id));
        throw FormatException(
          'ciclo nos pré-requisitos: ${left.map((n) => n.id).join(', ')}',
        );
      }
      final node = ready.first;
      sorted.add(node);
      done.add(node.id);
    }
    return SkillMap._(List.unmodifiable(sorted), {
      for (var i = 0; i < sorted.length; i++) sorted[i].id: i,
    });
  }

  factory SkillMap.fromJson(Map<String, dynamic> json) => SkillMap([
    for (final node in json['nodes'] as List)
      SkillNode.fromJson(node as Map<String, dynamic>),
  ]);

  static final empty = SkillMap(const []);

  /// Os nós em ordem topológica.
  final List<SkillNode> nodes;
  final Map<String, int> _index;

  SkillNode? node(String id) {
    final index = _index[id];
    return index == null ? null : nodes[index];
  }

  bool contains(String id) => _index.containsKey(id);

  /// A posição do nó na ordem topológica (-1 se não existe).
  int indexOf(String id) => _index[id] ?? -1;

  /// Todos os pré-requisitos de [id], diretos e indiretos (sem ele mesmo).
  Set<String> prerequisitesOf(String id) {
    final result = <String>{};
    final pending = [...?node(id)?.requires];
    while (pending.isNotEmpty) {
      final next = pending.removeLast();
      if (result.add(next)) pending.addAll(node(next)?.requires ?? const []);
    }
    return result;
  }

  /// Todos os nós que dependem de [id], direta ou indiretamente.
  Set<String> dependentsOf(String id) {
    final result = <String>{};
    final pending = [id];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final node in nodes) {
        if (node.requires.contains(current) && result.add(node.id)) {
          pending.add(node.id);
        }
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'nodes': [for (final node in nodes) node.toJson()],
  };
}

/// Como o jogador responde uma pergunta.
enum PlacementItemType {
  /// Toca em todas as casas certas.
  squares,

  /// Acha o lance (ou a linha curta).
  move,

  /// Escolhe uma entre 2 e 4 opções.
  choice,
}

/// De onde vem a pergunta.
enum PlacementSource { own, lichess }

/// Uma pergunta do banco (`items.json`).
class PlacementItem {
  const PlacementItem({
    required this.id,
    required this.node,
    required this.type,
    required this.difficulty,
    required this.fen,
    required this.prompt,
    this.params = const {},
    this.squares = const [],
    this.moves = const [],
    this.accept = const [],
    this.options = const [],
    this.answer,
    this.source = PlacementSource.own,
    this.themes = const [],
    this.lastMove,
  });

  factory PlacementItem.fromJson(Map<String, dynamic> json) => PlacementItem(
    id: json['id'] as String,
    node: json['node'] as String,
    type: PlacementItemType.values.byName(json['type'] as String),
    difficulty: (json['difficulty'] as num).round(),
    fen: json['fen'] as String,
    prompt: json['prompt'] as String,
    params: {
      for (final entry
          in (json['params'] as Map<String, dynamic>? ?? const {}).entries)
        entry.key: '${entry.value}',
    },
    squares: _strings(json['squares']),
    moves: _strings(json['moves']),
    accept: [for (final turn in json['accept'] as List? ?? []) _strings(turn)],
    options: _strings(json['options']),
    answer: json['answer'] as String?,
    source: PlacementSource.values.byName(json['source'] as String? ?? 'own'),
    themes: _strings(json['themes']),
    lastMove: json['lastMove'] as String?,
  );

  /// `own.rules.bishop.1` ou `lichess.<PuzzleId>`.
  final String id;

  /// O nó do mapa que a pergunta testa.
  final String node;
  final PlacementItemType type;

  /// Dificuldade na escala do rating de finais do app.
  final int difficulty;
  final String fen;

  /// A chave do `.arb` com o enunciado e os parâmetros dele.
  final String prompt;
  final Map<String, String> params;

  /// `squares`: todas as casas certas.
  final List<String> squares;

  /// `move`: a linha em UCI, lances do jogador e respostas alternados.
  final List<String> moves;

  /// `move`: os lances aceitos em cada vez do jogador (vazio: só o da linha).
  final List<List<String>> accept;

  /// `choice`: as opções (chaves `placementOption*`).
  final List<String> options;

  /// `choice`: a opção certa.
  final String? answer;
  final PlacementSource source;
  final List<String> themes;

  /// O lance que levou à posição (UCI), para destacar no tabuleiro: o do
  /// adversário nos puzzles do Lichess e o do peão no en passant.
  final String? lastMove;

  /// Quantas opções a pergunta tem (0 se não for `choice`): o chute vale 1/k.
  int get optionCount => type == PlacementItemType.choice ? options.length : 0;

  /// Quantos lances o jogador faz numa pergunta `move`.
  int get playerMoves => (moves.length + 1) ~/ 2;

  /// Se [uci] vale na vez [turn] do jogador (0 é o primeiro lance).
  bool acceptsMove(int turn, String uci) {
    final alias = _castlingAlias[uci];
    if (alias != null && _acceptsMove(turn, alias)) return true;
    return _acceptsMove(turn, uci);
  }

  // O roque chega do tabuleiro como o rei tomando a torre (e1h1) e está na
  // linha como o rei andando duas casas (e1g1), ou o contrário.
  static const _castlingAlias = {
    'e1h1': 'e1g1',
    'e1a1': 'e1c1',
    'e8h8': 'e8g8',
    'e8a8': 'e8c8',
    'e1g1': 'e1h1',
    'e1c1': 'e1a1',
    'e8g8': 'e8h8',
    'e8c8': 'e8a8',
  };

  bool _acceptsMove(int turn, String uci) {
    if (turn < accept.length && accept[turn].isNotEmpty) {
      return accept[turn].contains(uci);
    }
    return 2 * turn < moves.length && moves[2 * turn] == uci;
  }

  /// Se o jogador marcou exatamente as casas certas.
  bool acceptsSquares(Iterable<String> picked) {
    final set = picked.toSet();
    return set.length == squares.toSet().length && set.containsAll(squares);
  }

  bool acceptsChoice(String option) => option == answer;

  Map<String, dynamic> toJson() => {
    'id': id,
    'node': node,
    'type': type.name,
    'difficulty': difficulty,
    'fen': fen,
    'prompt': prompt,
    if (params.isNotEmpty) 'params': params,
    if (squares.isNotEmpty) 'squares': squares,
    if (moves.isNotEmpty) 'moves': moves,
    if (accept.isNotEmpty) 'accept': accept,
    if (options.isNotEmpty) 'options': options,
    if (answer != null) 'answer': answer,
    'source': source.name,
    if (themes.isNotEmpty) 'themes': themes,
    'lastMove': ?lastMove,
  };

  static List<String> _strings(Object? json) => [
    for (final value in json as List? ?? const []) value as String,
  ];
}

/// O banco de perguntas.
class PlacementBank {
  PlacementBank(List<PlacementItem> items)
    : items = List.unmodifiable(items),
      _byId = {for (final item in items) item.id: item};

  factory PlacementBank.fromJson(Map<String, dynamic> json) => PlacementBank([
    for (final item in json['items'] as List)
      PlacementItem.fromJson(item as Map<String, dynamic>),
  ]);

  final List<PlacementItem> items;
  final Map<String, PlacementItem> _byId;

  PlacementItem? item(String id) => _byId[id];

  Map<String, dynamic> toJson() => {
    'items': [for (final item in items) item.toJson()],
  };
}

/// O resultado de uma resposta. "Não sei" conta como erro.
enum PlacementOutcome {
  correct,
  wrong,
  dontKnow;

  /// O placar da "partida" entre o jogador e a pergunta.
  double get score => this == correct ? 1 : 0;
}

/// A fase do teste em que uma pergunta caiu. O jogador não vê as fases.
enum PlacementPhase {
  /// Perguntas 1 a 4: saltar rápido para a região certa.
  screening,

  /// Perguntas 5 a 16: afinar a estimativa e cobrir os temas da faixa.
  adaptation,

  /// Perguntas 17 a 20: a fronteira entre as faixas e as lacunas.
  confirmation;

  /// A fase da pergunta de índice [index] (0 é a primeira).
  static PlacementPhase of(int index) => index < 4
      ? screening
      : index < 16
      ? adaptation
      : confirmation;
}

/// Uma resposta dada. Guarda o nó e a dificuldade da pergunta para o
/// resultado não depender do banco (que pode mudar numa atualização do app).
class PlacementAnswer {
  const PlacementAnswer({
    required this.itemId,
    required this.node,
    required this.difficulty,
    required this.outcome,
    required this.phase,
    this.options = 0,
    this.elapsed = Duration.zero,
    this.thetaAfter,
  });

  factory PlacementAnswer.fromJson(Map<String, dynamic> json) =>
      PlacementAnswer(
        itemId: json['item'] as String,
        node: json['node'] as String,
        difficulty: (json['difficulty'] as num).round(),
        outcome: PlacementOutcome.values.byName(json['outcome'] as String),
        phase: PlacementPhase.values.byName(json['phase'] as String),
        options: json['options'] as int? ?? 0,
        elapsed: Duration(milliseconds: json['ms'] as int? ?? 0),
        thetaAfter: (json['theta'] as num?)?.toDouble(),
      );

  final String itemId;
  final String node;
  final int difficulty;
  final PlacementOutcome outcome;
  final PlacementPhase phase;

  /// As opções da pergunta, se era `choice` (0 nas outras).
  final int options;

  /// O tempo de resposta. Só vira evidência extra no nó, nunca mexe em θ.
  final Duration elapsed;

  /// A estimativa depois desta resposta.
  final double? thetaAfter;

  bool get correct => outcome == PlacementOutcome.correct;
  bool get isChoice => options > 0;

  Map<String, dynamic> toJson() => {
    'item': itemId,
    'node': node,
    'difficulty': difficulty,
    'outcome': outcome.name,
    'phase': phase.name,
    'options': options,
    'ms': elapsed.inMilliseconds,
    if (thetaAfter != null) 'theta': thetaAfter,
  };
}

/// O que as respostas dizem de um nó.
class NodeEvidence {
  const NodeEvidence({
    this.correct = 0,
    this.wrong = 0,
    this.fastCorrect = 0,
    this.lastCorrect = false,
  });

  factory NodeEvidence.fromJson(Map<String, dynamic> json) => NodeEvidence(
    correct: json['correct'] as int? ?? 0,
    wrong: json['wrong'] as int? ?? 0,
    fastCorrect: json['fast'] as int? ?? 0,
    lastCorrect: json['last'] as bool? ?? false,
  );

  final int correct;

  /// Erros e "não sei".
  final int wrong;

  /// Acertos rápidos em perguntas fáceis para o jogador (d < θ − 300, em menos
  /// da metade da mediana de tempo dele no teste). Medido, não decide nada.
  final int fastCorrect;

  /// Se a última resposta no nó foi certa (é ela que decide quando há acerto
  /// e erro).
  final bool lastCorrect;

  int get total => correct + wrong;
  bool get mixed => correct > 0 && wrong > 0;

  NodeEvidence add({required bool correct, bool fast = false}) => NodeEvidence(
    correct: this.correct + (correct ? 1 : 0),
    wrong: wrong + (correct ? 0 : 1),
    fastCorrect: fastCorrect + (correct && fast ? 1 : 0),
    lastCorrect: correct,
  );

  Map<String, dynamic> toJson() => {
    'correct': correct,
    'wrong': wrong,
    'fast': fastCorrect,
    'last': lastCorrect,
  };
}

/// O teste em andamento. Gravado depois de cada resposta: fechar à força
/// retoma na mesma pergunta, porque a escolha da próxima só depende deste
/// estado e da semente.
class PlacementState {
  const PlacementState({
    required this.theta,
    required this.initialTheta,
    required this.seed,
    this.answered = const [],
    this.evidence = const {},
  });

  factory PlacementState.fromJson(Map<String, dynamic> json) => PlacementState(
    theta: (json['theta'] as num).toDouble(),
    initialTheta: (json['initialTheta'] as num).toDouble(),
    seed: json['seed'] as int,
    answered: [
      for (final answer in json['answered'] as List? ?? [])
        PlacementAnswer.fromJson(answer as Map<String, dynamic>),
    ],
    evidence: {
      for (final entry
          in (json['evidence'] as Map<String, dynamic>? ?? const {}).entries)
        entry.key: NodeEvidence.fromJson(entry.value as Map<String, dynamic>),
    },
  );

  /// O teste tem sempre 20 perguntas.
  static const questionCount = 20;

  /// A estimativa atual, na escala do rating de finais do app.
  final double theta;

  /// A estimativa antes da primeira pergunta (1200 ou o meio da faixa já
  /// escolhida). A triagem parte dela.
  final double initialTheta;

  /// Semente do sorteio "randomesque".
  final int seed;
  final List<PlacementAnswer> answered;

  /// Acertos e erros diretos por nó.
  final Map<String, NodeEvidence> evidence;

  /// O número da próxima pergunta (1 a 20), ou 21 no fim.
  int get questionNumber => answered.length + 1;

  bool get isFinished => answered.length >= questionCount;

  /// A fase da próxima pergunta. Nula no fim.
  PlacementPhase? get phase =>
      isFinished ? null : PlacementPhase.of(answered.length);

  Set<String> get usedItems => {for (final answer in answered) answer.itemId};

  int get choiceCount => answered.where((answer) => answer.isChoice).length;

  PlacementState copyWith({
    double? theta,
    List<PlacementAnswer>? answered,
    Map<String, NodeEvidence>? evidence,
  }) => PlacementState(
    theta: theta ?? this.theta,
    initialTheta: initialTheta,
    seed: seed,
    answered: answered ?? this.answered,
    evidence: evidence ?? this.evidence,
  );

  Map<String, dynamic> toJson() => {
    'theta': theta,
    'initialTheta': initialTheta,
    'seed': seed,
    'answered': [for (final answer in answered) answer.toJson()],
    'evidence': {
      for (final entry in evidence.entries) entry.key: entry.value.toJson(),
    },
  };
}

/// O estado de um nó depois do teste.
enum NodeState {
  /// Domina (acertou, ou é pré-requisito de um nó que domina).
  mastered,

  /// Provável que saiba: inferido pela faixa ou pelos pré-requisitos.
  likely,

  /// Sem evidência: não entra no "já domina" nem no "falta".
  unknown,

  /// Lacuna: errou.
  gap,
}

/// O diagnóstico de um nó: o estado e se veio de resposta direta
/// (`confirmed`) ou de inferência.
class NodeStatus {
  const NodeStatus(this.state, {this.confirmed = false});

  factory NodeStatus.fromJson(Map<String, dynamic> json) => NodeStatus(
    NodeState.values.byName(json['state'] as String),
    confirmed: json['confirmed'] as bool? ?? false,
  );

  static const unknown = NodeStatus(NodeState.unknown);

  final NodeState state;
  final bool confirmed;

  /// O teste dispensa o nó (domina ou provável).
  bool get skippable =>
      state == NodeState.mastered || state == NodeState.likely;

  bool get isGap => state == NodeState.gap;

  @override
  bool operator ==(Object other) =>
      other is NodeStatus &&
      other.state == state &&
      other.confirmed == confirmed;

  @override
  int get hashCode => Object.hash(state, confirmed);

  @override
  String toString() => '${state.name}${confirmed ? '' : '?'}';

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'confirmed': confirmed,
  };
}

/// O resultado do teste, gravado com a data. O roteiro é recalculado a partir
/// dele e do progresso real.
class PlacementResult {
  const PlacementResult({
    required this.theta,
    required this.low,
    required this.high,
    required this.nodes,
    required this.takenAt,
    this.answers = const [],
  });

  factory PlacementResult.fromJson(Map<String, dynamic> json) =>
      PlacementResult(
        theta: json['theta'] as int,
        low: json['low'] as int,
        high: json['high'] as int,
        nodes: {
          for (final entry in (json['nodes'] as Map<String, dynamic>).entries)
            entry.key: NodeStatus.fromJson(entry.value as Map<String, dynamic>),
        },
        takenAt: DateTime.parse(json['takenAt'] as String),
        answers: [
          for (final answer in json['answers'] as List? ?? [])
            PlacementAnswer.fromJson(answer as Map<String, dynamic>),
        ],
      );

  /// A estimativa final, arredondada, em [400, 2800].
  final int theta;

  /// O intervalo plausível (pela verossimilhança das respostas).
  final int low;
  final int high;

  /// O estado de cada nó do mapa.
  final Map<String, NodeStatus> nodes;

  /// Quando o teste terminou (vem do `Now` de quem chama).
  final DateTime takenAt;

  /// As respostas, para a revisão no fim.
  final List<PlacementAnswer> answers;

  /// A faixa de θ.
  RatingLevel get level => RatingLevel.of(theta);

  /// As faixas que o intervalo cruza, da mais fraca à mais forte. Com mais de
  /// uma, a tela mostra as opções e o jogador escolhe.
  List<RatingLevel> get levels => [
    for (
      var index = RatingLevel.of(low).index;
      index <= RatingLevel.of(high).index;
      index++
    )
      RatingLevel.values[index],
  ];

  NodeStatus status(String node) => nodes[node] ?? NodeStatus.unknown;

  Map<String, dynamic> toJson() => {
    'theta': theta,
    'low': low,
    'high': high,
    'nodes': {
      for (final entry in nodes.entries) entry.key: entry.value.toJson(),
    },
    'takenAt': takenAt.toIso8601String(),
    'answers': [for (final answer in answers) answer.toJson()],
  };
}
