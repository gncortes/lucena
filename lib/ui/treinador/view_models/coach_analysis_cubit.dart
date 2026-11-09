import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';

enum CoachAnalysisStatus { loading, ready, notFound, offline }

/// A partida da análise completa do Treinador.
final class CoachAnalysisState {
  const CoachAnalysisState({
    this.status = CoachAnalysisStatus.loading,
    this.game,
  });

  final CoachAnalysisStatus status;
  final PartidaTreinador? game;
}

/// Lê a partida da análise (até [timeout]) e marca `progresso.viuAnalise`
/// (o funil do painel), uma vez por partida.
final class CoachAnalysisCubit extends Cubit<CoachAnalysisState> {
  CoachAnalysisCubit({
    required this.repository,
    required this.id,
    this.timeout = const Duration(seconds: 20),
  }) : super(const CoachAnalysisState());

  final TreinadorRepository repository;
  final String id;
  final Duration timeout;

  Future<void> load() async {
    unawaited(_markViewed());
    try {
      final game = await repository.partida(id).first.timeout(timeout);
      if (isClosed) return;
      emit(
        CoachAnalysisState(
          status: game == null
              ? CoachAnalysisStatus.notFound
              : CoachAnalysisStatus.ready,
          game: game,
        ),
      );
    } on Object {
      if (!isClosed) {
        emit(const CoachAnalysisState(status: CoachAnalysisStatus.offline));
      }
    }
  }

  Future<void> _markViewed() async {
    try {
      final progresso = await repository.progresso(id);
      if (progresso.viuAnalise) return;
      await repository.salvarProgresso(id, progresso.comAnaliseVista());
    } on Object catch (e) {
      debugPrint('análise vista sem gravar: $e');
    }
  }
}
