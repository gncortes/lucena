import '../models/goal_preference.dart';
import '../models/home_layout.dart';
import '../models/rating_level.dart';
import 'visible_lessons.dart';

/// Qual texto um caminho mostra na tela inicial, pelo nível do jogador.
enum HomePathText {
  /// O de quem está começando.
  standard,

  /// O de desafio, para os fortes.
  challenge,
}

/// A tela inicial pelo nível: a ordem dos caminhos, os que vêm marcados, o
/// texto de cada um e as regras de mexer nela.
abstract final class HomeSuggestion {
  /// A sugestão do nível [level]: os caminhos na ordem que faz sentido para
  /// ele, com os primeiros marcados. Os finais para você vêm logo antes das
  /// aulas de finais e, quando elas estão marcadas, marcados também.
  ///
  /// Sem a Escola ([school] falso, enquanto [VisibleLessons] não libera aula
  /// dela), as aulas do Viktor saem da lista e o próximo caminho sobe.
  ///
  /// Com o objetivo [goal] (decisão 2a da E1.11), o caminho dele vem
  /// primeiro, marcado, e o resto segue a ordem e os marcados do nível. Com as aulas de
  /// finais primeiro, os finais para você vêm logo depois delas.
  ///
  /// Sem o curso ([course] falso, sem aula de final liberada), as aulas de
  /// finais e os finais para você saem também.
  static HomeLayout of(
    RatingLevel level, {
    bool? school,
    bool course = true,
    GoalPreference? goal,
  }) {
    const learn = HomePath.learn;
    const journey = HomePath.journey;
    const endgames = HomePath.endgames;
    const speedrun = HomePath.speedrun;
    const train = HomePath.train;
    const race = HomePath.race;
    final (order, marked) = switch (level) {
      RatingLevel.beginner => (
        [learn, journey, endgames, train, speedrun, race],
        2,
      ),
      RatingLevel.casual => (
        [journey, endgames, train, speedrun, race, learn],
        3,
      ),
      RatingLevel.intermediate => (
        [journey, endgames, train, speedrun, race, learn],
        4,
      ),
      RatingLevel.advanced => (
        [endgames, journey, speedrun, race, train, learn],
        4,
      ),
      RatingLevel.expert => (
        [endgames, speedrun, race, train, journey, learn],
        3,
      ),
      RatingLevel.master => (
        [speedrun, endgames, race, train, journey, learn],
        3,
      ),
    };
    // Quem quer aprender a jogar fica com a Escola, primeira e marcada, mesmo
    // sem aula liberada (ela abre como as peças se movem).
    final learning = goal == GoalPreference.learn;
    if (!learning && !(school ?? VisibleLessons.school)) order.remove(learn);
    if (!course) order.remove(endgames);
    // Os marcados são os do nível; o do objetivo entra junto.
    final first = goal == null
        ? null
        : goalPath(goal, school: school, course: course);
    final visible = {
      ...order.where((p) => p != race).take(marked),
      ?first,
      if (learning) learn,
    };
    for (final path in [?first, if (learning) learn]) {
      order
        ..remove(path)
        ..insert(0, path);
    }
    final at = order.indexOf(endgames);
    final withForYou = [...order];
    if (course) {
      withForYou.insert(first == endgames ? at + 1 : at, HomePath.forYou);
    }
    // As Estrelas vêm logo depois dos Problemas, marcadas também.
    withForYou.insert(withForYou.indexOf(race) + 1, HomePath.stars);
    return HomeLayout(
      order: withForYou,
      visible: {
        ...visible,
        if (course && visible.contains(endgames)) HomePath.forYou,
        race,
        HomePath.stars,
      },
    );
  }

