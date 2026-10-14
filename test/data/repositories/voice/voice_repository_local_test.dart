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

  test('os perfis do JSON: os oito adversários, sem o Viktor', () async {
    final profiles = await reopen().profiles();
    const ids = [
      'beachgoer',
      'grandpa',
      'snob',
      'magician',
      'prodigy',
      'bodybuilder',
      'foodie',
      'youngster',
    ];
    expect(profiles.keys, unorderedEquals(ids));
    final raw = jsonDecode(
      io.File('assets/voices/profiles.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final id in ids) {
      expect(io.File('assets/characters/$id.json').existsSync(), isTrue);
      final entry = raw[id] as Map<String, dynamic>;
      expect(['m', 'f'], contains(entry['genero']), reason: id);
      expect(
        ['crianca', 'jovem', 'adulto', 'idoso'],
        contains(entry['idade']),
        reason: id,
      );
    }
    expect(profiles['grandpa']!.age, VoiceAge.elder);
    expect(profiles['prodigy']!.gender, VoiceGender.female);
    expect(profiles['prodigy']!.age, VoiceAge.child);
  });

  test('known.json: só "m" ou "f"', () async {
    final raw = jsonDecode(
      io.File('assets/voices/known.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final e in raw.entries) {
      expect(['m', 'f'], contains(e.value), reason: e.key);
    }
    final known = await reopen().knownGenders();
    expect(known.length, raw.length);
  });
}
