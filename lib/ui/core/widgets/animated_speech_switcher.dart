import 'package:flutter/material.dart';

import '../motion/lucena_motion.dart';
import '../motion/movimento_reduzido.dart';
import '../theme/app_motion.dart';

/// A troca de fala dentro do balão (Gabriel, 14/10/2026; canvas
/// `T70-etapa1-estados`, E7d): o balão fica no lugar, a fala antiga sai e a
/// nova entra em crossfade, e a altura muda animada, então o que está embaixo
/// acompanha sem pulo (H-ANI-09: a antiga sai em 90 ms, `emphasizedAccelerate`;
/// a nova entra em 210 ms, `emphasizedDecelerate`). Com "remover animações",
/// a troca é um fade de 100 ms, sem a altura animada.
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

  /// A fala nova entra; a antiga sai em [saida].
  static const fade = LucenaMotion.falaEntra;
  static const saida = LucenaMotion.falaSai;

  /// A mudança de altura.
  static const resize = AppMotion.panel;

  static Widget _pilha(Widget? current, List<Widget> previous) => Stack(
    alignment: AlignmentDirectional.topStart,
    clipBehavior: Clip.none,
    children: [
      for (final old in previous)
        PositionedDirectional(top: 0, start: 0, end: 0, child: old),
      ?current,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final keyed = KeyedSubtree(key: ValueKey(speech), child: child);
    // Sem animação, só o fade curto, sem a altura animada (o AnimatedSize
    // de duração zero não aguenta).
    if (MovimentoReduzido.of(context)) {
      return AnimatedSwitcher(
        duration: LucenaMotion.fadeReduzido,
        layoutBuilder: _pilha,
        child: keyed,
      );
    }
    // O corte vai na borda que anima (o AnimatedSize só corta o filho maior
    // que ele, e o filho já tem a altura da fala nova).
    return ClipRect(
      child: AnimatedSize(
        duration: resize,
        curve: AppMotion.resize,
        alignment: AlignmentDirectional.topStart,
        child: AnimatedSwitcher(
          duration: fade,
          reverseDuration: saida,
          switchInCurve: LucenaMotion.emphasizedDecelerate,
          switchOutCurve: LucenaMotion.emphasizedAccelerate,
          // A altura é a da fala nova; a antiga sai por cima e é cortada
          // aos poucos, na borda do balão que encolhe.
          layoutBuilder: _pilha,
          child: keyed,
        ),
      ),
    );
  }
}

/// A primeira aparição do balão (H-ANI-09): fade, escala de 0,92 a 1 a
/// partir da ponta do bico e subida de 8 px, em 280 ms
/// (`emphasizedDecelerate`). Só ao entrar na tela; a troca de fala é o
/// [AnimatedSpeechSwitcher]. Com movimento reduzido, só um fade de 100 ms.
class SpeechPop extends StatelessWidget {
  const SpeechPop({
    required this.child,
    this.alignment = AlignmentDirectional.bottomStart,
    super.key,
  });

  /// De onde o balão cresce: a ponta que aponta para quem fala.
  final AlignmentGeometry alignment;

  final Widget child;

  static const duration = LucenaMotion.balaoEntra;
  static const scale = LucenaMotion.escalaDoBalao;

  @override
  Widget build(BuildContext context) {
    final reduzir = MovimentoReduzido.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduzir ? LucenaMotion.fadeReduzido : duration,
      curve: reduzir ? LucenaMotion.linear : LucenaMotion.emphasizedDecelerate,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: reduzir
            ? child
            : Transform.translate(
                offset: Offset(0, LucenaMotion.subidaDoBalao * (1 - t)),
                child: Transform.scale(
                  scale: scale + (1 - scale) * t,
                  alignment: alignment,
                  child: child,
                ),
              ),
      ),
      child: child,
    );
  }
}
