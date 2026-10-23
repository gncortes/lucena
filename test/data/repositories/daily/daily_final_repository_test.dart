import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/daily/daily_final_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/daily_final.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_positions_repository.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);

  final String text;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(text));
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  LocalDailyFinalRepository repository([String? queue]) =>
      LocalDailyFinalRepository(
        AssetService(
          _Bundle(
            queue ??
                jsonEncode({
                  'version': 1,
                  'epoch': '2026-10-22',
                  'ids': ['basic.rook.0001', 'basic.queen.0001', 'sumiu'],
                }),
          ),
        ),
        FakePositionsRepository(),
        PreferencesService(),
      );

  DailyRecord record(DateTime date, DailyOutcome outcome) => DailyRecord(
    date: date,
    positionId: 'basic.rook.0001',
    outcome: outcome,
    fulfilled: outcome == DailyOutcome.won,
    squares: const [DailySquare.right],
  );

  test('o final de cada dia sai da fila, na ordem', () async {
    final daily = repository();
    final today = await daily.of(DateTime(2026, 10, 22, 21));
    expect(today?.position.id, 'basic.rook.0001');
    expect(today?.date, DateTime(2026, 10, 22));
    final tomorrow = await daily.of(DateTime(2026, 10, 23, 8));
    expect(tomorrow?.position.id, 'basic.queen.0001');
  });

  test('id fora do catálogo ou fila quebrada: sem final', () async {
    expect(await repository().of(DateTime(2026, 10, 24)), isNull);
    expect(await repository('{').of(DateTime(2026, 10, 22)), isNull);
  });

  test('só a primeira tentativa do dia vale', () async {
    final day = DateTime(2026, 10, 22, 10);
    expect(await repository().record(day), isNull);
    await repository().saveFirst(record(day, DailyOutcome.lost));
    await repository().saveFirst(record(day, DailyOutcome.won));
    final saved = await repository().record(DateTime(2026, 10, 22, 23));
    expect(saved?.outcome, DailyOutcome.lost);
    expect(await repository().record(DateTime(2026, 10, 23)), isNull);
  });

  test('a fila do app: sem repetir, todos no catálogo, até 7 peças', () {
    final queue = DailyQueue.fromJson(
      jsonDecode(File('assets/daily/queue.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final catalog = {
      for (final p
          in (jsonDecode(
                File('assets/positions/positions.json').readAsStringSync(),
              ) as Map<String, dynamic>)['positions']
              as List)
        p['id'] as String: p['fen'] as String,
    };
    expect(queue.ids, isNotEmpty);
    expect(queue.ids.toSet(), hasLength(queue.ids.length));
    for (final id in queue.ids) {
      final fen = catalog[id];
      expect(fen, isNotNull, reason: id);
      final pieces = fen!.split(' ').first.split('').where((c) {
        return RegExp('[a-zA-Z]').hasMatch(c);
      }).length;
      expect(pieces, lessThanOrEqualTo(7), reason: id);
    }
  });
}
