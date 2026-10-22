import 'package:lucena/data/repositories/activity/activity_repository.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/domain/use_cases/streak_rules.dart';

import 'fake_now.dart';

class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository({Set<DateTime>? days, Now? now})
    : marked = {...?days},
      _now = now ?? FakeNow(DateTime(2026, 10, 22, 9));

  final Set<DateTime> marked;
  final Now _now;

  @override
  Future<Set<DateTime>> days() async => {
    for (final day in marked) StreakRules.day(day),
  };

  @override
  Future<void> markToday() async => marked.add(StreakRules.day(_now()));

  DateTime? lostShown;

  @override
  Future<bool> lostPending(DateTime lastDay) async => lostShown != lastDay;

  @override
  Future<void> markLostShown(DateTime lastDay) async => lostShown = lastDay;
}
