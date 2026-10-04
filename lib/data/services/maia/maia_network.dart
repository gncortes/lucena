import 'dart:math' as math;
import 'dart:typed_data';

import 'maia_weights.dart';

/// A rede do Maia-3 (Chessformer) em Dart puro: as mesmas contas do
/// `MAIA3Model` oficial em PyTorch, com os pesos de [MaiaWeights].
///
/// As 64 casas são os tokens. Cada bloco soma à atenção um viés por par de
/// casas calculado a partir da própria posição (GAB), e a cabeça de lances dá
/// uma nota para cada par casa de origem → casa de destino.
///
/// Uma instância guarda os buffers de trabalho: [run] não pode ser chamado
/// duas vezes ao mesmo tempo, e as saídas valem até a chamada seguinte.
class MaiaNetwork {
  MaiaNetwork(MaiaWeights weights)
    : config = weights.config,
      _eloLow = weights.tensor('elo_embedding_low.weight'),
      _eloHigh = weights.tensor('elo_embedding_high.weight'),
      _tokenWeight = weights.tensor('token_projection.weight'),
      _tokenBias = weights.tensor('token_projection.bias'),
      _gabWeight = weights.tensor4('gab_shared_weight'),
      _finalNormWeight = weights.tensor('transformer.norm.weight'),
      _finalNormBias = weights.tensor('transformer.norm.bias'),
      _lastNormWeight = weights.tensor('last_ln.weight'),
      _lastNormBias = weights.tensor('last_ln.bias'),
      _fromWeight = weights.tensor4('proj_sq_from.weight'),
      _toWeight = weights.tensor4('proj_sq_to.weight'),
      _promotionWeight = weights.tensor4('promo_bias_proj.weight'),
      _valueHiddenWeight = weights.tensor4('fc_value_hid.weight'),
      _valueHiddenBias = weights.tensor('fc_value_hid.bias'),
      _valueWeight = weights.tensor('fc_value.weight'),
      _valueBias = weights.tensor('fc_value.bias'),
      _ponderHiddenWeight = weights.tensor4('fc_ponder_hid.weight'),
      _ponderHiddenBias = weights.tensor('fc_ponder_hid.bias'),
      _ponderWeight = weights.tensor('fc_ponder.weight'),
      _ponderBias = weights.tensor('fc_ponder.bias'),
      _blocks = [
        for (var i = 0; i < weights.config.blocks; i++) _Block(weights, i),
      ] {
    final dim = config.dim;
    final mlp = _blocks.first.linear1Bias.length;
    _x = _Buffer(squares * dim);
    _qkv = _Buffer(squares * 3 * dim);
    _attention = _Buffer(squares * dim);
    _projected = _Buffer(squares * dim);
    _hidden = _Buffer(squares * mlp);
    _pooled = _Buffer(dim);
    _gabHidden = _Buffer(config.gabIntermediateDim);
    _gabGen = _Buffer(config.heads * config.gabGenSize);
    _bias = Float32List(config.heads * squares * squares);
    _from = _Buffer(squares * config.headDim);
    _to = _Buffer(squares * config.headDim);
    _headHidden = _Buffer(config.headDim);
  }

  static const int squares = 64;

  /// O rating é cortado nesta faixa, como no modelo oficial.
  static const int maxElo = 5000;

  final MaiaConfig config;

  final Float32List _eloLow;
  final Float32List _eloHigh;
  final Float32List _tokenWeight;
  final Float32List _tokenBias;
  final Float32x4List _gabWeight;
  final Float32List _finalNormWeight;
  final Float32List _finalNormBias;
  final Float32List _lastNormWeight;
  final Float32List _lastNormBias;
  final Float32x4List _fromWeight;
  final Float32x4List _toWeight;
  final Float32x4List _promotionWeight;
  final Float32x4List _valueHiddenWeight;
  final Float32List _valueHiddenBias;
  final Float32List _valueWeight;
  final Float32List _valueBias;
  final Float32x4List _ponderHiddenWeight;
  final Float32List _ponderHiddenBias;
  final Float32List _ponderWeight;
  final Float32List _ponderBias;
  final List<_Block> _blocks;

