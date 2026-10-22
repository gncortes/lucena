import 'package:lucena/data/repositories/sync/sync_repository.dart';
import 'package:lucena/domain/models/progress_summary.dart';

/// A conta na memória. [remote] é o que "outro aparelho" deixou; com
/// [offline], entrar falha como sem rede. [synced] guarda cada uid sincronizado.
class FakeSyncRepository implements SyncRepository {
  FakeSyncRepository({this.remote, this.offline = false, this.at});

  ProgressSummary? remote;
  bool offline;
  DateTime? at;
  final synced = <String>[];

  @override
  Future<DateTime?> lastSyncedAt(String uid) async => at;

  @override
  Future<SyncResult> sync(String uid) async {
    if (offline) throw const SyncException();
    synced.add(uid);
    final summary = remote ?? const ProgressSummary();
    return SyncResult(summary: summary, hadRemote: !summary.isEmpty);
  }
}
