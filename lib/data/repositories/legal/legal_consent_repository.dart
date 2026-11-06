import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/use_cases/now.dart';
import '../../services/firebase/cloud_store_service.dart';
import '../../services/preferences_service.dart';

/// O aceite dos Termos de uso e da Política de privacidade (H-CON-08): logo
/// depois de criar a conta, uma vez por conta.
abstract class LegalConsentRepository {
  /// A versão dos textos aceitos ("Versão 1" no começo dos dois).
  static const version = 1;

  /// A conta [uid] já aceitou a versão atual neste aparelho.
  Future<bool> accepted(String uid);

  /// A conta [uid] entrou e falta o aceite: se o app fechar antes de
  /// "Continuar", ele reabre no aceite.
  Future<void> markPending(String uid);

  /// A conta com aceite pendente (nula: nenhuma).
  Future<String?> pending();

  /// Grava o aceite no aparelho e na conta (sem rede, sobe depois).
  Future<void> accept(String uid);
}

class LocalLegalConsentRepository implements LegalConsentRepository {
  LocalLegalConsentRepository(
    this._preferences,
    this._cloud, {
    required this._now,
  });

  final PreferencesService _preferences;
  final CloudStoreService _cloud;
  final Now _now;

  static const _pendingKey = 'account.legal.pending';
  static String _acceptedKey(String uid) =>
      'account.legal.acceptedVersion.$uid';

  @override
  Future<bool> accepted(String uid) async {
    final saved = await _preferences.getString(_acceptedKey(uid));
    return saved == '${LegalConsentRepository.version}';
  }

  @override
  Future<void> markPending(String uid) =>
      _preferences.setString(_pendingKey, uid);

  @override
  Future<String?> pending() async {
    final uid = await _preferences.getString(_pendingKey);
    if (uid == null || await accepted(uid)) return null;
    return uid;
  }

  @override
  Future<void> accept(String uid) async {
    await _preferences.setString(
      _acceptedKey(uid),
      '${LegalConsentRepository.version}',
    );
    await _preferences.remove(_pendingKey);
    // O Firestore guarda sem rede e manda quando ela volta: não espera.
    unawaited(
      _cloud
          .mergeUser(uid, {
            // As regras pedem o updatedAt em toda gravação do perfil.
            'updatedAt': _now(),
            'legal': {
              'acceptedVersion': LegalConsentRepository.version,
              'acceptedAt': _now().toUtc().toIso8601String(),
            },
          })
          .catchError((Object error) {
            debugPrint('legal consent upload failed: $error');
          }),
    );
  }
}

/// Sem conta (F-Droid) não há aceite a pedir.
class NoLegalConsentRepository implements LegalConsentRepository {
  const NoLegalConsentRepository();

  @override
  Future<bool> accepted(String uid) async => true;

  @override
  Future<void> markPending(String uid) async {}

  @override
  Future<String?> pending() async => null;

  @override
  Future<void> accept(String uid) async {}
}
