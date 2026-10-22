import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Abre telas de configuração do sistema e o app de e-mail (o canal fica no
/// `MainActivity`).
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

  /// Os ajustes de notificação do Lucena (ou os do app, em Android antigo).
  Future<bool> openAppNotifications() async {
    try {
      return await _channel.invokeMethod<bool>('openAppNotifications') ?? false;
    } on Object catch (error) {
      debugPrint('SystemSettingsService.openAppNotifications: $error');
      return false;
    }
  }

  /// Se há app de e-mail no aparelho.
  Future<bool> hasEmailApp() async {
    try {
      return await _channel.invokeMethod<bool>('hasEmailApp') ?? false;
    } on Object catch (error) {
      debugPrint('SystemSettingsService.hasEmailApp: $error');
      return false;
    }
  }

  /// O app de e-mail, na caixa de entrada.
  Future<bool> openEmailApp() async {
    try {
      return await _channel.invokeMethod<bool>('openEmailApp') ?? false;
    } on Object catch (error) {
      debugPrint('SystemSettingsService.openEmailApp: $error');
      return false;
    }
  }
}
