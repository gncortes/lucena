import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/game_setup.dart';
import '../../services/preferences_service.dart';
import 'training_repository.dart';

/// Preferências do treino gravadas no aparelho.
class LocalTrainingRepository implements TrainingRepository {
  LocalTrainingRepository(this._preferences);

  static const _filterKey = 'catalog.goal';
  static const _clockKey = 'setup.clock';
  static const _userTimeKey = 'setup.userTime';
  static const _opponentTimeKey = 'setup.opponentTime';
  static const _opponentKey = 'setup.opponent';
  static const _maiaLevelKey = 'setup.maiaLevel';
  static const _blindKey = 'setup.blind';
  static const _draftFenKey = 'custom.fen';
  static const _draftGoalKey = 'custom.goal';

  final PreferencesService _preferences;

  @override
  Future<GoalFilter> loadCatalogFilter() async =>
      GoalFilter.fromCode(await _preferences.getString(_filterKey));

  @override
  Future<void> saveCatalogFilter(GoalFilter filter) =>
      _preferences.setString(_filterKey, filter.code);

  @override
  Future<GameSetup> loadSetup() async {
    const defaults = GameSetup();
    return GameSetup(
      clock: await _preferences.getBool(_clockKey) ?? defaults.clock,
      userTime:
          TimeControl.tryParse(await _preferences.getString(_userTimeKey)) ??
          defaults.userTime,
      opponentTime:
          TimeControl.tryParse(
            await _preferences.getString(_opponentTimeKey),
          ) ??
          defaults.opponentTime,
      opponent: OpponentKind.trainingFromCode(
        await _preferences.getString(_opponentKey),
      ),
      maiaLevel: int.tryParse(
        await _preferences.getString(_maiaLevelKey) ?? '',
      ),
      blind: await _preferences.getBool(_blindKey) ?? defaults.blind,
    );
  }

  @override
  Future<void> saveSetup(GameSetup setup) async {
    await _preferences.setBool(_clockKey, value: setup.clock);
    await _preferences.setString(_userTimeKey, setup.userTime.code);
    await _preferences.setString(_opponentTimeKey, setup.opponentTime.code);
    await _preferences.setString(_opponentKey, setup.opponent.code);
    await _preferences.setBool(_blindKey, value: setup.blind);
    final level = setup.maiaLevel;
    if (level != null) await _preferences.setString(_maiaLevelKey, '$level');
  }

  @override
  Future<CustomPositionDraft?> loadCustomDraft() async {
    final fen = await _preferences.getString(_draftFenKey);
    if (fen == null) return null;
    final goal =
        PositionGoal.fromCode(await _preferences.getString(_draftGoalKey)) ??
        PositionGoal.win;
    return (fen: fen, goal: goal);
  }

  @override
  Future<void> saveCustomDraft(CustomPositionDraft draft) async {
    await _preferences.setString(_draftFenKey, draft.fen);
    await _preferences.setString(_draftGoalKey, draft.goal.code);
  }
}
