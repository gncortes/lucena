import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/review/review_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/use_cases/lesson_count.dart';
import '../../../domain/use_cases/review_policy.dart';

/// O pedido de avaliação da loja (E1.26): 1,5 s depois de uma aula concluída
/// ou de uma vitória num final. Quem decide é a `ReviewPolicy`. O estado diz
/// se o pedido foi feito.
class ReviewPromptCubit extends Cubit<bool> {
  ReviewPromptCubit({
    required this._review,
    required this._school,
    required this._endgames,
    required this._progress,
    this.delay = ReviewPolicy.delay,
  }) : super(false);

  final ReviewRepository _review;
  final SchoolProgressRepository _school;
  final EndgameProgressRepository _endgames;
  final ProgressRepository _progress;
  final Duration delay;

  Timer? _timer;

  /// Agenda o pedido; sair da tela antes cancela.
  void ask() {
    _timer?.cancel();
    _timer = Timer(delay, _ask);
  }

  Future<void> _ask() async {
    if (isClosed) return;
    final asked = await _review.maybeAsk(
      lessonsCompleted: LessonCount.completed(
        await _school.load(),
        await _endgames.load(),
      ),
      endgamesWon: LessonCount.wins(await _progress.allAttempts()),
    );
    if (!isClosed) emit(asked);
  }

  /// Uma derrota: não pede logo depois.
  void noteSetback() {
    _timer?.cancel();
    _review.noteSetback();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
