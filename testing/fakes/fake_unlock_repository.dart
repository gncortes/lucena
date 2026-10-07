import 'package:lucena/data/repositories/home/unlock_repository.dart';

class FakeUnlockRepository implements UnlockRepository {
  final seenModes = <String>{};

  @override
  Future<bool> seen(String mode) async => seenModes.contains(mode);

  @override
  Future<void> markSeen(String mode) async => seenModes.add(mode);
}
