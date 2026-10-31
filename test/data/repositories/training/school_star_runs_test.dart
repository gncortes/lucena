import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/star_challenge_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class Disk extends PreferencesService {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('disk');
    values[key] = value;
  }
}

void main() {
  late Disk disk;
  late LocalStarChallengeRepository repository;
  final date = DateTime(2026, 10, 26, 12);
  Future<void> add(int points) => repository.addRun(
    piece: ChallengePiece.rook,
    level: ChallengeLevel.easy,
    points: points,
    at: date,
  );
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    disk = Disk();
    repository = LocalStarChallengeRepository(disk);
  });
  test(
    'legacy best remains; same best and worse runs still have dated history',
    () async {
      disk.values['school.starChallenges'] = jsonEncode({
        'best': {'rook.easy': 30},
      });
      expect(await repository.runsSince(DateTime(2026)), isEmpty);
      await add(15);
      await add(30);
      await add(0);
      expect(
        (await repository.load()).bestOf(
          ChallengePiece.rook,
          ChallengeLevel.easy,
        ),
        30,
      );
      expect(
        await LocalStarChallengeRepository(disk).runsSince(date),
        hasLength(3),
      );
      expect(
        await repository.runsSince(date.add(const Duration(seconds: 1))),
        isEmpty,
      );
    },
  );
  test(
    'serialized concurrent runs preserve history and monotonic best',
    () async {
      await Future.wait([add(40), add(10), add(15)]);
      await repository.save(
        const StarChallengeProgress(best: {'rook.easy': 1}),
      );
      expect(
        (await repository.load()).bestOf(
          ChallengePiece.rook,
          ChallengeLevel.easy,
        ),
        40,
      );
      expect(await repository.runsSince(date), hasLength(3));
    },
  );
  test(
    'failed disk write publishes no run or record; next write can retry',
    () async {
      await add(15);
      disk.fail = true;
      await expectLater(add(50), throwsStateError);
      expect(
        (await repository.load()).bestOf(
          ChallengePiece.rook,
          ChallengeLevel.easy,
        ),
        15,
      );
      expect(await repository.runsSince(date), hasLength(1));
      disk.fail = false;
      await add(20);
      expect(await repository.runsSince(date), hasLength(2));
    },
  );
}
