import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/voice/voice_repository_local.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/data/services/tts_service.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _ProjectBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await io.File(key).readAsBytes());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Cada chamada cria repositório e serviços novos, como ao reabrir o app.
  LocalVoiceRepository reopen() => LocalVoiceRepository(
    PreferencesService(),
    AssetService(_ProjectBundle()),
    TtsService(),
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('sem nada gravado, a voz começa desligada', () async {
    expect(await reopen().load(), const VoiceSettings());
  });

  test('as escolhas voltam ao reabrir', () async {
    const settings = VoiceSettings(
      enabled: true,
      speed: 1.2,
      teacherVoice: 'pt-br-x-a',
      characterVoices: {'grandpa': 'pt-br-x-b'},
    );
    await reopen().save(settings);
    expect(await reopen().load(), settings);
  });

  test('preferência estragada volta ao padrão', () async {
    await PreferencesService().setString('voice', '{oops');
    expect(await reopen().load(), const VoiceSettings());
    await PreferencesService().setString('voice', jsonEncode({'speed': 'x'}));
    expect(await reopen().load(), const VoiceSettings());
  });

  test('os perfis do JSON: o Viktor e os oito adversários', () async {
    final profiles = await reopen().profiles();
    expect(profiles.keys, hasLength(9));
    for (final id in [
      'master',
      'beachgoer',
      'grandpa',
      'snob',
      'magician',
      'prodigy',
      'bodybuilder',
      'foodie',
      'youngster',
    ]) {
      expect(profiles[id], isNotNull, reason: id);
      expect(io.File('assets/characters/$id.json').existsSync(), isTrue);
    }
    // O Tito fala mais grave e mais devagar que a Zuri.
    expect(profiles['grandpa']!.pitch, lessThan(profiles['prodigy']!.pitch));
    expect(profiles['grandpa']!.rate, lessThan(profiles['prodigy']!.rate));
  });
}
