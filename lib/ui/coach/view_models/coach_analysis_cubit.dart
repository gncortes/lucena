import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/coach/coach_repository.dart';
import '../../../domain/models/coach/coach.dart';

enum CoachAnalysisStatus { loading, ready, notFound, offline }

/// A partida da análise completa do Treinador.
final class CoachAnalysisState {
  const CoachAnalysisState({
    this.status = CoachAnalysisStatus.loading,
    this.game,
  });

  final CoachAnalysisStatus status;
  final CoachGame? game;
}

/// Lê a partida da análise (até [timeout]) e marca `progresso.viuAnalise`
/// (o funil do painel), uma vez por partida.
final class CoachAnalysisCubit extends Cubit<CoachAnalysisState> {
  CoachAnalysisCubit({
    required this.repository,
    required this.id,
    this.timeout = const Duration(seconds: 20),
  }) : super(const CoachAnalysisState());

  final CoachRepository repository;
  final String id;
  final Duration timeout;

  Future<void> load() async {
    unawaited(_markViewed());
    try {
      final game = await repository.game(id).first.timeout(timeout);
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
      final progress = await repository.progress(id);
      if (progress.sawAnalysis) return;
      await repository.saveProgress(id, progress.withAnalysisViewed());
    } on Object catch (e) {
      debugPrint('análise vista sem gravar: $e');
    }
  }
}
