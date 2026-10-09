import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/sound/sound_repository.dart';
import '../../../domain/models/app_accent.dart';
import '../../../domain/models/app_language.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../domain/models/game_sound.dart';

/// Preferências do app. O estado é nulo até a primeira leitura terminar.
class SettingsCubit extends Cubit<AppSettings?> {
  SettingsCubit(this._repository, {required this.languages, this._sound})
    : super(null);

  final SettingsRepository _repository;

  // Para tocar a amostra ao ligar os sons; nulo nos testes que não ligam.
  final SoundRepository? _sound;

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

  /// Troca a cor predominante do app.
  Future<void> setAccent(AppAccent accent) {
    return _update((state ?? const AppSettings()).copyWith(accent: accent));
  }

  /// Troca as preferências do tabuleiro.
  Future<void> setBoard(BoardSettings board) {
    return _update((state ?? const AppSettings()).copyWith(board: board));
  }

  /// Mostra ou esconde as marcações do professor no tabuleiro das aulas.
  Future<void> setLessonMarks({required bool shown}) {
    return _update((state ?? const AppSettings()).copyWith(lessonMarks: shown));
  }

  /// Troca as preferências do relógio.
  Future<void> setClock(ClockSettings clock) {
    return _update((state ?? const AppSettings()).copyWith(clock: clock));
  }

  /// Liga ou desliga as falas dos personagens.
  Future<void> setCharacterTalk({required bool enabled}) {
    return _update(
      (state ?? const AppSettings()).copyWith(characterTalk: enabled),
    );
  }

  /// Liga ou desliga os sons do jogo. Ao ligar, toca o som de um lance,
  /// para o usuário ouvir o que escolheu.
  Future<void> setSound({required bool enabled}) async {
    await _update((state ?? const AppSettings()).copyWith(sound: enabled));
    if (enabled) await _sound?.play(GameSound.move);
  }

  /// O tempo de pensar nas aulas (1, 3 ou 5 minutos, ou 0, o recomendado):
  /// escolhido, a aula não pergunta mais.
  Future<void> setThinkMinutes(int minutes) => _update(
    (state ?? const AppSettings()).copyWith(
      thinkMinutes: minutes,
      thinkChosen: true,
    ),
  );

  /// Liga ou desliga a vibração do app.
  Future<void> setVibration({required bool enabled}) =>
      _update((state ?? const AppSettings()).copyWith(vibration: enabled));

  /// Mostra ou esconde a barra de avaliação na revisão da partida.
  Future<void> setEvalBar({required bool enabled}) =>
      _update((state ?? const AppSettings()).copyWith(evalBar: enabled));

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
