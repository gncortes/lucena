import 'dart:convert';

import '../../services/preferences_service.dart';

/// Uma tentativa de lance falado no modo às cegas: o que o reconhecedor
/// devolveu, o que o app entendeu e quanto demorou.
class BlindAttempt {
  const BlindAttempt({
    required this.at,
    required this.alternatives,
    required this.result,
    required this.latencyMs,
    required this.onDevice,
    this.san,
  });

  final DateTime at;
  final List<String> alternatives;

  /// `move`, `ambiguous`, `unknown`, `command`, `failed`.
  final String result;

  /// O lance jogado, quando houve.
  final String? san;

  /// Do soltar o botão (ou do fim da fala) até o lance aplicado.
  final int latencyMs;

  /// O reconhecimento foi só no aparelho.
  final bool onDevice;

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'alternatives': alternatives,
    'result': result,
    'san': san,
    'latencyMs': latencyMs,
    'onDevice': onDevice,
  };

  static BlindAttempt? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['at']}');
    final alternatives = json['alternatives'];
    final result = json['result'];
    if (at == null || alternatives is! List || result is! String) return null;
    return BlindAttempt(
      at: at,
      alternatives: [for (final a in alternatives) '$a'],
      result: result,
      san: json['san'] is String ? json['san'] as String : null,
      latencyMs: json['latencyMs'] is int ? json['latencyMs'] as int : 0,
      onDevice: json['onDevice'] == true,
    );
  }
}

/// As medições do modo às cegas, guardadas no aparelho (spike da T40).
abstract class BlindLogRepository {
  Future<void> add(BlindAttempt attempt);

  Future<List<BlindAttempt>> all();

  /// Todas as medições em JSON, para copiar e colar no relatório.
  Future<String> export();

  Future<void> clear();
}

class LocalBlindLogRepository implements BlindLogRepository {
  LocalBlindLogRepository(this._preferences);

  final PreferencesService _preferences;
  static const _key = 'blind.log';

  /// As mais antigas saem depois desse tanto.
  static const max = 2000;

  @override
  Future<void> add(BlindAttempt attempt) async {
    final list = [...await all(), attempt];
    final kept = list.length > max ? list.sublist(list.length - max) : list;
    await _preferences.setString(
      _key,
      jsonEncode([for (final a in kept) a.toJson()]),
    );
  }

  @override
  Future<List<BlindAttempt>> all() async {
    final text = await _preferences.getString(_key);
    if (text == null) return const [];
    try {
      final json = jsonDecode(text);
      if (json is! List) return const [];
      return [for (final item in json) ?BlindAttempt.fromJson(item)];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<String> export() async =>
      const JsonEncoder.withIndent('  ')
          .convert([for (final a in await all()) a.toJson()]);

  @override
  Future<void> clear() => _preferences.remove(_key);
}
