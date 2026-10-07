import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/blind/blind_log_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  LocalBlindLogRepository reopen() =>
      LocalBlindLogRepository(PreferencesService());

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('as medições ficam no aparelho e saem em JSON', () async {
    await reopen().add(
      BlindAttempt(
        at: DateTime.utc(2026, 10, 7, 12),
        alternatives: const ['torre f3', 'torre ff3'],
        result: 'move',
        san: 'Rf3',
        latencyMs: 640,
        onDevice: true,
      ),
    );
    final all = await reopen().all();
    expect(all.single.san, 'Rf3');
    expect(all.single.alternatives, ['torre f3', 'torre ff3']);
    final json = jsonDecode(await reopen().export()) as List;
    expect(json.single['latencyMs'], 640);

    await reopen().clear();
    expect(await reopen().all(), isEmpty);
  });
}
