import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/coach/coach_repository.dart';
import '../../../domain/models/coach/coach.dart';

enum ModelGamesStatus { loading, ready, error }

final class ModelGamesState {
  const ModelGamesState({
    this.status = ModelGamesStatus.loading,
    this.modelGames = const [],
    this.aviso = false,
  });

  final ModelGamesStatus status;
  final List<ModelGame> modelGames;

  /// "Avisar quando chegar uma nova" (`conta.avisoModelos`).
  final bool aviso;

  ModelGamesState copyWith({
    ModelGamesStatus? status,
    List<ModelGame>? modelGames,
    bool? aviso,
  }) => ModelGamesState(
    status: status ?? this.status,
    modelGames: modelGames ?? this.modelGames,
    aviso: aviso ?? this.aviso,
  );
}

/// As partidas-modelo de uma abertura (`treinador_modelos/{eco}`) e o aviso
/// de partida nova, que vale para a conta toda.
class ModelGamesCubit extends Cubit<ModelGamesState> {
  ModelGamesCubit({required this._repository, required this.eco})
    : super(const ModelGamesState());

  final CoachRepository _repository;
  final String eco;
  StreamSubscription<CoachAccount?>? _account;

  Future<void> load() async {
    unawaited(_account?.cancel());
    _account = _repository.account().listen((c) {
      if (!isClosed) emit(state.copyWith(aviso: c?.modelGamesNotice ?? false));
    }, onError: (Object _) {});
    emit(state.copyWith(status: ModelGamesStatus.loading));
    try {
      final modelGames = await _repository.modelGames(eco);
      if (isClosed) return;
      emit(
        state.copyWith(status: ModelGamesStatus.ready, modelGames: modelGames),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(status: ModelGamesStatus.error));
    }
  }

  /// Muda na hora e grava; se a gravação falhar, volta o que era.
  Future<void> setNotice({required bool linked}) async {
    final before = state.aviso;
    emit(state.copyWith(aviso: linked));
    try {
      await _repository.setModelGamesNotice(linked: linked);
    } on Object {
      if (!isClosed) emit(state.copyWith(aviso: before));
    }
  }

  @override
  Future<void> close() async {
    await _account?.cancel();
    return super.close();
  }
}
