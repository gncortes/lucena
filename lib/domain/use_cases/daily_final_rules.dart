import '../models/daily_final.dart';
import '../models/wdl.dart';
import 'streak_rules.dart';

/// Qual é o final de um dia e a cor de cada lance dele.
abstract final class DailyFinalRules {
  /// Quantos dias [at] está depois do começo da fila (negativo antes dele).
  /// Conta em datas, sem horas: o horário de verão não muda o dia.
  static int dayIndex(DateTime at, DateTime epoch) {
    final day = StreakRules.day(at);
    return DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(epoch.year, epoch.month, epoch.day)).inDays;
  }

  /// O id do final de [at]: o do documento do dia ([override], que o painel
  /// grava), senão o da fila. Nulo com a fila vazia e sem documento.
  static String? idOf(DateTime at, DailyQueue queue, {String? override}) {
    if (override != null) return override;
    if (queue.ids.isEmpty) return null;
    return queue.ids[dayIndex(at, queue.epoch) % queue.ids.length];
  }

  /// A cor de um lance, com o resultado teórico [before] (antes do lance) e
  /// [after] (depois dele), os dois do ponto de vista de quem joga o final.
  /// Pior que antes: estragou; sem um dos dois (o juiz não sabe): certo.
  static DailySquare square(Wdl? before, Wdl? after) {
    if (before == null || after == null) return DailySquare.right;
    return after.index > before.index ? DailySquare.bad : DailySquare.right;
  }
}
