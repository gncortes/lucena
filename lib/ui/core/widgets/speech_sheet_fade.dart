import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Enquanto a folha da fala inteira está aberta, o nome e o balão da faixa de
/// cima somem (a fala fica em evidência na folha, onde o retrato já foi
/// parar): o espaço continua reservado, para o tabuleiro não pular, e tudo
/// volta ao fechar (Gabriel, 14/10/2026; canvas `T70-etapa1-estados`).
///
/// [open] é ligado por `showScriptSpeechSheet`; o conteúdo da própria folha
/// fica fora do efeito ([SpeechSheetFade.exempt]).
class SpeechSheetFade extends StatelessWidget {
  const SpeechSheetFade({required this.child, super.key});

  final Widget child;

  /// A folha da fala está aberta?
  static final open = ValueNotifier<bool>(false);

  /// Põe em volta do conteúdo da folha, para o que está dentro dela (nome e
  /// balão do cabeçalho do exercício) não sumir.
  static Widget exempt({required Widget child}) =>
      _Exempt(open: _closed, child: child);

  static final ValueListenable<bool> _closed = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final scoped = context.dependOnInheritedWidgetOfExactType<_Exempt>();
    return ValueListenableBuilder<bool>(
      valueListenable: scoped?.open ?? open,
      child: child,
      builder: (context, hidden, child) => ExcludeSemantics(
        excluding: hidden,
        child: IgnorePointer(
          ignoring: hidden,
          child: AnimatedOpacity(
            opacity: hidden ? 0 : 1,
            duration: AppMotion.of(context).state,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Exempt extends InheritedWidget {
  const _Exempt({required this.open, required super.child});

  final ValueListenable<bool> open;

  @override
  bool updateShouldNotify(_Exempt old) => old.open != open;
}
