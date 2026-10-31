import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lucena/data/repositories/analysis/analysis_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/game_review.dart';

void initializeAnalysisPreferences() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
}

class AnalysisMemoryPreferences extends PreferencesService {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('disk unavailable');
    values[key] = value;
  }
}

class ControlledAnalysisEngine implements AnalysisRepository {
  final requests =
      <({Position position, int count, Completer<List<EngineLine>> result})>[];
  @override
  Future<List<EngineLine>> analyse(
    Position position, {
    required int depth,
    int lines = 1,
    bool urgent = false,
    Duration? time,
    bool preemptible = false,
  }) {
    final result = Completer<List<EngineLine>>();
    requests.add((position: position, count: lines, result: result));
    return result.future;
  }
}
