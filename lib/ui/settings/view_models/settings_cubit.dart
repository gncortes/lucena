import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/app_language.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';

/// Preferências do app. O estado é nulo até a primeira leitura terminar.
class SettingsCubit extends Cubit<AppSettings?> {
  SettingsCubit(this._repository, {required this.languages}) : super(null);

  final SettingsRepository _repository;

  /// Idiomas oferecidos na tela de idioma.
  final List<AppLanguage> languages;

  Future<void> load() async => emit(await _repository.load());

  /// Troca o idioma do app. Nulo volta a seguir o idioma do sistema.
  Future<void> setLanguage(AppLanguage? language) {
    return _update(
      (state ?? const AppSettings()).copyWith(languageCode: language?.code),
    );
  }

  /// Troca o tema do app.
  Future<void> setThemeMode(AppThemeMode themeMode) {
    return _update(
      (state ?? const AppSettings()).copyWith(themeMode: themeMode),
    );
  }

  /// Troca as preferências do tabuleiro.
  Future<void> setBoard(BoardSettings board) {
    return _update((state ?? const AppSettings()).copyWith(board: board));
  }

  /// Troca as preferências do relógio.
  Future<void> setClock(ClockSettings clock) {
    return _update((state ?? const AppSettings()).copyWith(clock: clock));
  }

  /// Cores, peças e coordenadas de fábrica; o resto do tabuleiro não muda.
  Future<void> resetBoardAppearance() {
    final settings = state ?? const AppSettings();
    return setBoard(settings.board.withDefaultAppearance());
  }

  // O estado muda na hora; a gravação vem em seguida.
  Future<void> _update(AppSettings settings) async {
    emit(settings);
    await _repository.save(settings);
  }
}
