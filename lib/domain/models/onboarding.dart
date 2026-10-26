/// As telas da primeira abertura, na ordem da loja (decisão 1a da E1.11):
/// o tour, "O que você quer fazer?" e "Seu nível". Quem veio de um link passa
/// pela conta entre o tour e a pergunta.
enum OnboardingStage {
  tour,
  account,
  goal,
  level;

  static OnboardingStage? fromCode(Object? code) => values.asNameMap()[code];
}

/// O tour da primeira abertura: em que passo está, se terminou e o degrau
/// escolhido para começar a Jornada.
class Onboarding {
  const Onboarding({
    this.done = false,
    this.step = 0,
    this.startRung,
    this.selectedRating,
    this.byHand = false,
    this.inProgress = false,
    this.linkSetupDone = false,
    this.stage = OnboardingStage.tour,
    this.boardControlsDone = false,
    this.boardControlsOpen = false,
    this.boardControlsFen,
  });

  /// A tela da primeira abertura em que a pessoa está: o app fechado volta
  /// nela.
  final OnboardingStage stage;
  final bool boardControlsDone;
  final bool boardControlsOpen;
  final String? boardControlsFen;

  /// O tour já foi visto ou pulado.
  final bool done;

  /// O passo em que o tour parou (para voltar nele se o app fechar).
  final int step;

  /// O degrau da Jornada escolhido no tour. Nulo: começa do primeiro.
  final String? startRung;

  /// Explicit tour choice, never inferred from the profile's initial rating.
  /// Null means neither a manual band nor a used placement result was chosen.
  final int? selectedRating;
  final bool byHand;

  /// Also records an unfinished replay without making old done users repeat it.
  final bool inProgress;

  /// Quem abriu o app por um link de desafio já passou pelo "Antes do
  /// desafio" (cores, peças e som): o tour pula o passo do tabuleiro.
  final bool linkSetupDone;

  Onboarding copyWith({
    bool? done,
    int? step,
    String? startRung,
    int? Function()? selectedRating,
    bool? byHand,
    bool? inProgress,
    bool? linkSetupDone,
    OnboardingStage? stage,
    bool? boardControlsDone,
    bool? boardControlsOpen,
    String? boardControlsFen,
  }) => Onboarding(
    stage: stage ?? this.stage,
    boardControlsDone: boardControlsDone ?? this.boardControlsDone,
    boardControlsOpen: boardControlsOpen ?? this.boardControlsOpen,
    boardControlsFen: boardControlsFen ?? this.boardControlsFen,
    selectedRating: selectedRating == null
        ? this.selectedRating
        : selectedRating(),
    byHand: byHand ?? this.byHand,
    inProgress: inProgress ?? this.inProgress,
    linkSetupDone: linkSetupDone ?? this.linkSetupDone,
    done: done ?? this.done,
    step: step ?? this.step,
    startRung: startRung ?? this.startRung,
  );

  @override
  bool operator ==(Object other) =>
      other is Onboarding &&
      other.done == done &&
      other.step == step &&
      other.startRung == startRung &&
      other.selectedRating == selectedRating &&
      other.byHand == byHand &&
      other.inProgress == inProgress &&
      other.linkSetupDone == linkSetupDone &&
      other.stage == stage &&
      other.boardControlsDone == boardControlsDone &&
      other.boardControlsOpen == boardControlsOpen &&
      other.boardControlsFen == boardControlsFen;

  @override
  int get hashCode => Object.hash(
    done,
    step,
    startRung,
    selectedRating,
    byHand,
    inProgress,
    linkSetupDone,
    stage,
    boardControlsDone,
    boardControlsOpen,
    boardControlsFen,
  );
}
