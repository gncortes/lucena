import 'dart:async';

import 'package:flutter/material.dart';

/// Um item de lista que entra em cascata: aparece subindo de leve, um pouco
/// depois do anterior ([index]). Com "remover animações" no sistema, já entra
/// pronto.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  /// O atraso entre um item e o seguinte, e o máximo de itens que esperam
  /// (os de baixo, fora da tela, não precisam esperar mais).
  static const step = Duration(milliseconds: 45);
  static const maxDelayed = 8;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final slot = widget.index.clamp(0, StaggeredEntrance.maxDelayed);
    _delay = Timer(StaggeredEntrance.step * slot, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
