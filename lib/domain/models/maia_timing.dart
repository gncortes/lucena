import 'package:freezed_annotation/freezed_annotation.dart';

part 'maia_timing.freezed.dart';

/// Quanto o Maia leva para calcular um lance no aparelho, medido em várias
/// contas seguidas.
@freezed
abstract class MaiaTiming with _$MaiaTiming {
  const factory MaiaTiming({
    /// Quantas contas foram medidas.
    required int runs,

    /// O tempo do meio: metade das contas foi mais rápida, metade mais lenta.
    required Duration median,
    required Duration fastest,
    required Duration slowest,
  }) = _MaiaTiming;

  /// Resume os tempos medidos. Nulo se não há nenhum.
  static MaiaTiming? of(List<Duration> times) {
    if (times.isEmpty) return null;
    final sorted = [...times]..sort();
    final middle = sorted.length ~/ 2;
    return MaiaTiming(
      runs: sorted.length,
      median: sorted.length.isOdd
          ? sorted[middle]
          : (sorted[middle - 1] + sorted[middle]) ~/ 2,
      fastest: sorted.first,
      slowest: sorted.last,
    );
  }
}
