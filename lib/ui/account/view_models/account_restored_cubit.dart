import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/progress_summary.dart';
import '../../../domain/use_cases/mastery.dart';

class AccountRestoredState {
  const AccountRestoredState({
    this.ready = false,
    this.failed = false,
    this.current,
    this.characters = const [],
  });

  final bool ready;

  /// A leitura da Jornada falhou: erro padrão com "Tentar novamente".
  final bool failed;

  /// O degrau em que a pessoa está (nulo: a Jornada inteira foi concluída).
  final RungProgress? current;
  final List<Character> characters;
}

/// "Bem-vindo de volta" (H-CON-10): a Jornada do progresso que voltou, no
/// degrau atual ("Valdini, 4 de 9 desafios").
class AccountRestoredCubit extends Cubit<AccountRestoredState> {
  AccountRestoredCubit(this._summary, this._journey, this._characters)
    : super(const AccountRestoredState());

  final ProgressSummary _summary;
  final JourneyRepository _journey;
  final CharacterRepository _characters;

  Future<void> load() async {
    emit(const AccountRestoredState());
    try {
      final start = _summary.startRung;
      final progress = Mastery.of(
        await _journey.ladder(),
        _summary.challenges,
        startRung: start == null ? null : '$start',
      );
      final characters = await _characters.characters();
      if (!isClosed) {
        emit(
          AccountRestoredState(
            ready: true,
            current: progress.current,
            characters: characters,
          ),
        );
      }
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) emit(const AccountRestoredState(failed: true));
    }
  }
}
