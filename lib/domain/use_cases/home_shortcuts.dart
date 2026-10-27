import '../models/home_layout.dart';
import '../models/home_shortcut.dart';

/// Os quatro atalhos da tela inicial (T83, prancha "Atalhos por tipo de
/// usuário"): a ordem do nível, sem a Escola, sem o caminho do cartão de
/// cima e sem a Jornada vencida, com os finais para você dentro do Curso de
/// finais. Ficam os três primeiros e os Problemas; faltando um, as Estrelas.
abstract final class HomeShortcuts {
  /// Quantos atalhos a grade mostra.
  static const count = 4;

  /// [order] é a ordem dos caminhos ([HomeLayout.order]); [hero] o caminho
  /// do cartão de cima. [learning]: o objetivo "Aprender a jogar", que vê as
  /// Estrelas primeiro e, antes da primeira vitória ([firstWin] falso), só
  /// elas e os Problemas. [journeyDone]: a Jornada vencida até o fim.
  static List<HomeShortcut> of({
    required List<HomePath> order,
    HomePath? hero,
    bool learning = false,
    bool firstWin = true,
    bool journeyDone = false,
  }) {
    if (learning && !firstWin) {
      return const [HomeShortcut.stars, HomeShortcut.race];
    }
    final skip = {?_shortcut(hero), if (journeyDone) HomeShortcut.journey};
    final paths = <HomeShortcut>[];
    for (final path in order) {
      final shortcut = _shortcut(path);
      if (shortcut == null || shortcut == HomeShortcut.race) continue;
      if (skip.contains(shortcut) || paths.contains(shortcut)) continue;
      paths.add(shortcut);
    }
    final shortcuts = [
      if (learning) HomeShortcut.stars,
      ...paths.take(learning ? count - 2 : count - 1),
      HomeShortcut.race,
    ];
    if (shortcuts.length < count && !shortcuts.contains(HomeShortcut.stars)) {
      shortcuts.add(HomeShortcut.stars);
    }
    return shortcuts;
  }

  static HomeShortcut? _shortcut(HomePath? path) => switch (path) {
    HomePath.journey => HomeShortcut.journey,
    HomePath.forYou || HomePath.endgames => HomeShortcut.endgames,
    HomePath.train => HomeShortcut.train,
    HomePath.speedrun => HomeShortcut.speedrun,
    HomePath.race => HomeShortcut.race,
    HomePath.learn || null => null,
  };
}
