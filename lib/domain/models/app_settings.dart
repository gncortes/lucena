import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_accent.dart';
import 'app_theme_mode.dart';
import 'board_settings.dart';
import 'clock_settings.dart';

part 'app_settings.freezed.dart';

/// Preferências do app. Tudo aqui é salvo e volta ao reabrir.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// Código do idioma escolhido (`es`, `pt_PT`...). Nulo segue o sistema.
    String? languageCode,

    /// Tema claro, escuro ou o do aparelho.
    @Default(AppThemeMode.system) AppThemeMode themeMode,

    /// Cor predominante do app. Nula: a de fábrica de cada tema (azul no
    /// claro, verde no escuro).
    AppAccent? accent,

    /// Aparência e comportamento do tabuleiro.
    @Default(BoardSettings()) BoardSettings board,

    /// Onde o relógio aparece e como ele avisa.
    @Default(ClockSettings()) ClockSettings clock,

    /// Os personagens comentam a partida num balão de fala.
    @Default(true) bool characterTalk,

    /// Os sons do jogo: o das peças a cada lance e o aviso do relógio.
    @Default(true) bool sound,

    /// O retorno tátil: lances, vitórias, conquistas e o aviso do relógio.
    @Default(true) bool vibration,

    /// A barra de avaliação da engine na revisão da partida.
    @Default(true) bool evalBar,

    /// Nas aulas de finais, com o teste de nível feito: a trilha inteira
    /// ("Todos") em vez do roteiro ("Para você") (T52).
    @Default(false) bool endgamesAll,

    /// Nas aulas de finais, em "Para você": esconder as aulas já concluídas.
    @Default(false) bool endgamesHideDone,
  }) = _AppSettings;
}
