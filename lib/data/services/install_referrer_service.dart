import 'package:play_install_referrer/play_install_referrer.dart';

/// O `referrer` da Play Store: o texto que o link de instalação levou
/// (`play.google.com/store/apps/details?id=...&referrer=<texto>`), T84.
abstract class InstallReferrerService {
  /// O texto do referrer, ou nulo (sem Play, iOS, demorou, erro).
  Future<String?> referrer();
}

/// Lê pela Play Install Referrer API (`com.android.installreferrer`). Não
/// pede permissão perigosa nem identifica o aparelho.
class PlayInstallReferrerService implements InstallReferrerService {
  const PlayInstallReferrerService({this.timeout = const Duration(seconds: 3)});

  /// O app não espera mais que isso para abrir.
  final Duration timeout;

  @override
  Future<String?> referrer() async {
    try {
      final details = await PlayInstallReferrer.installReferrer.timeout(
        timeout,
      );
      return details.installReferrer;
    } on Object {
      // iOS, sem Play Services, tempo esgotado ou a API fora do ar: segue
      // sem referrer.
      return null;
    }
  }
}

/// Sem referrer (testes e plataformas sem Play).
class NoInstallReferrerService implements InstallReferrerService {
  const NoInstallReferrerService();

  @override
  Future<String?> referrer() async => null;
}
