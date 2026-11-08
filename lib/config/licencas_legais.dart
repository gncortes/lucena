import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;

/// Registra na tela de licenças o aviso do Lucena (copyright, sem garantia,
/// AGPL-3.0 e o endereço do código-fonte) e as licenças do Stockfish (GPL-3.0)
/// e do Maia-3 (AGPL-3.0). O texto mora em `assets/legal/`.
void registrarLicencasLegais() {
  LicenseRegistry.addLicense(() async* {
    final aviso = await rootBundle.loadString('assets/legal/aviso_lucena.txt');
    final agpl = await rootBundle.loadString('assets/legal/AGPL-3.0.txt');
    final gpl = await rootBundle.loadString('assets/legal/GPL-3.0.txt');
    yield LicenseEntryWithLineBreaks(['Lucena'], '$aviso\n\n$agpl');
    yield LicenseEntryWithLineBreaks(
      ['Stockfish'],
      'Stockfish, motor de xadrez (Stockfish developers). GNU GPL-3.0.\n\n$gpl',
    );
    yield LicenseEntryWithLineBreaks(
      ['Maia-3'],
      'Maia-3, modelo e pesos (CSSLab, University of Toronto). GNU AGPL-3.0.\n\n$agpl',
    );
  });
}
