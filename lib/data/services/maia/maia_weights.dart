import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Os pesos do Maia-3 no formato de `tools/maia/export_weights.py`:
/// `LMW1`, tamanho do cabeçalho, cabeçalho JSON e os tensores em float16.
class MaiaWeights {
  MaiaWeights._(this.config, this._data, this._offsets, this._sizes);

  /// Lê o arquivo de pesos. Lança [FormatException] se o arquivo não for um
  /// arquivo de pesos do Maia.
  factory MaiaWeights.parse(Uint8List bytes) {
    if (bytes.length < 8 || ascii.decode(bytes.sublist(0, 4)) != 'LMW1') {
      throw const FormatException('Not a Maia weights file');
    }
    final view = ByteData.sublistView(bytes);
    final headerLength = view.getUint32(4, Endian.little);
    final header = jsonDecode(
      utf8.decode(bytes.sublist(8, 8 + headerLength)),
    ) as Map<String, dynamic>;

    // Os pesos vêm em float16 (metade do tamanho) e as contas são em float32.
    final start = 8 + headerLength;
    final count = (bytes.length - start) ~/ 2;
    final data = Float32List(count);
    for (var i = 0; i < count; i++) {
      data[i] = _fromHalf(view.getUint16(start + 2 * i, Endian.little));
    }

    final offsets = <String, int>{};
    final sizes = <String, int>{};
    for (final entry in header['tensors'] as List<dynamic>) {
      final tensor = entry as Map<String, dynamic>;
      final name = tensor['name'] as String;
      offsets[name] = tensor['offset'] as int;
      sizes[name] = (tensor['shape'] as List<dynamic>).cast<int>().fold(
        1,
        (size, dimension) => size * dimension,
      );
    }
    return MaiaWeights._(
      MaiaConfig.fromJson(header['config'] as Map<String, dynamic>),
      data,
      offsets,
      sizes,
    );
  }

  final MaiaConfig config;
  final Float32List _data;
  final Map<String, int> _offsets;
  final Map<String, int> _sizes;

  /// O tensor [name], linha por linha.
  Float32List tensor(String name) {
    final offset = _offsets[name];
    if (offset == null) throw ArgumentError.value(name, 'name', 'No tensor');
    return Float32List.sublistView(_data, offset, offset + _sizes[name]!);
  }

  /// Um float16 (IEEE 754: 1 bit de sinal, 5 de expoente, 10 de fração).
  static double _fromHalf(int bits) {
    final exponent = (bits >> 10) & 0x1f;
    final fraction = bits & 0x3ff;
    final double magnitude;
    if (exponent == 0) {
      magnitude = fraction * _halfSubnormalStep;
    } else if (exponent == 0x1f) {
      magnitude = fraction == 0 ? double.infinity : double.nan;
    } else {
      magnitude = (1024 + fraction) * _halfScales[exponent];
    }
    return bits & 0x8000 == 0 ? magnitude : -magnitude;
  }

  /// 2^-24: o passo dos float16 menores que o menor número normal.
  static const double _halfSubnormalStep = 1 / 16777216;

  /// Para cada expoente e, 2^(e - 15 - 10).
  static final List<double> _halfScales = [
    for (var exponent = 0; exponent < 31; exponent++)
      math.pow(2, exponent - 25).toDouble(),
  ];

  /// O tensor [name] de 4 em 4 valores. O tamanho dele tem de ser múltiplo
  /// de 4.
  Float32x4List tensor4(String name) => Float32x4List.sublistView(tensor(name));
}

/// O tamanho do modelo: o que muda entre o Maia-3 de 5M e os maiores.
class MaiaConfig {
  const MaiaConfig({
    required this.history,
    required this.dimEmb,
    required this.dim,
    required this.blocks,
    required this.heads,
    required this.headDim,
    required this.gabGenSize,
    required this.gabIntermediateDim,
  });

  factory MaiaConfig.fromJson(Map<String, dynamic> json) => MaiaConfig(
    history: json['history'] as int,
    dimEmb: json['dimEmb'] as int,
    dim: json['dim'] as int,
    blocks: json['blocks'] as int,
    heads: json['heads'] as int,
    headDim: json['headDim'] as int,
    gabGenSize: json['gabGenSize'] as int,
    gabIntermediateDim: json['gabIntermediateDim'] as int,
  );

  /// Quantas posições (a atual e as anteriores) o modelo recebe.
  final int history;

  /// Tamanho do vetor de cada rating.
  final int dimEmb;

  /// Tamanho do vetor de cada casa dentro do transformer.
  final int dim;

  final int blocks;
  final int heads;

  /// Tamanho das projeções das cabeças de lance, resultado e tempo.
  final int headDim;

  final int gabGenSize;
  final int gabIntermediateDim;

  /// Canais de entrada por casa: 12 tipos de peça por posição do histórico.
  int get planes => 12 * history;
}
