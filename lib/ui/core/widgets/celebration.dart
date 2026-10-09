import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Uma chuva curta de confete, uma vez, para os grandes momentos (degrau
/// concluído, formatura, recorde). Não pega toques. Com "remover animações",
/// não aparece.
class Celebration extends StatefulWidget {
  const Celebration({this.pieces = 40, super.key});

  final int pieces;

  static const duration = Duration(milliseconds: 1600);

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Celebration.duration,
  );

  // Cada pedaço: de onde sai, para onde vai, quanto gira e a cor.
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    // Sempre os mesmos pedaços: a festa não depende de sorteio.
    final random = math.Random(7);
    _pieces = [
      for (var i = 0; i < widget.pieces; i++)
        _Piece(
          x: random.nextDouble(),
          drift: (random.nextDouble() - 0.5) * 0.4,
          delay: random.nextDouble() * 0.25,
          spin: (random.nextDouble() - 0.5) * 12,
          size: 6 + random.nextDouble() * 6,
          hue: random.nextInt(4),
        ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppMotion.of(context).disabled && _controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.of(context).disabled) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final palette = [
      colors.primary,
      colors.tertiary,
      const Color(0xFFFFC107),
      colors.secondary,
    ];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _controller.isCompleted
            ? const SizedBox.shrink()
            : CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_pieces, _controller.value, palette),
              ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.drift,
    required this.delay,
    required this.spin,
    required this.size,
    required this.hue,
  });

  final double x;
  final double drift;
  final double delay;
  final double spin;
  final double size;
  final int hue;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress, this.palette);

  final List<_Piece> pieces;
  final double progress;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final t = ((progress - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final x = (piece.x + piece.drift * t) * size.width;
      // Cai acelerando, do alto até um pouco além do meio.
      final y = -20 + t * t * size.height * 0.8;
      final paint = Paint()
        ..color = palette[piece.hue % palette.length].withValues(
          alpha: 1 - t * 0.8,
        );
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(piece.spin * t)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.5,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
