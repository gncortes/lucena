import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_colors.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O tamanho da [Celebracao]: grande no fim de curso e da Escola, pequena no
/// fim de lição e de abertura.
enum TamanhoDaCelebracao { grande, pequena }

/// A comemoração de fim de curso ou de lição (H-ANI-15): o diploma ([child])
/// escala de 0,88 a 1,03 e assenta em 1 em 520 ms (`emphasized`), e o confete
/// (40 partículas na grande, menos na pequena) cai em 950 ms, com até 420 ms
/// de atraso entre elas. Acaba em 1,4 s.
///
/// O confete cai sobre a área do [Celebracao]; envolva a tela inteira para
/// ele cobrir tudo. Com movimento reduzido, sem confete: o diploma aparece com
/// fade de 100 ms.
class Celebracao extends StatefulWidget {
  const Celebracao({
    required this.child,
    this.tamanho = TamanhoDaCelebracao.grande,
    this.diploma,
    super.key,
  });

  /// O conteúdo da tela.
  final Widget child;
  final TamanhoDaCelebracao tamanho;

  /// O diploma que escala; sem ele, escala o [child] inteiro.
  final Widget? diploma;

  @override
  State<Celebracao> createState() => _CelebracaoState();
}

class _CelebracaoState extends State<Celebracao>
    with SingleTickerProviderStateMixin {
  static final _total =
      LucenaMotion.quedaDoConfete + LucenaMotion.atrasoDoConfete;

  late final AnimationController _controle;
  late final bool _reduzido;
  late final List<ParticulaDoConfete> _particulas;
  var _iniciado = false;

  static final _escala = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: LucenaMotion.escalaDoDiploma,
        end: LucenaMotion.picoDoDiploma,
      ).chain(CurveTween(curve: LucenaMotion.emphasized)),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: LucenaMotion.picoDoDiploma,
        end: 1.0,
      ).chain(CurveTween(curve: LucenaMotion.emphasized)),
      weight: 40,
    ),
  ]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _reduzido = MovimentoReduzido.of(context);
    _controle = AnimationController(
      vsync: this,
      duration: _reduzido ? LucenaMotion.fadeDaCelebracao : _total,
    )..forward();
    _particulas = _reduzido ? const [] : _sortear(context);
  }

  List<ParticulaDoConfete> _sortear(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = [
      esquema.primary,
      esquema.secondary,
      esquema.tertiary,
      AppColors.of(context).gold,
    ];
    final sorte = math.Random(7);
    final quantas = widget.tamanho == TamanhoDaCelebracao.grande
        ? LucenaMotion.confeteGrande
        : LucenaMotion.confetePequeno;
    final atraso =
        LucenaMotion.atrasoDoConfete.inMicroseconds / _total.inMicroseconds;
    return [
      for (var i = 0; i < quantas; i++)
        ParticulaDoConfete(
          x: sorte.nextDouble(),
          deriva: (sorte.nextDouble() - .5) * .2,
          inicio: atraso * i / quantas,
          giro: sorte.nextDouble() * 4 * math.pi,
          cor: cores[i % cores.length],
        ),
    ];
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diploma = widget.diploma;
    Widget escalado(Widget filho) => FadeTransition(
      key: MotionKeys.fadeDaCelebracao,
      opacity: _reduzido ? _controle : kAlwaysCompleteAnimation,
      child: AnimatedBuilder(
        animation: _controle,
        child: filho,
        builder: (context, filho) => Transform.scale(
          key: MotionKeys.diplomaDaCelebracao,
          scale: _reduzido ? 1 : _escala.transform(_fracaoDoDiploma),
          child: filho,
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        diploma == null ? escalado(widget.child) : widget.child,
        if (diploma != null)
          Positioned.fill(child: Center(child: escalado(diploma))),
        if (!_reduzido)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controle,
                builder: (context, _) => _controle.isCompleted
                    ? const SizedBox.shrink()
                    : CustomPaint(
                        key: MotionKeys.confeteDaCelebracao,
                        painter: PintorDoConfete(
                          particulas: _particulas,
                          tempo: _controle.value,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  double get _fracaoDoDiploma =>
      (_controle.value *
              _total.inMicroseconds /
              LucenaMotion.diplomaDaCelebracao.inMicroseconds)
          .clamp(0.0, 1.0);
}

/// Uma partícula: posição de saída ([x], 0 a 1), deriva lateral, instante de
/// saída ([inicio], fração do tempo total) e giro.
class ParticulaDoConfete {
  const ParticulaDoConfete({
    required this.x,
    required this.deriva,
    required this.inicio,
    required this.giro,
    required this.cor,
  });

  final double x;
  final double deriva;
  final double inicio;
  final double giro;
  final Color cor;
}

/// Pinta o confete no [tempo] (0 a 1 da celebração inteira).
class PintorDoConfete extends CustomPainter {
  const PintorDoConfete({required this.particulas, required this.tempo});

  final List<ParticulaDoConfete> particulas;
  final double tempo;

  @override
  void paint(Canvas canvas, Size size) {
    final queda = 1 - particulas.fold(0.0, (m, p) => math.max(m, p.inicio));
    final pincel = Paint();
    for (final p in particulas) {
      final t = ((tempo - p.inicio) / queda).clamp(0.0, 1.0);
      if (t == 0 || t == 1) continue;
      final y = -12 + (size.height + 24) * Curves.easeIn.transform(t);
      final x = (p.x + p.deriva * t) * size.width;
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.giro * t);
      pincel.color = p.cor.withValues(alpha: t < .8 ? 1 : (1 - t) / .2);
      canvas
        ..drawRect(const Rect.fromLTWH(-3, -5, 6, 10), pincel)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(PintorDoConfete antigo) =>
      antigo.tempo != tempo || antigo.particulas != particulas;
}
