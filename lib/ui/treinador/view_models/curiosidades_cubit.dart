import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/treinador/curiosidades_repository.dart';
import '../../../domain/models/treinador/curiosidade.dart';
import '../../../domain/use_cases/now.dart';

/// A curiosidade da espera da análise: começa por uma diferente a cada dia
/// e "Outra curiosidade" passa para a seguinte.
final class CuriosidadesState {
  const CuriosidadesState({this.todas = const [], this.indice = 0});

  final List<Curiosidade> todas;
  final int indice;

  Curiosidade? get atual => todas.isEmpty ? null : todas[indice % todas.length];
}

final class CuriosidadesCubit extends Cubit<CuriosidadesState> {
  CuriosidadesCubit({required this.repository, required this.now})
    : super(const CuriosidadesState());

  final CuriosidadesRepository repository;
  final Now now;

  Future<void> load() async {
    try {
      final todas = await repository.todas();
      if (isClosed || todas.isEmpty) return;
      final agora = now();
      final inicio = (agora.millisecondsSinceEpoch ~/ 60000) % todas.length;
      emit(CuriosidadesState(todas: todas, indice: inicio));
    } on Object {
      // Sem curiosidade, a espera mostra só a porcentagem.
    }
  }

  void outra() {
    if (state.todas.length < 2) return;
    emit(CuriosidadesState(todas: state.todas, indice: state.indice + 1));
  }
}