  late final _Buffer _x;
  late final _Buffer _qkv;
  late final _Buffer _attention;
  late final _Buffer _projected;
  late final _Buffer _hidden;
  late final _Buffer _pooled;
  late final _Buffer _gabHidden;
  late final _Buffer _gabGen;
  late final Float32List _bias;
  late final _Buffer _from;
  late final _Buffer _to;
  late final _Buffer _headHidden;
  final Float32List _scores = Float32List(squares);

  /// Previsão de resultado para quem joga, antes do softmax: derrota, empate
  /// e vitória, nessa ordem.
  final Float32List valueLogits = Float32List(3);

  /// Saída bruta da cabeça de tempo de reflexão.
  double ponder = 0;

  /// Roda a rede. [tokens] tem, para cada uma das 64 casas (a1, b1, … h8, do
  /// ponto de vista de quem joga), os [MaiaConfig.planes] canais de entrada.
  void run(Float32List tokens, {required int selfElo, required int oppoElo}) {
    assert(tokens.length == squares * config.planes);
    _embed(tokens, selfElo, oppoElo);
    for (final block in _blocks) {
      _gabBias(block);
      _selfAttention(block);
      _rmsNorm(_x.values, _projected.values, block.norm1Weight);
      _feedForward(block);
      _rmsNorm(_x.values, _projected.values, block.norm2Weight);
    }
    final dim = config.dim;
    final headDim = config.headDim;
    final x = _x.values;
    for (var s = 0; s < squares; s++) {
      _layerNorm(x, s * dim, dim, _finalNormWeight, _finalNormBias);
    }
    _linear(_fromWeight, null, _x.lanes, _from.values, squares, headDim, dim);
    _linear(_toWeight, null, _x.lanes, _to.values, squares, headDim, dim);

    _mean(x, _pooled.values, dim);
    _layerNorm(_pooled.values, 0, dim, _lastNormWeight, _lastNormBias);
    _head(_valueHiddenWeight, _valueHiddenBias, _valueWeight, _valueBias, 3);
    for (var i = 0; i < 3; i++) {
      valueLogits[i] = _headOut[i];
    }
    _head(
      _ponderHiddenWeight,
      _ponderHiddenBias,
      _ponderWeight,
      _ponderBias,
      1,
    );
    ponder = _headOut[0];
  }

  /// A nota do lance da casa [from] para a casa [to] (sem promoção).
  double moveLogit(int from, int to) =>
      _dot(_from.lanes, from, _to.lanes, to) / math.sqrt(config.headDim);

  /// A nota da promoção da coluna [fromFile] (sétima fila) para a coluna
  /// [toFile] (oitava fila). [piece]: 0 dama, 1 torre, 2 bispo, 3 cavalo.
  double promotionLogit(int fromFile, int toFile, int piece) {
    final to = 56 + toFile;
    final bias = _dot(_promotionWeight, piece, _to.lanes, to);
    return moveLogit(48 + fromFile, to) + bias * math.sqrt(config.headDim);
  }

  final Float32List _headOut = Float32List(3);

  double _dot(Float32x4List a, int rowA, Float32x4List b, int rowB) {
    final lanes = config.headDim >> 2;
    final ao = rowA * lanes;
    final bo = rowB * lanes;
    var sum = Float32x4.zero();
    for (var i = 0; i < lanes; i++) {
      sum += a[ao + i] * b[bo + i];
    }
    return sum.x + sum.y + sum.z + sum.w;
  }

  /// Entrada: canais da casa + vetor do rating de quem joga + vetor do rating
  /// do oponente, projetados para o tamanho do transformer.
  void _embed(Float32List tokens, int selfElo, int oppoElo) {
    final dim = config.dim;
    final planes = config.planes;
    final dimEmb = config.dimEmb;
    final width = planes + 2 * dimEmb;
    final selfWeight = selfElo.clamp(0, maxElo) / maxElo;
    final oppoWeight = oppoElo.clamp(0, maxElo) / maxElo;
    final x = _x.values;
    final shared = _pooled.values;

    // Os ratings são iguais nas 64 casas: a parte deles é calculada uma vez.
    for (var r = 0; r < dim; r++) {
      final row = r * width + planes;
      var sum = _tokenBias[r].toDouble();
      for (var c = 0; c < dimEmb; c++) {
        final low = _eloLow[c];
        final high = _eloHigh[c];
        sum +=
            _tokenWeight[row + c] *
            (selfWeight * low + (1 - selfWeight) * high);
        sum +=
            _tokenWeight[row + dimEmb + c] *
            (oppoWeight * low + (1 - oppoWeight) * high);
      }
      shared[r] = sum;
    }
    for (var s = 0; s < squares; s++) {
      final out = s * dim;
      for (var r = 0; r < dim; r++) {
        x[out + r] = shared[r];
      }
      // Os canais das peças são quase todos zero.
      for (var c = 0; c < planes; c++) {
        final value = tokens[s * planes + c];
        if (value == 0) continue;
        for (var r = 0; r < dim; r++) {
          x[out + r] += value * _tokenWeight[r * width + c];
        }
      }
    }
  }

