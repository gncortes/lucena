import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Abre telas de configuração do sistema (o canal fica no `MainActivity`).
class SystemSettingsService {
  const SystemSettingsService();

  static const _channel = MethodChannel('lucena/system_settings');

  /// A tela de texto para fala do aparelho, onde ficam as vozes. Falso se
  /// não deu para abrir (outra plataforma, aparelho sem a tela).
  Future<bool> openTextToSpeech() async {
    try {
      return await _channel.invokeMethod<bool>('openTextToSpeech') ?? false;
    } on Object catch (error) {
      debugPrint('SystemSettingsService.openTextToSpeech: $error');
      return false;
    }
  }
}
