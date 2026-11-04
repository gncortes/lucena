import 'package:flutter/animation.dart';

/// Os tempos e curvas das animações aprovadas (T85, H-ANI-01): a fonte é
/// `docs/tasks/T85-historias/animacoes/motion-spec.md`. Nenhum widget de
/// `lib/ui/core/motion/` escreve `Duration` ou `Cubic` fora daqui (teste
/// `tokens_soltos_test.dart`).
///
/// Os tokens antigos de [AppMotion] continuam nas telas que já existiam; os
/// widgets do kit de movimento usam só estes.
abstract final class LucenaMotion {
  // Curvas (Material 3).

  /// Padrão de quase tudo: o que se move dentro da tela.
  static const emphasized = Cubic(.2, 0, 0, 1);

  /// Entrada: algo aparece.
  static const emphasizedDecelerate = Cubic(.05, .7, .1, 1);

  /// Saída: algo some.
  static const emphasizedAccelerate = Cubic(.3, 0, .8, .15);

  /// Saída curta (eixo X, fade through).
  static const standardAccelerate = Cubic(.3, 0, 1, 1);

  /// Véu, dissolve e giro do carregando.
  static const linear = Curves.linear;

  // Reduzir movimento.

  /// Com "remover animações", o que sobra é este fade (ou nada).
  static const fadeReduzido = Duration(milliseconds: 100);
}