  /// GAB: da média das casas sai, para cada cabeça de atenção, um viés para
  /// cada par (casa que olha, casa olhada).
  void _gabBias(_Block block) {
    final dim = config.dim;
    final heads = config.heads;
    final gen = config.gabGenSize;
    final intermediate = config.gabIntermediateDim;

    _mean(_x.values, _pooled.values, dim);
    final hidden = _gabHidden.values;
    _linear(
      block.gabIn,
      block.gabInBias,
      _pooled.lanes,
      hidden,
      1,
      intermediate,
      dim,
    );
    _gelu(hidden);
    _layerNorm(
      hidden,
      0,
      intermediate,
      block.gabNorm1Weight,
      block.gabNorm1Bias,
    );

    final generated = _gabGen.values;
    _linear(
      block.gabOut,
      block.gabOutBias,
      _gabHidden.lanes,
      generated,
      1,
      heads * gen,
      intermediate,
    );
    _gelu(generated);
    _layerNorm(
      generated,
      0,
      heads * gen,
      block.gabNorm2Weight,
      block.gabNorm2Bias,
    );

    final lanes = gen >> 2;
    final pairs = squares * squares;
    final y = _gabGen.lanes;
    for (var h = 0; h < heads; h++) {
      final yo = h * lanes;
      final out = h * pairs;
      for (var pair = 0; pair < pairs; pair++) {
        final wo = pair * lanes;
        var sum = Float32x4.zero();
        for (var i = 0; i < lanes; i++) {
          sum += y[yo + i] * _gabWeight[wo + i];
        }
        _bias[out + pair] = sum.x + sum.y + sum.z + sum.w;
      }
    }
  }

  /// Atenção entre as casas, com o viés do GAB. Deixa o resultado em
  /// `_projected`.
  void _selfAttention(_Block block) {
    final dim = config.dim;
    final heads = config.heads;
    final headDim = dim ~/ heads;
    final lanes = headDim >> 2;
    final stride = (3 * dim) >> 2;
    final keyOffset = dim >> 2;
    final valueOffset = (2 * dim) >> 2;
    final scale = 1 / math.sqrt(headDim);
    final pairs = squares * squares;

    _linear(block.inProj, null, _x.lanes, _qkv.values, squares, 3 * dim, dim);
    final qkv = _qkv.lanes;
    final out = _attention.lanes;
    for (var h = 0; h < heads; h++) {
      final head = (h * headDim) >> 2;
      for (var i = 0; i < squares; i++) {
        final query = i * stride + head;
        final bias = h * pairs + i * squares;
        var max = double.negativeInfinity;
        for (var j = 0; j < squares; j++) {
          final key = j * stride + keyOffset + head;
          var sum = Float32x4.zero();
          for (var l = 0; l < lanes; l++) {
            sum += qkv[query + l] * qkv[key + l];
          }
          final score =
              (sum.x + sum.y + sum.z + sum.w) * scale + _bias[bias + j];
          _scores[j] = score;
          if (score > max) max = score;
        }
        var total = 0.0;
        for (var j = 0; j < squares; j++) {
          final weight = math.exp(_scores[j] - max);
          _scores[j] = weight;
          total += weight;
        }
        final target = i * (dim >> 2) + head;
        for (var l = 0; l < lanes; l++) {
          out[target + l] = Float32x4.zero();
        }
        for (var j = 0; j < squares; j++) {
          final weight = Float32x4.splat(_scores[j] / total);
          final value = j * stride + valueOffset + head;
          for (var l = 0; l < lanes; l++) {
            out[target + l] += qkv[value + l] * weight;
          }
        }
      }
    }
    _linear(
      block.outProj,
      null,
      _attention.lanes,
      _projected.values,
      squares,
      dim,
      dim,
    );
  }

