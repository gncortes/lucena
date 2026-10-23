import '../../../domain/models/endgame_lesson.dart';
import 'endgame_progress_repository.dart';

/// Avisa cada gravação do progresso das aulas de finais, para a conta
/// receber o progresso depois (E1.13).
class NotifyingEndgameProgressRepository implements EndgameProgressRepository {
  NotifyingEndgameProgressRepository(this._inner, this._onSaved);

  final EndgameProgressRepository _inner;
  final void Function() _onSaved;

  @override
  Future<EndgameProgress> load() => _inner.load();

  @override
  Future<void> save(EndgameProgress progress) async {
    await _inner.save(progress);
    _onSaved();
  }
}
