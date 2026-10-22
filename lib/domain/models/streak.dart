/// A sequência de dias seguidos (E1.22, decisão 2b): o dia conta quando a
/// pessoa termina uma partida, faz uma aula ou joga um final. Perdeu um dia,
/// volta a zero; o recorde fica.
///
/// Os dias são datas do aparelho (meia-noite local, ver `StreakRules.day`).
/// As contas andam por data, não por 24 horas, para o horário de verão não
/// pular nem repetir um dia.
class Streak {
  const Streak({
    required this.current,
    required this.record,
    required this.activeToday,
    this.lost = 0,
  });

  static const none = Streak(current: 0, record: 0, activeToday: false);

  /// Os dias seguidos até hoje, ou até ontem se hoje ainda não teve nada (a
  /// sequência só acaba quando o dia fecha).
  final int current;

  /// A maior sequência já feita (nunca menor que [current]).
  final int record;

  final bool activeToday;

  /// A sequência que acabou: ontem ficou sem nada e, antes disso, havia
  /// [lost] dias seguidos. Zero se nada acabou.
  final int lost;

  /// Quantos dias faltam para empatar o recorde (zero: já é o recorde).
  int get toRecord => record - current;
}
