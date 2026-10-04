import 'package:lucena/data/repositories/haptics/haptics_repository.dart';

/// Não vibra: só conta os avisos pedidos.
class FakeHapticsRepository implements HapticsRepository {
  int lowTimeCalls = 0;

  @override
  Future<void> lowTime() async => lowTimeCalls++;
}
