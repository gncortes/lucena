import 'dart:async';

import 'package:lucena/data/repositories/update/app_update_repository.dart';

/// A Play na memória: [info] é a resposta, e os contadores mostram o que o
/// app pediu.
class FakeAppUpdateRepository implements AppUpdateRepository {
  FakeAppUpdateRepository({
    this.build = 100,
    this.info = const PlayUpdateInfo(),
    this.seen = 0,
    this.flexibleResult = true,
  });

  int build;
  PlayUpdateInfo info;
  int seen;
  bool flexibleResult;
  int checks = 0;
  int immediates = 0;
  int flexibles = 0;
  int completes = 0;
  int storeOpens = 0;

  /// Segura o fim do download até o teste completar.
  Completer<void>? holdFlexible;

  @override
  Future<int> installedBuild() async => build;

  @override
  Future<PlayUpdateInfo> check() async {
    checks++;
    return info;
  }

  @override
  Future<bool> immediate() async {
    immediates++;
    return false;
  }

  @override
  Future<bool> flexible() async {
    flexibles++;
    await holdFlexible?.future;
    return flexibleResult;
  }

  @override
  Future<void> completeFlexible() async => completes++;

  @override
  Future<void> openStore() async => storeOpens++;

  @override
  Future<int> recommendedSeen() async => seen;

  @override
  Future<void> markRecommendedSeen(int build) async => seen = build;
}
