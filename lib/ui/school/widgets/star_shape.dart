import 'package:flutter/material.dart';

/// Uma estrela no tabuleiro, que cresce ao aparecer.
class StarShape extends StatelessWidget {
  const StarShape({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: const FittedBox(
        child: Icon(Icons.star_rounded, color: Color(0xfff2b705)),
      ),
    );
  }
}
