import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/crowd_stat.dart';

void main() {
  test('lê pct e total', () {
    expect(
      CrowdStat.fromJson({'pct': 62.6, 'total': 4812}),
      const CrowdStat(percent: 63, total: 4812),
    );
  });

  test('sem documento, sem campos ou estragado: nulo', () {
    expect(CrowdStat.fromJson(null), isNull);
    expect(CrowdStat.fromJson({'total': 40}), isNull);
    expect(CrowdStat.fromJson({'pct': '63', 'total': 40}), isNull);
    expect(CrowdStat.fromJson({'pct': 101, 'total': 40}), isNull);
    expect(CrowdStat.fromJson({'pct': 50, 'total': -1}), isNull);
  });

  test('o número só aparece a partir de 30 pessoas', () {
    expect(const CrowdStat(percent: 50, total: 29).enough, isFalse);
    expect(const CrowdStat(percent: 50, total: 30).enough, isTrue);
  });
}
