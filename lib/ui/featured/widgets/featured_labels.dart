import 'package:flutter/material.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/models/game_setup.dart';
import '../../core/l10n/countries.dart';
import '../../core/l10n/l10n.dart';

/// Os textos e os ícones dos finais em destaque. Um conceito, um ícone, em
/// todas as telas (cartão, lista, livrinho).
abstract final class FeaturedLabels {
  static IconData originIcon(FeaturedOrigin origin) => switch (origin) {
    FeaturedOrigin.tournament => Icons.stadium_outlined,
    FeaturedOrigin.video => Icons.smart_display_outlined,
    FeaturedOrigin.online => Icons.computer_outlined,
    FeaturedOrigin.historical => Icons.history,
    FeaturedOrigin.challenge => Icons.campaign_outlined,
  };

  static String origin(AppLocalizations l10n, FeaturedOrigin origin) =>
      switch (origin) {
        FeaturedOrigin.tournament => l10n.featuredOriginTournament,
        FeaturedOrigin.video => l10n.featuredOriginVideo,
        FeaturedOrigin.online => l10n.featuredOriginOnline,
        FeaturedOrigin.historical => l10n.featuredOriginHistorical,
        FeaturedOrigin.challenge => l10n.featuredOriginChallenge,
      };

  static String theme(AppLocalizations l10n, FeaturedTheme theme) =>
      switch (theme) {
        FeaturedTheme.escapedWin => l10n.featuredThemeEscapedWin,
        FeaturedTheme.perfectConversion => l10n.featuredThemePerfectConversion,
        FeaturedTheme.resourcefulDefense =>
          l10n.featuredThemeResourcefulDefense,
        FeaturedTheme.decisiveMistake => l10n.featuredThemeDecisiveMistake,
      };

  /// O nome do país por extenso. Código sem nome volta como veio.
  static String country(AppLocalizations l10n, String code) =>
      Countries.name(l10n, code);

  static String players(AppLocalizations l10n, FeaturedEndgame endgame) =>
      l10n.featuredPlayers(endgame.white.name, endgame.black.name);

  /// Só os sobrenomes ("Carlsen × So"), para o cartão.
  static String shortPlayers(AppLocalizations l10n, FeaturedEndgame endgame) =>
      l10n.featuredPlayers(_surname(endgame.white), _surname(endgame.black));

  static String _surname(FeaturedPlayer player) {
    final parts = player.name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? player.name : parts.last;
  }

  /// "Torneio · Rodada 5" ("rodada 5" com [inline]); sem rodada, só o torneio;
  /// sem torneio, a origem.
  static String subtitle(
    AppLocalizations l10n,
    String language,
    FeaturedEndgame endgame,
    FeaturedTournament? tournament, {
    bool inline = false,
  }) {
    if (tournament == null) return origin(l10n, endgame.origin);
    final name = tournament.nameIn(language);
    final round = endgame.round;
    if (round == null) return name;
    // No cartão a rodada segue a linha dos jogadores, em minúscula.
    return inline
        ? l10n.featuredCardRound(name, round)
        : l10n.featuredTournamentRound(name, round);
  }

  /// "Norway Chess 2017": evento e ano do cartão. Sem torneio, a origem.
  static String eventYear(
    AppLocalizations l10n,
    String language,
    FeaturedEndgame endgame,
    FeaturedTournament? tournament,
  ) => tournament == null
      ? origin(l10n, endgame.origin)
      : _withYear(l10n, tournament.nameIn(language), tournament.year);

  /// O ano só entra quando o nome do evento ainda não o traz
  /// ("Norway Chess 2017" não vira "Norway Chess 2017 2017").
  static String _withYear(AppLocalizations l10n, String name, int year) =>
      name.contains('$year') ? name : l10n.featuredEventYear(name, year);

  /// O personagem do adversário (o Stockfish, ou o do nível do Maia). Nulo
  /// quando o nível não tem personagem.
  static Character? character(
    List<Character> characters,
    FeaturedChoice choice,
  ) => choice.opponent == OpponentKind.stockfish || choice.level == null
      ? Character.stockfish
      : characters.forLevel(choice.level);

  /// O adversário, para a linha de configuração: "Percival · 1400", o mesmo
  /// nome da partida; "Stockfish" sem nível.
  static String opponent(
    AppLocalizations l10n,
    FeaturedChoice choice,
    List<Character> characters,
  ) {
    if (choice.opponent == OpponentKind.stockfish || choice.level == null) {
      return l10n.featuredOpponentStockfish;
    }
    final character = characters.forLevel(choice.level);
    return character == null
        ? l10n.featuredOpponentMaia(choice.level!)
        : l10n.characterNameLevel(character.name, choice.level!);
  }

  /// `180+0` vira "3+0".
  static String clock(AppLocalizations l10n, FeaturedChoice choice) {
    final time = choice.time;
    return time == null ? l10n.featuredNoClock : clockCode(choice.clock!);
  }

  static String clockCode(String code) {
    final time = TimeControl.tryParse(code);
    if (time == null) return code;
    return '${time.initial.inMinutes}+${time.increment.inSeconds}';
  }

  /// Os relógios que a folha oferece (segundos+incremento).
  static const clocks = <String?>[null, '180+0', '300+0', '600+0'];
}