  /// As duas camadas densas do bloco. Deixa o resultado em `_projected`.
  void _feedForward(_Block block) {
    final dim = config.dim;
    final mlp = block.linear1Bias.length;
    _linear(
      block.linear1,
      block.linear1Bias,
      _x.lanes,
      _hidden.values,
      squares,
      mlp,
      dim,
    );
    _gelu(_hidden.values);
    _linear(
      block.linear2,
      block.linear2Bias,
      _hidden.lanes,
      _projected.values,
      squares,
      dim,
      mlp,
    );
  }

  /// Cabeça de resultado ou de tempo: densa, ReLU, densa. Lê `_pooled` e
  /// escreve [outputs] valores em `_headOut`.
  void _head(
    Float32x4List hiddenWeight,
    Float32List hiddenBias,
    Float32List weight,
    Float32List bias,
    int outputs,
  ) {
    final headDim = config.headDim;
    final hidden = _headHidden.values;
    _linear(
      hiddenWeight,
      hiddenBias,
      _pooled.lanes,
      hidden,
      1,
      headDim,
      config.dim,
    );
    for (var o = 0; o < outputs; o++) {
      var sum = bias[o].toDouble();
      for (var i = 0; i < headDim; i++) {
        final value = hidden[i];
        if (value > 0) sum += weight[o * headDim + i] * value;
      }
      _headOut[o] = sum;
    }
  }

  /// `out[t][r] = bias[r] + Σ weight[r][c] · x[t][c]`, para [count] vetores
  /// de [cols] valores.
  static void _linear(
    Float32x4List weight,
    Float32List? bias,
    Float32x4List x,
    Float32List out,
    int count,
    int rows,
    int cols,
  ) {
    assert(cols % 16 == 0);
    final lanes = cols >> 2;
    for (var r = 0; r < rows; r++) {
      final wo = r * lanes;
      final b = bias == null ? 0.0 : bias[r];
      for (var t = 0; t < count; t++) {
        final xo = t * lanes;
        // Quatro somas independentes: o processador faz as quatro em paralelo.
        var s0 = Float32x4.zero();
        var s1 = Float32x4.zero();
        var s2 = Float32x4.zero();
        var s3 = Float32x4.zero();
        for (var i = 0; i < lanes; i += 4) {
          s0 += weight[wo + i] * x[xo + i];
          s1 += weight[wo + i + 1] * x[xo + i + 1];
          s2 += weight[wo + i + 2] * x[xo + i + 2];
          s3 += weight[wo + i + 3] * x[xo + i + 3];
        }
        final sum = (s0 + s1) + (s2 + s3);
        out[t * rows + r] = sum.x + sum.y + sum.z + sum.w + b;
      }
    }
  }

  /// Média das 64 casas de [x] em [out].
  static void _mean(Float32List x, Float32List out, int dim) {
    for (var d = 0; d < dim; d++) {
      var sum = 0.0;
      for (var s = 0; s < squares; s++) {
        sum += x[s * dim + d];
      }
      out[d] = sum / squares;
    }
  }

  /// `x = RMSNorm(x + delta)`, casa por casa (o bloco normaliza depois de
  /// somar, como no modelo oficial).
  void _rmsNorm(Float32List x, Float32List delta, Float32List weight) {
    final dim = config.dim;
    for (var s = 0; s < squares; s++) {
      final offset = s * dim;
      var squaresSum = 0.0;
      for (var d = 0; d < dim; d++) {
        final value = x[offset + d] + delta[offset + d];
        x[offset + d] = value;
        squaresSum += value * value;
      }
      final scale = 1 / math.sqrt(squaresSum / dim + _rmsEpsilon);
      for (var d = 0; d < dim; d++) {
        x[offset + d] = x[offset + d] * scale * weight[d];
      }
    }
  }

  static void _layerNorm(
    Float32List x,
    int offset,
    int length,
    Float32List weight,
    Float32List bias,
  ) {
    var mean = 0.0;
    for (var i = 0; i < length; i++) {
      mean += x[offset + i];
    }
    mean /= length;
    var variance = 0.0;
    for (var i = 0; i < length; i++) {
      final centered = x[offset + i] - mean;
      variance += centered * centered;
    }
    final scale = 1 / math.sqrt(variance / length + _layerNormEpsilon);
    for (var i = 0; i < length; i++) {
      x[offset + i] = (x[offset + i] - mean) * scale * weight[i] + bias[i];
    }
  }

