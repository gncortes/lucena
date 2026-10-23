import 'home_layout.dart';

/// O que a pessoa quer fazer no Lucena, escolhido na primeira abertura ("O
/// que você quer fazer?") e trocado no Perfil. Decide o primeiro cartão da
/// tela inicial.
enum GoalPreference {
  /// Aprender a jogar: a Escola do Viktor.
  learn,

  /// Aprender finais: as aulas de finais.
  endgames,

  /// Treinar finais: as posições do catálogo.
  train;

  static GoalPreference? fromCode(Object? code) => values.asNameMap()[code];

  /// O caminho da tela inicial que vira o cartão do objetivo.
  HomePath get path => switch (this) {
    GoalPreference.learn => HomePath.learn,
    GoalPreference.endgames => HomePath.endgames,
    GoalPreference.train => HomePath.train,
  };
}
