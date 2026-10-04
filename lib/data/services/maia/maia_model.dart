import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';

import 'maia_network.dart';
import 'maia_weights.dart';

/// O que o Maia prevê para uma posição.
class MaiaEvaluation {
  const MaiaEvaluation({
    required this.policy,
    required this.win,
    required this.draw,
    required this.loss,
    required this.ponder,
    this.elapsed = Duration.zero,
  });

  /// A chance de um jogador humano fazer cada lance legal (UCI, como `e2e4`,
  /// `e7e8q` e roque `e1g1`), do mais provável para o menos. Soma 1.
  final Map<String, double> policy;

  /// Chance de quem joga ganhar, empatar e perder a partida.
  final double win;
  final double draw;
  final double loss;

  /// Saída bruta da cabeça de tempo de reflexão do modelo.
  final double ponder;

  /// Quanto a conta levou (preenchido pelo `MaiaService`).
  final Duration elapsed;
}

/// O Maia-3 pronto para avaliar posições: monta a entrada a partir das
/// posições do `dartchess`, roda a [MaiaNetwork] e traduz a saída em lances.
///
/// Segue o `maia3/uci.py` oficial com `--use-uci-history`: a rede vê a posição
/// do ponto de vista de quem joga (para as pretas o tabuleiro é espelhado) e
/// as posições anteriores da partida.
class MaiaModel {
  MaiaModel(MaiaWeights weights) : _network = MaiaNetwork(weights);

  final MaiaNetwork _network;

  /// Avalia a última posição de [history] (da mais antiga para a atual; só as
  /// últimas [MaiaConfig.history] contam). [selfElo] é o rating de quem joga e
  /// [oppoElo] o do oponente.
  MaiaEvaluation evaluate(
    List<Position> history, {
    required int selfElo,
    required int oppoElo,
  }) {
    final position = history.last;
    _network.run(encode(history), selfElo: selfElo, oppoElo: oppoElo);

    final logits = <String, double>{};
    final flip = position.turn == Side.black;
    for (final MapEntry(key: from, value: targets)
        in position.legalMoves.entries) {
      final role = position.board.roleAt(from);
      for (final to in targets.squares) {
        // O dartchess dá o roque como "rei toma a própria torre"; o modelo
        // (e o UCI) usam a casa de chegada do rei.
        final isCastling =
            role == Role.king && position.board.sideAt(to) == position.turn;
        final target = isCastling
            ? Square((from & 56) | (to > from ? 6 : 2))
            : to;
        final f = flip ? from ^ 56 : from;
        final t = flip ? target ^ 56 : target;
        final uci = from.name + target.name;
        if (role == Role.pawn && SquareSet.backranks.has(to)) {
          for (var piece = 0; piece < _promotions.length; piece++) {
            logits[uci + _promotions[piece].letter] = _network.promotionLogit(
              f & 7,
              t & 7,
              piece,
            );
          }
        } else {
          logits[uci] = _network.moveLogit(f, t);
        }
      }
    }

    final value = _softmax(_network.valueLogits);
    final probabilities = _softmax(logits.values.toList());
    final moves = logits.keys.toList();
    final order = List.generate(moves.length, (i) => i)
      ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));
    return MaiaEvaluation(
      policy: {for (final i in order) moves[i]: probabilities[i]},
      loss: value[0],
      draw: value[1],
      win: value[2],
      ponder: _network.ponder,
    );
  }

  /// A entrada da rede: para cada casa, 12 canais (6 peças de quem joga, 6 do
  /// oponente) por posição do histórico. Se a partida tem menos posições do
  /// que a rede espera, a mais antiga é repetida no começo.
  Float32List encode(List<Position> history) {
    final config = _network.config;
    final slots = config.history;
    final planes = config.planes;
    final first = math.max(0, history.length - slots);
    final padding = slots - (history.length - first);
    final tokens = Float32List(MaiaNetwork.squares * planes);
    for (var slot = 0; slot < slots; slot++) {
      final position = history[first + math.max(0, slot - padding)];
      final flip = position.turn == Side.black;
      for (final square in position.board.occupied.squares) {
        final piece = position.board.pieceAt(square)!;
        final s = flip ? square ^ 56 : square;
        final channel =
            _channel(piece.role) + (piece.color == position.turn ? 0 : 6);
        tokens[s * planes + slot * 12 + channel] = 1;
      }
    }
    return tokens;
  }

  /// A ordem das promoções na saída do modelo.
  static const List<Role> _promotions = [
    Role.queen,
    Role.rook,
    Role.bishop,
    Role.knight,
  ];

  static int _channel(Role role) => switch (role) {
    Role.pawn => 0,
    Role.knight => 1,
    Role.bishop => 2,
    Role.rook => 3,
    Role.queen => 4,
    Role.king => 5,
  };

  static List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return const [];
    final max = logits.reduce(math.max);
    final weights = [for (final logit in logits) math.exp(logit - max)];
    final total = weights.fold(0.0, (sum, weight) => sum + weight);
    return [for (final weight in weights) weight / total];
  }
}
