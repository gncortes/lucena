import 'dart:async';

import 'package:lucena/config/remote_defaults.dart';
import 'package:lucena/data/repositories/config/remote_flags_repository.dart';

/// As chaves do Remote Config com valor à mão; [change] avisa quem escuta.
class FakeRemoteFlagsRepository implements RemoteFlagsRepository {
  FakeRemoteFlagsRepository({
    this.updateMinBuild = 0,
    this.updateRecommendedBuild = 0,
    bool? adsEnabled,
    int? adsFreeLessons,
    int? adsMinGapSeconds,
  }) : adsEnabled =
           adsEnabled ?? remoteDefaults[RemoteKeys.adsEnabled]! as bool,
       adsFreeLessons =
           adsFreeLessons ?? remoteDefaults[RemoteKeys.adsFreeLessons]! as int,
       adsMinGapSeconds =
           adsMinGapSeconds ??
           remoteDefaults[RemoteKeys.adsMinGapSeconds]! as int;

  @override
  int updateMinBuild;

  @override
  int updateRecommendedBuild;

  @override
  bool adsEnabled;

  @override
  int adsFreeLessons;

  @override
  int adsMinGapSeconds;

  final _changes = StreamController<Set<String>>.broadcast();
  int refreshes = 0;

  @override
  Future<void> start() async {}

  @override
  Future<void> refresh() async => refreshes++;

  /// O console mudou [keys] (os valores já foram trocados no fake).
  void change(Set<String> keys) => _changes.add(keys);

  @override
  Stream<Set<String>> get changes => _changes.stream;
}
