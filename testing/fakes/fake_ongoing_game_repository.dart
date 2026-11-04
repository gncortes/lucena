import 'dart:io';

import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository.dart';
import 'package:lucena/domain/models/game_snapshot.dart';

/// Partida em andamento só na memória. [saved] guarda tudo o que foi gravado,
/// em ordem.
class FakeOngoingGameRepository implements OngoingGameRepository {
  FakeOngoingGameRepository([this.snapshot]);

  GameSnapshot? snapshot;
  final saved = <GameSnapshot>[];
  int clearCalls = 0;

  @override
  Future<GameSnapshot?> load() async => snapshot;

  /// Quantas gravações da partida ainda falham (falta de espaço, H-PAR-19).
  int failSave = 0;

  @override
  Future<void> save(GameSnapshot snapshot) async {
    if (failSave > 0) {
      failSave--;
      throw const FileSystemException('No space left on device');
    }
    this.snapshot = snapshot;
    saved.add(snapshot);
  }

  @override
  Future<void> clear() async {
    snapshot = null;
    clearCalls++;
  }
}
