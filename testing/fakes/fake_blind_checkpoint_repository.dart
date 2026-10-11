import 'package:lucena/data/repositories/blind/blind_checkpoint_repository.dart';
import 'package:lucena/domain/models/blind_checkpoint.dart';

class FakeBlindCheckpointRepository implements BlindCheckpointRepository {
  BlindCheckpoint? checkpoint;
  @override
  Future<BlindCheckpoint?> load() async => checkpoint;
  @override
  Future<void> save(BlindCheckpoint value) async {
    checkpoint = value;
  }

  @override
  Future<void> clear() async {
    checkpoint = null;
  }
}
