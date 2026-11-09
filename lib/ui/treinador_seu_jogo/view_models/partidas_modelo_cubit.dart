import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';

enum PartidasModeloStatus { carregando, pronto, erro }

final class PartidasModeloState {
  const PartidasModeloState({
    this.status = PartidasModeloStatus.carregando,
    this.modelos = const [],
    this.aviso = false,
  });

  final PartidasModeloStatus status;
  final List<PartidaModelo> modelos;

  /// "Avisar quando chegar uma nova" (`conta.avisoModelos`).
  final bool aviso;

  PartidasModeloState copyWith({
    PartidasModeloStatus? status,
    List<PartidaModelo>? modelos,
    bool? aviso,
  }) => PartidasModeloState(
    status: status ?? this.status,
    modelos: modelos ?? this.modelos,
    aviso: aviso ?? this.aviso,
  );
}

/// As partidas-modelo de uma abertura (`treinador_modelos/{eco}`) e o aviso
/// de partida nova, que vale para a conta toda.
class PartidasModeloCubit extends Cubit<PartidasModeloState> {
  PartidasModeloCubit({required this._repository, required this.eco})
    : super(const PartidasModeloState());

  final TreinadorRepository _repository;
  final String eco;
  StreamSubscription<TreinadorConta?>? _conta;

  Future<void> load() async {
    unawaited(_conta?.cancel());
    _conta = _repository.conta().listen((c) {
      if (!isClosed) emit(state.copyWith(aviso: c?.avisoModelos ?? false));
    }, onError: (Object _) {});
    emit(state.copyWith(status: PartidasModeloStatus.carregando));
    try {
      final modelos = await _repository.modelos(eco);
      if (isClosed) return;
      emit(
        state.copyWith(status: PartidasModeloStatus.pronto, modelos: modelos),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(status: PartidasModeloStatus.erro));
    }
  }

  /// Muda na hora e grava; se a gravação falhar, volta o que era.
  Future<void> definirAviso({required bool ligado}) async {
    final antes = state.aviso;
    emit(state.copyWith(aviso: ligado));
    try {
      await _repository.definirAvisoModelos(ligado: ligado);
    } on Object {
      if (!isClosed) emit(state.copyWith(aviso: antes));
    }
  }

  @override
  Future<void> close() async {
    await _conta?.cancel();
    return super.close();
  }
}
