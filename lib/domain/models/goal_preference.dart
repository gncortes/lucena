import 'home_layout.dart';

/// O que a pessoa quer fazer no Lucena, escolhido na primeira abertura ("O
/// que você quer fazer?") e trocado no Perfil. Decide o primeiro cartão da
/// tela inicial. Ordem = ordem dos cartões na pergunta (H-ABE-03).
enum GoalPreference {
  /// Aprender a jogar: a Escola do Viktor.
  learn,

  /// Melhorar o jogo: o guia de treino (Pilares do Xadrez).
  improve,

  /// Treinar finais: as posições do catálogo.
  train,

  /// Explorar posições: o tabuleiro livre.
  explore,

  /// Enfrentar desafios: a Jornada e o relógio.
  challenge;

  /// O objetivo gravado. "endgames" (Aprender finais, que saiu com o curso
  /// de finais oculto) vira Treinar finais.
  static GoalPreference? fromCode(Object? code) =>
      code == 'endgames' ? GoalPreference.train : values.asNameMap()[code];

  /// O caminho da tela inicial que vira o cartão do objetivo.
  HomePath get path => switch (this) {
    GoalPreference.learn => HomePath.learn,
    GoalPreference.improve => HomePath.forYou,
    GoalPreference.train => HomePath.train,
    GoalPreference.explore => HomePath.train,
    GoalPreference.challenge => HomePath.journey,
  };
}
