/// Os níveis do Maia: o rating do jogador humano que ele imita.
abstract final class MaiaLevels {
  static const min = 1000;
  static const max = 2600;
  static const step = 200;

  /// Do mais fraco ao mais forte.
  static const all = [1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400, 2600];

  /// O nível mais próximo de um rating (o do perfil do jogador, por exemplo).
  static int nearest(int rating) =>
      ((rating / step).round() * step).clamp(min, max);

  /// Quanto o Maia varia os lances. Com 1, ele sorteia o lance na proporção
  /// em que as pessoas daquele rating o jogam; mais perto de 0, fica nos
  /// lances mais prováveis; com 0, joga sempre o mesmo lance.
  ///
  /// Calibrado nos finais do catálogo (`docs/calibracao.md`): o mesmo valor
  /// para todos os níveis. A força de cada nível já vem das probabilidades do
  /// modelo. Com 1, o Maia joga fora mais resultados do que o próprio modelo
  /// prevê para pessoas daquele rating; com 0, toda partida sai igual.
  static const temperature = 0.5;
}
