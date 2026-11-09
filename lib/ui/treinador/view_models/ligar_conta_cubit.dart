import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';

/// Ligar a conta do Lichess ou do chess.com.
final class LigarContaState {
  const LigarContaState({
    required this.plataforma,
    this.usuario = '',
    this.enviando = false,
    this.falha,
    this.ligada = false,
  });

  final Plataforma plataforma;
  final String usuario;
  final bool enviando;
  final FalhaLigarConta? falha;
  final bool ligada;

  bool get podeEnviar => !enviando && usuario.trim().isNotEmpty;

  LigarContaState copyWith({
    String? usuario,
    bool? enviando,
    FalhaLigarConta? Function()? falha,
    bool? ligada,
  }) => LigarContaState(
    plataforma: plataforma,
    usuario: usuario ?? this.usuario,
    enviando: enviando ?? this.enviando,
    falha: falha == null ? this.falha : falha(),
    ligada: ligada ?? this.ligada,
  );
}

final class LigarContaCubit extends Cubit<LigarContaState> {
  LigarContaCubit({required this.repository, required Plataforma plataforma})
    : super(LigarContaState(plataforma: plataforma));

  final TreinadorRepository repository;

  void digitar(String usuario) =>
      emit(state.copyWith(usuario: usuario, falha: () => null));

  Future<void> ligar() async {
    if (!state.podeEnviar) return;
    emit(state.copyWith(enviando: true, falha: () => null));
    try {
      await repository.ligarConta(state.plataforma, state.usuario.trim());
      if (!isClosed) emit(state.copyWith(enviando: false, ligada: true));
    } on LigarContaException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(enviando: false, falha: () => e.falha));
      }
    } on Object {
      if (!isClosed) {
        emit(
          state.copyWith(
            enviando: false,
            falha: () => FalhaLigarConta.semResposta,
          ),
        );
      }
    }
  }
}
