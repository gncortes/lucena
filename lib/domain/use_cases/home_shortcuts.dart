import '../models/home_layout.dart';
import '../models/home_shortcut.dart';

/// Os atalhos da tela inicial (T83, prancha "Atalhos por usuário" v2): todos
/// os caminhos marcados em Configurações > Tela inicial, na ordem do nível
/// (o do objetivo primeiro), sem corte, com os finais para você dentro do
/// Curso de finais; os Problemas e as Estrelas vêm no fim. A grade é 2×N.
abstract final class HomeShortcuts {
  /// [order] e [visible] vêm do [HomeLayout] (a ordem e os marcados).
  /// [learning]: o objetivo "Aprender a jogar", que vê só a Escola, a
  /// Jornada, os Problemas e as Estrelas, nessa ordem (os marcados).
  static List<HomeShortcut> of({
    required List<HomePath> order,
    required Set<HomePath> visible,
    bool learning = false,
  }) {
    if (learning) {
      return [
        for (final path in const [
          HomePath.learn,
          HomePath.journey,
          HomePath.race,
          HomePath.stars,
        ])
          if (visible.contains(path)) ?_shortcut(path),
      ];
    }
    final shortcuts = <HomeShortcut>[];
    for (final path in order) {
      if (!visible.contains(path)) continue;
      final shortcut = _shortcut(path);
      if (shortcut == null ||
          shortcut == HomeShortcut.race ||
          shortcut == HomeShortcut.stars ||
          shortcuts.contains(shortcut)) {
        continue;
      }
      shortcuts.add(shortcut);
    }
    return [
      ...shortcuts,
      if (visible.contains(HomePath.race)) HomeShortcut.race,
      if (visible.contains(HomePath.stars)) HomeShortcut.stars,
    ];
  }

  static HomeShortcut? _shortcut(HomePath path) => switch (path) {
    HomePath.learn => HomeShortcut.school,
    HomePath.journey => HomeShortcut.journey,
    HomePath.forYou || HomePath.endgames => HomeShortcut.endgames,
    HomePath.train => HomeShortcut.train,
    HomePath.speedrun => HomeShortcut.speedrun,
    HomePath.race => HomeShortcut.race,
    HomePath.stars => HomeShortcut.stars,
  };
}