  static void _gelu(Float32List x) {
    for (var i = 0; i < x.length; i++) {
      final value = x[i];
      x[i] = 0.5 * value * (1 + _erf(value * math.sqrt1_2));
    }
  }

  /// Função erro, que o `dart:math` não tem: aproximação de Chebyshev de
  /// "Numerical Recipes", só com os termos que importam para float32 (erro
  /// abaixo de 1e-10).
  static double _erf(double x) {
    final z = x.abs();
    final t = 2 / (2 + z);
    final ty = 4 * t - 2;
    var d = 0.0;
    var dd = 0.0;
    for (var j = _erfCoefficients.length - 1; j > 0; j--) {
      final previous = d;
      d = ty * d - dd + _erfCoefficients[j];
      dd = previous;
    }
    final erfc =
        t * math.exp(-z * z + 0.5 * (_erfCoefficients[0] + ty * d) - dd);
    return x >= 0 ? 1 - erfc : erfc - 1;
  }

  /// O `eps` padrão do `torch.nn.RMSNorm` (o menor passo do float32).
  static const double _rmsEpsilon = 1.1920928955078125e-7;
  static const double _layerNormEpsilon = 1e-5;

  static const List<double> _erfCoefficients = [
    -1.3026537197817094,
    6.4196979235649026e-1,
    1.9476473204185836e-2,
    -9.561514786808631e-3,
    -9.46595344482036e-4,
    3.66839497852761e-4,
    4.2523324806907e-5,
    -2.0278578112534e-5,
    -1.624290004647e-6,
    1.303655835580e-6,
    1.5626441722e-8,
    -8.5238095915e-8,
    6.529054439e-9,
    5.059343495e-9,
    -9.91364156e-10,
    -2.27365122e-10,
    9.6467911e-11,
  ];
}

/// Os pesos de um bloco do transformer.
class _Block {
  _Block(MaiaWeights weights, int index)
    : this._(weights, 'transformer.layers.$index');

  _Block._(MaiaWeights weights, String prefix)
    : inProj = weights.tensor4('$prefix.self_attn.mha.in_proj_weight'),
      outProj = weights.tensor4('$prefix.self_attn.mha.out_proj.weight'),
      gabIn = weights.tensor4('$prefix.self_attn.sm2.weight'),
      gabInBias = weights.tensor('$prefix.self_attn.sm2.bias'),
      gabNorm1Weight = weights.tensor('$prefix.self_attn.ln1.weight'),
      gabNorm1Bias = weights.tensor('$prefix.self_attn.ln1.bias'),
      gabOut = weights.tensor4('$prefix.self_attn.sm3.weight'),
      gabOutBias = weights.tensor('$prefix.self_attn.sm3.bias'),
      gabNorm2Weight = weights.tensor('$prefix.self_attn.ln2.weight'),
      gabNorm2Bias = weights.tensor('$prefix.self_attn.ln2.bias'),
      linear1 = weights.tensor4('$prefix.linear1.weight'),
      linear1Bias = weights.tensor('$prefix.linear1.bias'),
      linear2 = weights.tensor4('$prefix.linear2.weight'),
      linear2Bias = weights.tensor('$prefix.linear2.bias'),
      norm1Weight = weights.tensor('$prefix.norm1.weight'),
      norm2Weight = weights.tensor('$prefix.norm2.weight');

  final Float32x4List inProj;
  final Float32x4List outProj;
  final Float32x4List gabIn;
  final Float32List gabInBias;
  final Float32List gabNorm1Weight;
  final Float32List gabNorm1Bias;
  final Float32x4List gabOut;
  final Float32List gabOutBias;
  final Float32List gabNorm2Weight;
  final Float32List gabNorm2Bias;
  final Float32x4List linear1;
  final Float32List linear1Bias;
  final Float32x4List linear2;
  final Float32List linear2Bias;
  final Float32List norm1Weight;
  final Float32List norm2Weight;
}

/// Um vetor de trabalho, visto valor a valor ou de 4 em 4.
class _Buffer {
  _Buffer(int length) : lanes = Float32x4List(length >> 2) {
    values = lanes.buffer.asFloat32List();
  }

  final Float32x4List lanes;
  late final Float32List values;
}
