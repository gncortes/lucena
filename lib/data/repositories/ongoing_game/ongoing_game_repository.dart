import '../../../domain/models/game_snapshot.dart';

/// A partida em andamento, guardada para sobreviver ao fechamento do app.
abstract class OngoingGameRepository {
  /// A partida gravada. Nulo se não há partida em andamento.
  Future<GameSnapshot?> load();

  Future<void> save(GameSnapshot snapshot);

  /// Esquece a partida (ela terminou).
  Future<void> clear();
}
