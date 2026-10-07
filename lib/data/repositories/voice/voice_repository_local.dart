import 'dart:convert';

import '../../../domain/models/voice.dart';
import '../../services/asset_service.dart';
import '../../services/preferences_service.dart';
import '../../services/system_settings_service.dart';
import '../../services/tts_service.dart';
import 'voice_repository.dart';

/// Preferências no aparelho, perfis em `assets/voices/profiles.json` e a
/// voz do sistema.
class LocalVoiceRepository implements VoiceRepository {
  LocalVoiceRepository(
    this._preferences,
    this._assets,
    this._tts, {
    this._system = const SystemSettingsService(),
  });

  final PreferencesService _preferences;
  final AssetService _assets;
  final TtsService _tts;
  final SystemSettingsService _system;
  Future<List<TtsVoice>>? _voices;
  Future<Map<String, CharacterVoiceProfile>>? _profiles;

  static const _key = 'voice';
  static const profilesAsset = 'assets/voices/profiles.json';

  @override
  Future<VoiceSettings> load() async {
    final text = await _preferences.getString(_key);
    if (text == null) return const VoiceSettings();
    try {
      return VoiceSettings.fromJson(jsonDecode(text));
    } on FormatException {
      return const VoiceSettings();
    }
  }

  @override
  Future<void> save(VoiceSettings settings) =>
      _preferences.setString(_key, jsonEncode(settings.toJson()));

  @override
  Future<List<TtsVoice>> voices({bool refresh = false}) {
    if (refresh) _voices = _tts.voices(refresh: true);
    return _voices ??= _tts.voices();
  }

  @override
  Future<Map<String, CharacterVoiceProfile>> profiles() =>
      _profiles ??= _loadProfiles();

  Future<Map<String, CharacterVoiceProfile>> _loadProfiles() async {
    final json = jsonDecode(await _assets.loadString(profilesAsset));
    if (json is! Map<String, dynamic>) return const {};
    return {
      for (final e in json.entries)
        if (e.value is Map<String, dynamic>)
          e.key: CharacterVoiceProfile.fromJson(
            e.key,
            e.value as Map<String, dynamic>,
          ),
    };
  }

  @override
  Future<void> speak(String text, ResolvedVoice voice) =>
      _tts.speak(text, voice);

  @override
  Future<void> stop() => _tts.stop();

  @override
  Stream<TtsEvent> get events => _tts.events;

  @override
  Future<bool> openSystemVoices() => _system.openTextToSpeech();
}
