import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/review/game_review_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/history_filter.dart';
import '../../../domain/models/player_rating.dart';
import '../../../domain/use_cases/history_games.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/speedrun_history_rows.dart';
import '../../speedrun/view_models/speedrun_bonus_payer.dart';

/// O Histórico: o rating e as partidas que contaram, e os speedruns do
/// Clássico e da Maratona, com a aba e os filtros de cada uma.
class HistoryState {
  const HistoryState({
    this.loaded = false,
    this.tab = HistoryTab.games,
    this.gamesFilter = const GamesHistoryFilter(),
    this.classicFilter = const SpeedrunHistoryFilter(),
    this.marathonFilter = const SpeedrunHistoryFilter(),
    this.current,
    this.history = const [],
    this.games = const [],
    this.classic = const [],
    this.marathons = const [],
    this.characters = const [],
    this.now,
    this.highlightedGame,
  });

  /// Falso até a primeira leitura terminar.
  final bool loaded;
  final HistoryTab tab;
  final GamesHistoryFilter gamesFilter;
  final SpeedrunHistoryFilter classicFilter;
  final SpeedrunHistoryFilter marathonFilter;

  final PlayerRating? current;

  /// O rating depois de cada partida e de cada bônus, do mais antigo para o
  /// mais recente.
  final List<RatingEntry> history;

  /// As partidas que contaram, da mais recente para a mais antiga, sem
  /// filtro.
  final List<HistoryGame> games;

  /// As linhas do Clássico e da Maratona, sem filtro.
  final List<SpeedrunHistoryRow> classic;
  final List<SpeedrunHistoryRow> marathons;
  final List<Character> characters;

  /// O instante da leitura: de onde os períodos contam para trás.
  final DateTime? now;

  /// A partida em destaque (`?game=` da rota). Nula: nenhuma.
  final int? highlightedGame;

  /// A partida em destaque, se ela está nas que contaram; senão nula (o id
  /// da rota é ignorado em silêncio).
  int? get highlighted =>
      games.any((game) => game.id == highlightedGame) ? highlightedGame : null;

  /// As partidas do filtro e o placar delas.
  List<HistoryGame> get filteredGames =>
      HistoryGames.filter(games, gamesFilter, now ?? DateTime.utc(2000));

  List<SpeedrunHistoryRow> rows(HistoryTab tab) => switch (tab) {
    HistoryTab.classic => SpeedrunHistoryRows.filter(classic, classicFilter),
    HistoryTab.marathon => SpeedrunHistoryRows.filter(
      marathons,
      marathonFilter,
    ),
    HistoryTab.games => const [],
  };
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required this._rating,
    required this._progress,
    required this._speedruns,
    required this._journey,
    required this._characters,
    required this._reviews,
    required this._settings,
    this._now = const SystemNow(),
    this.highlightedGame,
  }) : _bonus = SpeedrunBonusPayer(
         rating: _rating,
         speedruns: _speedruns,
         journey: _journey,
       ),
       super(const HistoryState());

  /// A partida em destaque (`?game=` da rota): abre em Partidas, com os
  /// filtros zerados só em memória.
  final int? highlightedGame;

  final RatingRepository _rating;
  final ProgressRepository _progress;
  final SpeedrunRepository _speedruns;
  final JourneyRepository _journey;
  final CharacterRepository _characters;
  final GameReviewRepository _reviews;
  final SettingsRepository _settings;
  final Now _now;
  final SpeedrunBonusPayer _bonus;

  Future<void> load() async {
    // O bônus de uma conclusão que fechou à força antes de ser gravado.
    await _bonus.payPending();
    final settings = await _settings.load();
    final current = await _rating.current();
    final history = await _rating.history();
    final bonuses = await _rating.speedrunBonuses();
    final attempts = await _progress.attemptsById({
      for (final entry in history) ?entry.gameId,
    });
    final sides = await _reviews.accuracies(attempts.keys);
    // A precisão do lado do jogador.
    final accuracies = <int, double>{
      for (final MapEntry(key: id, value: side) in sides.entries)
        id: ?(attempts[id]?.userSide == Side.black ? side.black : side.white),
    };
    final bases = await _journey.speedruns();
    final speedrunAttempts = await _speedruns.allAttempts();
    final characters = await _characters.characters();
    if (isClosed) return;
    final highlighted = highlightedGame != null;
    emit(
      HistoryState(
        loaded: true,
        tab: state.loaded
            ? state.tab
            : (highlighted ? HistoryTab.games : settings.historyTab),
        gamesFilter: state.loaded
            ? state.gamesFilter
            : (highlighted
                  ? const GamesHistoryFilter()
                  : settings.historyGamesFilter),
        classicFilter: state.loaded
            ? state.classicFilter
            : settings.historyClassicFilter,
        marathonFilter: state.loaded
            ? state.marathonFilter
            : settings.historyMarathonFilter,
        current: current,
        history: history,
        games: HistoryGames.build(
          history,
          attempts: attempts,
          accuracies: accuracies,
        ),
        classic: SpeedrunHistoryRows.build(
          bases: bases,
          attempts: speedrunAttempts,
          bonuses: bonuses,
          marathon: false,
        ),
        marathons: SpeedrunHistoryRows.build(
          bases: bases,
          attempts: speedrunAttempts,
          bonuses: bonuses,
          marathon: true,
        ),
        characters: characters,
        now: _now(),
        highlightedGame: highlightedGame,
      ),
    );
  }

  /// Troca de aba (toque ou arraste) e grava.
  Future<void> selectTab(HistoryTab tab) async {
    if (tab == state.tab) return;
    emit(_copy(tab: tab));
    await _save((settings) => settings.copyWith(historyTab: tab));
  }

  /// Aplica o filtro da aba Partidas e grava.
  Future<void> applyGamesFilter(GamesHistoryFilter filter) async {
    emit(_copy(gamesFilter: filter));
    await _save((settings) => settings.copyWith(historyGamesFilter: filter));
  }

  /// Aplica o filtro do Clássico e grava.
  Future<void> applyClassicFilter(SpeedrunHistoryFilter filter) async {
    emit(_copy(classicFilter: filter));
    await _save((settings) => settings.copyWith(historyClassicFilter: filter));
  }

  /// Aplica o filtro da Maratona e grava.
  Future<void> applyMarathonFilter(SpeedrunHistoryFilter filter) async {
    emit(_copy(marathonFilter: filter));
    await _save((settings) => settings.copyWith(historyMarathonFilter: filter));
  }

  HistoryState _copy({
    HistoryTab? tab,
    GamesHistoryFilter? gamesFilter,
    SpeedrunHistoryFilter? classicFilter,
    SpeedrunHistoryFilter? marathonFilter,
  }) => HistoryState(
    loaded: state.loaded,
    tab: tab ?? state.tab,
    gamesFilter: gamesFilter ?? state.gamesFilter,
    classicFilter: classicFilter ?? state.classicFilter,
    marathonFilter: marathonFilter ?? state.marathonFilter,
    current: state.current,
    history: state.history,
    games: state.games,
    classic: state.classic,
    marathons: state.marathons,
    characters: state.characters,
    now: state.now,
    highlightedGame: state.highlightedGame,
  );

  // Lê o gravado e muda só o campo pedido: o que está só em memória (o
  // filtro zerado do `?game=`) não vai junto.
  Future<void> _save(AppSettings Function(AppSettings) change) async =>
      _settings.save(change(await _settings.load()));
}
