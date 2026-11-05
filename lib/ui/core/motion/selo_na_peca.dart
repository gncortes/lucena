import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_colors.dart';
import '../widgets/board/piece_badge_overlay.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O selo sobre a peça (H-ANI-12): ✓ e ✗ do retorno do lance, `!!`, `??`
/// das anotações. Nasce no canto de cima à direita da [casa], um pouco para
/// fora dela ([PieceBadgeGeometry]): na fileira de cima sai por cima do
/// tabuleiro; nas laterais e embaixo é empurrado para dentro.
///
/// Entra com o salto de H-ANI-11 (0 → 1,2 → 1 em 260 ms); a posição não
/// anima. Com movimento reduzido ou [saltar] falso, aparece parado.
///
/// Ocupa o tabuleiro inteiro (empilhe sobre ele, do mesmo tamanho) e não
/// recebe toques.
class SeloNaPeca extends StatefulWidget {
  const SeloNaPeca({
    required this.casa,
    required this.orientacao,
    required this.tamanho,
    required this.cor,
    required this.child,
    this.saltar = true,
    this.chave = MotionKeys.seloNaPeca,
    super.key,
  });

  final Square casa;
  final Side orientacao;

  /// Lado do tabuleiro.
  final double tamanho;

  /// O fundo redondo do selo.
  final Color cor;

  /// O que vai dentro do selo (ícone ou símbolo), que se ajusta ao tamanho.
  final Widget child;

  final bool saltar;

  /// A key do círculo do selo.
  final Key chave;

  /// A escala do salto em [t] (0 a 1 dos 260 ms): sobe a 1,2 e volta a 1.
  static final salto = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: 1.2,
      ).chain(CurveTween(curve: LucenaMotion.emphasizedDecelerate)),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.2,
        end: 1,
      ).chain(CurveTween(curve: LucenaMotion.emphasized)),
      weight: 40,
    ),
  ]);

  @override
  State<SeloNaPeca> createState() => _SeloNaPecaState();
}

class _SeloNaPecaState extends State<SeloNaPeca>
    with SingleTickerProviderStateMixin {
  late final _salto = AnimationController(
    vsync: this,
    duration: LucenaMotion.saltoDoSelo,
  );
  bool _decidido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decidido) return;
    _decidido = true;
    if (widget.saltar && !MovimentoReduzido.of(context)) {
      _salto.forward();
    } else {
      _salto.value = 1;
    }
  }

  @override
  void dispose() {
    _salto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = PieceBadgeGeometry.rect(
      square: widget.casa,
      orientation: widget.orientacao,
      boardSize: widget.tamanho,
    );
    return IgnorePointer(
      child: SizedBox.square(
        dimension: widget.tamanho,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRect(
              rect: r,
              child: ScaleTransition(
                scale: _salto.drive(SeloNaPeca.salto),
                child: Container(
                  key: widget.chave,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.cor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.trainingFabShadow,
                        blurRadius: 1,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: FittedBox(child: widget.child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
