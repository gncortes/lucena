/// O evento (torneio) a que o plano de estudo chega, para a faixa da aba
/// Lição (H-LIC-05). Só datas: quem calcula "hoje" é o [Now] injetado.
final class PlanEvent {
  const PlanEvent({required this.name, required this.start, required this.date})
    : assert(name != '');

  final String name;

  /// O dia em que o plano começou.
  final DateTime start;

  /// O dia do evento.
  final DateTime date;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Quantas semanas o plano tem (no mínimo 1).
  int get totalWeeks {
    final days = _day(date).difference(_day(start)).inDays;
    return days <= 0 ? 1 : (days / 7).ceil();
  }

  /// Quantos dias faltam em [now] (0 no dia do evento ou depois).
  int daysLeft(DateTime now) {
    final left = _day(date).difference(_day(now)).inDays;
    return left < 0 ? 0 : left;
  }

  /// A semana do plano em [now], de 1 a [totalWeeks].
  int weekAt(DateTime now) {
    final passed = _day(now).difference(_day(start)).inDays;
    final week = (passed < 0 ? 0 : passed) ~/ 7 + 1;
    return week > totalWeeks ? totalWeeks : week;
  }

  /// O quanto de cada semana já passou (0 a 1), uma entrada por semana.
  List<double> weekFractions(DateTime now) {
    final passed = _day(now).difference(_day(start)).inDays;
    return [
      for (var i = 0; i < totalWeeks; i++)
        ((passed - i * 7) / 7).clamp(0.0, 1.0),
    ];
  }
}
