import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_theme_mode.dart';
import 'board_settings.dart';

part 'app_settings.freezed.dart';

/// Preferências do app. Tudo aqui é salvo e volta ao reabrir.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// Código do idioma escolhido (`es`, `pt_PT`...). Nulo segue o sistema.
    String? languageCode,

    /// Tema claro, escuro ou o do aparelho.
    @Default(AppThemeMode.system) AppThemeMode themeMode,

    /// Aparência e comportamento do tabuleiro.
    @Default(BoardSettings()) BoardSettings board,
  }) = _AppSettings;
}
