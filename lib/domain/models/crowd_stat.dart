/// "x% acertaram" (E1.24): de quem jogou um final, quantos cumpriram o
/// objetivo na primeira tentativa. Vem pronto da nuvem (uma função lê o
/// Analytics depois que o dia fecha); o app nunca calcula nem inventa.
class CrowdStat {
  const CrowdStat({required this.percent, required this.total});

  /// Com menos gente que isto, o número não aparece (decisão 13).
  static const minTotal = 30;

  final int percent;
  final int total;

  bool get enough => total >= minTotal;

  /// Os campos `pct` e `total` do documento. Nulo: ainda não saiu (ou veio
  /// estragado).
  static CrowdStat? fromJson(Map<String, Object?>? data) {
    final pct = data?['pct'];
    final total = data?['total'];
    if (pct is! num || total is! num) return null;
    if (pct < 0 || pct > 100 || total < 0) return null;
    return CrowdStat(percent: pct.round(), total: total.toInt());
  }

  @override
  bool operator ==(Object other) =>
      other is CrowdStat && other.percent == percent && other.total == total;

  @override
  int get hashCode => Object.hash(percent, total);
}
