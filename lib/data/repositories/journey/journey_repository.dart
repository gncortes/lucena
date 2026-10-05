import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';

/// O conteúdo da progressão: os degraus da Jornada e os speedruns.
abstract class JourneyRepository {
  /// Os degraus, do primeiro (1000) ao último (Stockfish).
  Future<List<Rung>> ladder();

  /// Os speedruns, na ordem em que aparecem.
  Future<List<Speedrun>> speedruns();
}
