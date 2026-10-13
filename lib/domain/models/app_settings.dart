import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_accent.dart';
import 'app_theme_mode.dart';
import 'board_settings.dart';
import 'clock_settings.dart';
import 'endgame_filter.dart';
import 'history_filter.dart';

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

    /// Nas aulas de finais, os filtros da lista (tipo, dificuldade,
    /// situação) e a ordem.
    @Default(EndgameFilter()) EndgameFilter endgamesFilter,

    /// Nas aulas, as marcações do professor no tabuleiro (setas e casas).
    @Default(true) bool lessonMarks,

    /// Nas aulas, no modo variante, os lances que o aluno ainda não viu ficam
    /// cobertos (T69).
    @Default(true) bool lessonHiddenMoves,

    /// A aba do Histórico em que o jogador parou.
    @Default(HistoryTab.games) HistoryTab historyTab,

    /// Os filtros de cada aba do Histórico.
    @Default(GamesHistoryFilter()) GamesHistoryFilter historyGamesFilter,
    @Default(SpeedrunHistoryFilter())
    SpeedrunHistoryFilter historyClassicFilter,
    @Default(SpeedrunHistoryFilter())
    SpeedrunHistoryFilter historyMarathonFilter,
  }) = _AppSettings;
}
