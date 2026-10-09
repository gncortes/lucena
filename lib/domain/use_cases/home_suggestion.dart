import '../models/home_layout.dart';
import '../models/rating_level.dart';

/// Qual texto um caminho mostra na tela inicial, pelo nível do jogador.
enum HomePathText {
  /// O de quem está começando.
  standard,

  /// O de quem já joga.
  player,

  /// O de desafio, para os fortes.
  challenge,
}

/// A tela inicial pelo nível: a ordem dos caminhos, os que vêm marcados, o
/// texto de cada um e as regras de mexer nela.
abstract final class HomeSuggestion {
  /// A sugestão do nível [level]: os caminhos na ordem que faz sentido para
  /// ele, com os primeiros marcados. Os finais para você vêm logo antes das
  /// aulas de finais e, quando elas estão marcadas, marcados também.
  static HomeLayout of(RatingLevel level) {
    const learn = HomePath.learn;
    const journey = HomePath.journey;
    const endgames = HomePath.endgames;
    const speedrun = HomePath.speedrun;
    const train = HomePath.train;
    final (order, marked) = switch (level) {
      RatingLevel.beginner => ([learn, journey, endgames, train, speedrun], 2),
      RatingLevel.casual => ([journey, endgames, train, speedrun, learn], 3),
      RatingLevel.intermediate => (
        [journey, endgames, train, speedrun, learn],
        4,
      ),
      RatingLevel.advanced => ([endgames, journey, speedrun, train, learn], 4),
      RatingLevel.expert => ([endgames, speedrun, train, journey, learn], 3),
      RatingLevel.master => ([speedrun, endgames, train, journey, learn], 3),
    };
    final visible = order.take(marked).toSet();
    final at = order.indexOf(endgames);
    final withForYou = [...order]..insert(at, HomePath.forYou);
    return HomeLayout(
      order: withForYou,
      visible: {...visible, if (visible.contains(endgames)) HomePath.forYou},
    );
  }

  /// O layout da tela: o ajustado pelo jogador ou, sem ajuste (ou sem nada
  /// gravado), a sugestão do nível atual.
  static HomeLayout resolve(HomeLayout? saved, RatingLevel level) =>
      saved != null && saved.custom ? saved : of(level);

  /// O layout com os caminhos [visible] marcados (no tour ou na
  /// configuração). Diferente da sugestão do nível, ele fica como ajustado.
  /// Nenhum marcado: não muda.
  static HomeLayout withVisible(
    HomeLayout layout,
    Set<HomePath> visible,
    RatingLevel level,
  ) {
    if (visible.isEmpty) return layout;
    return _marked(layout.copyWith(visible: visible), level);
  }

  /// Marca ou desmarca [path]. O último visível não sai: a tela nunca fica
  /// vazia.
  static HomeLayout toggle(
    HomeLayout layout,
    HomePath path,
    RatingLevel level,
  ) {
    final visible = {...layout.visible};
    if (!visible.remove(path)) visible.add(path);
    return withVisible(layout, visible, level);
  }

  /// Pode desmarcar [path]? Não, se ele for o último visível.
  static bool canHide(HomeLayout layout, HomePath path) =>
      !layout.visible.contains(path) || layout.visible.length > 1;

  /// Move o caminho da posição [from] para [to].
  static HomeLayout move(
    HomeLayout layout,
    int from,
    int to,
    RatingLevel level,
  ) {
    final order = [...layout.order];
    if (from < 0 || from >= order.length) return layout;
    final path = order.removeAt(from);
    order.insert(to.clamp(0, order.length), path);
    return _marked(layout.copyWith(order: order), level);
  }

  // Igual à sugestão do nível: segue o nível; diferente, fica como ajustado.
  static HomeLayout _marked(HomeLayout layout, RatingLevel level) {
    final suggestion = of(level);
    final same =
        suggestion.copyWith(custom: false) == layout.copyWith(custom: false);
    return layout.copyWith(custom: !same);
  }

  /// O texto de [path] para o nível [level]: a Jornada e as aulas falam com
  /// quem já joga; o speedrun desafia os fortes.
  static HomePathText textOf(HomePath path, RatingLevel level) =>
      switch (path) {
        HomePath.journey || HomePath.learn =>
          level == RatingLevel.beginner
              ? HomePathText.standard
              : HomePathText.player,
        HomePath.speedrun =>
          level == RatingLevel.expert || level == RatingLevel.master
              ? HomePathText.challenge
              : HomePathText.standard,
        HomePath.forYou ||
        HomePath.endgames ||
        HomePath.train => HomePathText.standard,
      };

  /// O caminho do cartão "Continuar": o da vez ([current]) se estiver
  /// visível; senão, o primeiro visível com progresso ([withProgress]). Nulo
  /// se nenhum visível tem progresso.
  static HomePath? continuePath(
    HomeLayout layout, {
    required HomePath current,
    required Set<HomePath> withProgress,
  }) {
    if (layout.visible.contains(current)) return current;
    // A aula de final aberta também vale para os finais para você.
    if (current == HomePath.endgames &&
        layout.visible.contains(HomePath.forYou)) {
      return HomePath.forYou;
    }
    for (final path in layout.shown) {
      if (withProgress.contains(path)) return path;
    }
    return null;
  }
}
