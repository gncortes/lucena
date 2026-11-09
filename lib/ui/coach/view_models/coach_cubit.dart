import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../../data/repositories/coach/coach_preferences.dart';
import '../../../data/repositories/coach/coach_repository.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/coach/coach_rules.dart';

/// A casca do Treinador (abas Hoje, Partidas e Seu jogo): a conta ligada, as
/// partidas, o plano e o filtro da lista.
final class CoachState {
  const CoachState({
    this.loading = true,
    this.failed = false,
    this.account,
    this.games = const [],
    this.grant = false,
    this.filter = GameFilter.everyone,
  });

  final bool loading;

  /// A leitura das partidas falhou (sem rede na primeira vez, servidor fora).
  final bool failed;
  final CoachAccount? account;

  /// Da mais recente para a mais antiga.
  final List<CoachGame> games;
  final bool grant;
  final GameFilter filter;

  bool get noAccount => !loading && account == null;
  CoachGame? get last => games.isEmpty ? null : games.first;
  List<CoachGame> get filtered => filter.apply(games);

  CoachState copyWith({
    bool? loading,
    bool? failed,
    CoachAccount? Function()? account,
    List<CoachGame>? games,
    bool? grant,
    GameFilter? filter,
  }) => CoachState(
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    account: account == null ? this.account : account(),
    games: games ?? this.games,
    grant: grant ?? this.grant,
    filter: filter ?? this.filter,
  );
}

final class CoachCubit extends Cubit<CoachState> {
  CoachCubit({
    required this.repository,
    required this.grants,
    required this.preferences,
    required this.now,
  }) : super(const CoachState());

  final CoachRepository repository;
  final CourseGrantsRepository grants;
  final CoachPreferences preferences;
  final Now now;

  StreamSubscription<CoachAccount?>? _account;
  StreamSubscription<List<CoachGame>>? _games;
  StreamSubscription<Object?>? _grants;
  bool _accountArrived = false;
  bool _gamesArrived = false;
  bool _accountFailed = false;
  bool _gamesFailed = false;

  Future<void> load() async {
    final filter = await preferences.filter();
    if (isClosed) return;
    emit(
      state.copyWith(
        filter: filter,
        grant: CoachRules.hasAccess(grants.current, now()),
      ),
    );
    _grants ??= grants.changes.listen((g) {
      if (!isClosed) {
        emit(state.copyWith(grant: CoachRules.hasAccess(g, now())));
      }
    });
    _listen();
  }

  void _listen() {
    _account?.cancel();
    _games?.cancel();
    _accountArrived = false;
    _gamesArrived = false;
    _accountFailed = false;
    _gamesFailed = false;
    _account = repository.account().listen((account) {
      _accountArrived = true;
      _accountFailed = false;
      if (isClosed) return;
      emit(
        state.copyWith(
          account: () => account,
          loading: !_ready && !_failed,
          failed: _failed,
        ),
      );
    }, onError: (_) => _fail(account: true));
    _games = repository.games().listen((list) {
      _gamesArrived = true;
      _gamesFailed = false;
      if (isClosed) return;
      emit(
        state.copyWith(
          games: list,
          loading: !_ready && !_failed,
          failed: _failed,
        ),
      );
    }, onError: (_) => _fail(account: false));
  }

  bool get _ready => _accountArrived && _gamesArrived;

  /// Uma das leituras falhou; a outra, vinda do cache, não apaga o erro.
  bool get _failed => _accountFailed || _gamesFailed;

  void _fail({required bool account}) {
    if (account) {
      _accountFailed = true;
    } else {
      _gamesFailed = true;
    }
    if (!isClosed) emit(state.copyWith(loading: false, failed: true));
  }

  /// "Tentar de novo" do erro de leitura.
  void retry() {
    emit(state.copyWith(loading: true, failed: false));
    _listen();
  }

  Future<void> applyFilter(GameFilter filter) async {
    emit(state.copyWith(filter: filter));
    await preferences.saveFilter(filter);
  }

  Future<void> clearFilters() => applyFilter(GameFilter.everyone);

  @override
  Future<void> close() async {
    await _account?.cancel();
    await _games?.cancel();
    await _grants?.cancel();
    await super.close();
  }
}
