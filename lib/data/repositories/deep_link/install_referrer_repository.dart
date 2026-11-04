import '../../../domain/use_cases/install_referrer_rules.dart';
import '../../services/install_referrer_service.dart';
import '../../services/preferences_service.dart';

/// O link de campanha que veio pela instalação da Play (deferred deep link,
/// T84): quem tocou no link sem o app instalado passa pela loja e, na 1ª
/// abertura, cai no mesmo desafio (ou aula).
abstract class InstallReferrerRepository {
  /// O link do referrer, só na 1ª vez que é pedido no aparelho; depois,
  /// sempre nulo (o referrer da Play não muda e não pode reabrir o desafio).
  Future<Uri?> pendingLink();
}

class ServiceInstallReferrerRepository implements InstallReferrerRepository {
  ServiceInstallReferrerRepository(this._service, this._preferences);

  final InstallReferrerService _service;
  final PreferencesService _preferences;

  static const _readKey = 'campaign.referrerRead';
  static const _attemptsKey = 'campaign.referrerAttempts';

  /// Quantas aberturas seguidas tentam ler o referrer antes de desistir: uma
  /// falha da Play não pode perder a campanha, mas um aparelho sem Play
  /// também não pode esperar o limite de tempo para sempre.
  static const maxAttempts = 3;

  @override
  Future<Uri?> pendingLink() async {
    if (await _preferences.getBool(_readKey) ?? false) return null;
    final String? referrer;
    try {
      referrer = await _service.referrer();
    } on InstallReferrerFailure {
      // Gap 6: a leitura falhou, a campanha continua para a próxima abertura
      // (até [maxAttempts]).
      final attempts =
          (int.tryParse(await _preferences.getString(_attemptsKey) ?? '') ??
              0) +
          1;
      await _preferences.setString(_attemptsKey, '$attempts');
      if (attempts >= maxAttempts) {
        await _preferences.setBool(_readKey, value: true);
      }
      return null;
    }
    await _preferences.setBool(_readKey, value: true);
    return InstallReferrerRules.link(referrer);
  }
}

/// Sem Play (testes e o padrão das dependências): nunca há link pendente.
class NoInstallReferrerRepository implements InstallReferrerRepository {
  const NoInstallReferrerRepository();

  @override
  Future<Uri?> pendingLink() async => null;
}
