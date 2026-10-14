import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// A troca de fala dentro do balão (Gabriel, 14/10/2026; canvas
/// `T70-etapa1-estados`, E7d): o balão fica no lugar, a fala antiga sai e a
/// nova entra em crossfade, e a altura muda animada, então o que está embaixo
/// acompanha sem pulo. Com "remover animações", a troca é seca.
///
/// Fica em volta só do texto: o balão em volta cresce junto com ele.
class AnimatedSpeechSwitcher extends StatelessWidget {
  const AnimatedSpeechSwitcher({
    required this.speech,
    required this.child,
    super.key,
  });

  /// O que identifica a fala: quando muda, é fala nova (crossfade).
  final Object speech;

  final Widget child;

  /// O crossfade do texto e a mudança de altura.
  static const fade = AppMotion.state;
  static const resize = AppMotion.panel;

  @override
  Widget build(BuildContext context) {
    final keyed = KeyedSubtree(key: ValueKey(speech), child: child);
    // Sem animação, troca seca (o AnimatedSize de duração zero não aguenta).
    if (AppMotion.reduced(context)) return keyed;
    return AnimatedSize(
      duration: resize,
      curve: AppMotion.resize,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: fade,
        // A altura é a da fala nova; a antiga sai por cima, cortada.
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            for (final old in previous)
              PositionedDirectional(top: 0, start: 0, end: 0, child: old),
            ?current,
          ],
        ),
        child: keyed,
      ),
    );
  }
}

/// A primeira aparição do balão: um pop leve (escala 0,95 → 1 com fade), a
/// partir da ponta do bico (canvas `T70-etapa1-estados`, E1a). Só ao entrar na
/// tela; a troca de fala é o [AnimatedSpeechSwitcher].
class SpeechPop extends StatelessWidget {
  const SpeechPop({
    required this.child,
    this.alignment = AlignmentDirectional.bottomStart,
    super.key,
  });

  /// De onde o balão cresce: a ponta que aponta para quem fala.
  final AlignmentGeometry alignment;

  final Widget child;

  static const duration = AppMotion.state;
  static const scale = 0.95;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.of(context).disabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: AppMotion.enter,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(
          scale: scale + (1 - scale) * t,
          alignment: alignment,
          child: child,
        ),
      ),
      child: child,
    );
  }
}
