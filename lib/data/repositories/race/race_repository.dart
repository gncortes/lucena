import '../../../domain/models/race.dart';

/// A Corrida de problemas: o banco, o recorde, o histórico e a Corrida em
/// andamento, que sobrevive ao app em segundo plano e ao fechamento forçado.
abstract class RaceRepository {
  /// Os problemas do banco.
  Future<List<RaceProblem>> problems();

  Future<RaceRecord> record();

  /// O recorde veio da conta (E1.13): fica o maior de cada campo.
  Future<void> restoreRecord(RaceRecord record);

  /// As últimas Corridas, a mais recente primeiro.
  Future<List<RaceResult>> history();

  /// A Corrida em andamento. Nulo se não há.
  Future<RaceRun?> ongoing();

  Future<void> saveOngoing(RaceRun run);

  /// Termina a Corrida: entra no histórico, atualiza o recorde e deixa de
  /// estar em andamento.
  Future<RaceOutcome> finish(RaceRun run, RaceEnd end);

  /// Esquece a Corrida em andamento sem guardar nada (o jogador saiu).
  Future<void> discardOngoing();

  /// O filtro de finais escolhido na abertura. Nulo: todos os finais.
  Future<RaceTheme?> theme();

  Future<void> setTheme(RaceTheme? theme);

  /// Se a Nova partida oferece o aquecimento antes de jogar.
  Future<bool> offersWarmUp();

  Future<void> setOffersWarmUp({required bool value});
}
