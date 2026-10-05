/// O tour da primeira abertura: em que passo está, se terminou e o degrau
/// escolhido para começar a Jornada.
class Onboarding {
  const Onboarding({this.done = false, this.step = 0, this.startRung});

  /// O tour já foi visto ou pulado.
  final bool done;

  /// O passo em que o tour parou (para voltar nele se o app fechar).
  final int step;

  /// O degrau da Jornada escolhido no tour. Nulo: começa do primeiro.
  final String? startRung;

  Onboarding copyWith({bool? done, int? step, String? startRung}) => Onboarding(
    done: done ?? this.done,
    step: step ?? this.step,
    startRung: startRung ?? this.startRung,
  );

  @override
  bool operator ==(Object other) =>
      other is Onboarding &&
      other.done == done &&
      other.step == step &&
      other.startRung == startRung;

  @override
  int get hashCode => Object.hash(done, step, startRung);
}
