import '../../../domain/models/app_settings.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../services/preferences_service.dart';
import 'settings_repository.dart';

/// Preferências gravadas no aparelho.
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._preferences);

  static const _languageKey = 'settings.language';
  static const _themeKey = 'settings.theme';
  static const _boardColorsKey = 'board.colors';
  static const _boardPiecesKey = 'board.pieces';
  static const _boardCoordinatesKey = 'board.coordinates';

  final PreferencesService _preferences;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      languageCode: await _preferences.getString(_languageKey),
      themeMode: AppThemeMode.fromCode(await _preferences.getString(_themeKey)),
      board: await _loadBoard(),
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
    await _saveBoard(settings.board);
  }

  Future<void> _saveBoard(BoardSettings board) async {
    await _preferences.setString(_boardColorsKey, board.colors.code);
    await _preferences.setString(_boardPiecesKey, board.pieces.code);
    await _preferences.setBool(_boardCoordinatesKey, value: board.coordinates);
  }
}
