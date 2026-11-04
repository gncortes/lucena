import 'package:flutter/widgets.dart';

import 'entradas_vistas.dart';

/// "Remover animações" do sistema (H-ANI-01). Todo widget de movimento
/// consulta aqui: com a opção ligada, nada sobe, escala, treme ou se desenha;
/// sobra um fade de `LucenaMotion.fadeReduzido` ou nada.
abstract final class MovimentoReduzido {
  /// `true` quando o sistema pede para remover as animações.
  static bool of(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// A entrada da tela anima: movimento ligado e primeira entrada da tela na
  /// sessão ([EntradaDaTela]). Mudança real (número que subiu, chip trocado)
  /// não passa por aqui: anima sempre, salvo com movimento reduzido.
  static bool animarEntrada(BuildContext context) =>
      !of(context) && EntradaDaTela.primeira(context);
}
