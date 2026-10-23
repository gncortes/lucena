import 'package:lucena/data/repositories/crowd/crowd_repository.dart';
import 'package:lucena/domain/models/crowd_stat.dart';

/// Os números na memória, por dia e por final.
class FakeCrowdRepository implements CrowdRepository {
  FakeCrowdRepository({
    Map<String, CrowdStat>? days,
    Map<String, CrowdStat>? featured,
  }) : days = {...?days},
       featuredStats = {...?featured};

  final Map<String, CrowdStat> days;
  final Map<String, CrowdStat> featuredStats;

  @override
  Future<CrowdStat?> daily(String day) async => days[day];

  @override
  Future<CrowdStat?> featured(String id) async => featuredStats[id];
}
