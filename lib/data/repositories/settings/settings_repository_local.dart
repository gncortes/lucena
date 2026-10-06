import '../../../domain/models/app_accent.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/clock_settings.dart';
import '../../services/preferences_service.dart';
import 'settings_repository.dart';

/// Preferências gravadas no aparelho.
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._preferences);

  static const _languageKey = 'settings.language';
  static const _themeKey = 'settings.theme';
  static const _accentKey = 'settings.accent';
  static const _boardColorsKey = 'board.colors';
  static const _boardPiecesKey = 'board.pieces';
  static const _boardCoordinatesKey = 'board.coordinates';
  static const _boardMoveMethodKey = 'board.moveMethod';
  static const _boardLegalMovesKey = 'board.legalMoves';
  static const _boardLastMoveKey = 'board.lastMove';
  static const _boardAnimationKey = 'board.animation';
  static const _boardPremovesKey = 'board.premoves';
  static const _boardNotationKey = 'board.notation';
  static const _clockPositionKey = 'clock.position';
  static const _clockVibrationKey = 'clock.lowTimeVibration';
  static const _speedrunTimeKey = 'clock.speedrunTime';
  static const _journeyTimeKey = 'clock.journeyTime';
  static const _characterTalkKey = 'characters.talk';
  static const _soundKey = 'sound.enabled';

  final PreferencesService _preferences;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      languageCode: await _preferences.getString(_languageKey),
      themeMode: AppThemeMode.fromCode(await _preferences.getString(_themeKey)),
      accent: AppAccent.fromCode(await _preferences.getString(_accentKey)),
      board: await _loadBoard(),
      clock: ClockSettings(
        position: ClockPosition.fromCode(
          await _preferences.getString(_clockPositionKey),
        ),
        lowTimeVibration:
            await _preferences.getBool(_clockVibrationKey) ??
            const ClockSettings().lowTimeVibration,
        speedrunTime:
            TimeControl.tryParse(
              await _preferences.getString(_speedrunTimeKey),
            ) ??
            const ClockSettings().speedrunTime,
        // Sem nada gravado (ou "sem relógio"), o desafio fica sem relógio.
        journeyTime: TimeControl.tryParse(
          await _preferences.getString(_journeyTimeKey),
        ),
      ),
      characterTalk:
          await _preferences.getBool(_characterTalkKey) ??
          const AppSettings().characterTalk,
      sound: await _preferences.getBool(_soundKey) ?? const AppSettings().sound,
    );
  }

  // Preferência nunca gravada fica com o valor de fábrica.
  Future<BoardSettings> _loadBoard() async {
    const defaults = BoardSettings();
    return BoardSettings(
      colors: BoardColors.fromCode(
        await _preferences.getString(_boardColorsKey),
      ),
      pieces: PieceStyle.fromCode(
        await _preferences.getString(_boardPiecesKey),
      ),
      coordinates:
          await _preferences.getBool(_boardCoordinatesKey) ??
          defaults.coordinates,
      moveMethod: MoveMethod.fromCode(
        await _preferences.getString(_boardMoveMethodKey),
      ),
      showLegalMoves:
          await _preferences.getBool(_boardLegalMovesKey) ??
          defaults.showLegalMoves,
      highlightLastMove:
          await _preferences.getBool(_boardLastMoveKey) ??
          defaults.highlightLastMove,
      animation:
          await _preferences.getBool(_boardAnimationKey) ?? defaults.animation,
      premoves:
          await _preferences.getBool(_boardPremovesKey) ?? defaults.premoves,
      notation: MoveNotation.fromCode(
        await _preferences.getString(_boardNotationKey),
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final languageCode = settings.languageCode;
    if (languageCode == null) {
      await _preferences.remove(_languageKey);
    } else {
      await _preferences.setString(_languageKey, languageCode);
    }
    await _preferences.setString(_themeKey, settings.themeMode.code);
    final accent = settings.accent;
    if (accent == null) {
      await _preferences.remove(_accentKey);
    } else {
      await _preferences.setString(_accentKey, accent.code);
    }
    await _saveBoard(settings.board);
    await _preferences.setString(
      _clockPositionKey,
      settings.clock.position.code,
    );
    await _preferences.setBool(
      _clockVibrationKey,
      value: settings.clock.lowTimeVibration,
    );
    await _preferences.setString(
      _speedrunTimeKey,
      settings.clock.speedrunTime.code,
    );
    await _preferences.setString(
      _journeyTimeKey,
      settings.clock.journeyTime?.code ?? 'none',
    );
    await _preferences.setBool(
      _characterTalkKey,
      value: settings.characterTalk,
    );
    await _preferences.setBool(_soundKey, value: settings.sound);
  }

  Future<void> _saveBoard(BoardSettings board) async {
    await _preferences.setString(_boardColorsKey, board.colors.code);
    await _preferences.setString(_boardPiecesKey, board.pieces.code);
    await _preferences.setBool(_boardCoordinatesKey, value: board.coordinates);
    await _preferences.setString(_boardMoveMethodKey, board.moveMethod.code);
    await _preferences.setBool(
      _boardLegalMovesKey,
      value: board.showLegalMoves,
    );
    await _preferences.setBool(
      _boardLastMoveKey,
      value: board.highlightLastMove,
    );
    await _preferences.setBool(_boardAnimationKey, value: board.animation);
    await _preferences.setBool(_boardPremovesKey, value: board.premoves);
    await _preferences.setString(_boardNotationKey, board.notation.code);
  }
}