  /// O layout da tela: o ajustado pelo jogador ou, sem ajuste (ou sem nada
  /// gravado), a sugestão do nível atual. Sem a Escola, as aulas do Viktor saem também do ajustado.
  static HomeLayout resolve(
    HomeLayout? saved,
    RatingLevel level, {
    bool? school,
    bool course = true,
    GoalPreference? goal,
  }) {
    if (saved == null || !saved.custom) {
      return of(level, school: school, course: course, goal: goal);
    }
    final hidden = {
      if (goal != GoalPreference.learn && !(school ?? VisibleLessons.school))
        HomePath.learn,
      if (!course) ...[HomePath.endgames, HomePath.forYou],
    };
    if (hidden.isEmpty) return saved;
    final order = [
      for (final path in saved.order)
        if (!hidden.contains(path)) path,
    ];
    final visible = {...saved.visible}..removeAll(hidden);
    return saved.copyWith(
      order: order,
      visible: visible.isEmpty ? {order.first} : visible,
    );
  }

  /// O caminho do cartão do objetivo [goal]. Sem a Escola, aprender a jogar
  /// cai na Jornada (a tela inicial nunca fica sem o cartão do objetivo).
  /// Sem o curso, aprender finais cai em treinar finais.
  static HomePath goalPath(
    GoalPreference goal, {
    bool? school,
    bool course = true,
  }) {
    if (goal == GoalPreference.learn && !(school ?? VisibleLessons.school)) {
      return HomePath.journey;
    }
    if (goal == GoalPreference.endgames && !course) return HomePath.train;
    return goal.path;
  }

  /// O layout com os caminhos [visible] marcados (no tour ou na
  /// configuração). Diferente da sugestão do nível, ele fica como ajustado.
  /// Nenhum marcado: não muda.
  static HomeLayout withVisible(
    HomeLayout layout,
    Set<HomePath> visible,
    RatingLevel level, {
    GoalPreference? goal,
  }) {
    if (visible.isEmpty) return layout;
    return _marked(layout.copyWith(visible: visible), level, goal);
  }

  /// Marca ou desmarca [path]. O último visível não sai: a tela nunca fica
  /// vazia.
  static HomeLayout toggle(
    HomeLayout layout,
    HomePath path,
    RatingLevel level, {
    GoalPreference? goal,
  }) {
    final visible = {...layout.visible};
    if (!visible.remove(path)) visible.add(path);
    return withVisible(layout, visible, level, goal: goal);
  }

  /// Pode desmarcar [path]? Não, se ele for o último visível.
  static bool canHide(HomeLayout layout, HomePath path) =>
      !layout.visible.contains(path) || layout.visible.length > 1;

  /// Move o caminho da posição [from] para [to].
  static HomeLayout move(
    HomeLayout layout,
    int from,
    int to,
    RatingLevel level, {
    GoalPreference? goal,
  }) {
    final order = [...layout.order];
    if (from < 0 || from >= order.length) return layout;
    final path = order.removeAt(from);
    order.insert(to.clamp(0, order.length), path);
    return _marked(layout.copyWith(order: order), level, goal);
  }

  // Igual à sugestão do nível (e do objetivo): segue o nível; diferente,
  // fica como ajustado.
  static HomeLayout _marked(
    HomeLayout layout,
    RatingLevel level,
    GoalPreference? goal,
  ) {
    final suggestion = of(level, goal: goal);
    final same =
        suggestion.copyWith(custom: false) == layout.copyWith(custom: false);
    return layout.copyWith(custom: !same);
  }

  /// O texto de [path] para o nível [level]: o speedrun desafia os fortes;
  /// os outros têm um texto só.
  static HomePathText textOf(HomePath path, RatingLevel level) =>
      switch (path) {
        HomePath.speedrun =>
          level == RatingLevel.expert || level == RatingLevel.master
              ? HomePathText.challenge
              : HomePathText.standard,
        HomePath.journey ||
        HomePath.learn ||
        HomePath.forYou ||
        HomePath.endgames ||
        HomePath.train ||
        HomePath.race ||
        HomePath.stars => HomePathText.standard,
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
