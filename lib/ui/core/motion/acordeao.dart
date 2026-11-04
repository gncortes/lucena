import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_spacing.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O recolhível das Dúvidas e das listas (H-ANI-22): o corpo abre em 300 ms
/// (`emphasized`), empurrando o que está abaixo, com fade, e a seta gira
/// 180°. Anima sempre; com movimento reduzido, abre e fecha sem transição.
///
/// O toque no cabeçalho tem a ondulação do Material.
class Acordeao extends StatefulWidget {
  const Acordeao({
    required this.cabecalho,
    required this.child,
    this.inicialmenteAberto = false,
    this.aoTrocar,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
    super.key,
  });

  final Widget cabecalho;

  /// O conteúdo que abre.
  final Widget child;
  final bool inicialmenteAberto;

  /// Avisa o estado novo a cada toque no cabeçalho.
  final ValueChanged<bool>? aoTrocar;

  /// O respiro do cabeçalho.
  final EdgeInsetsGeometry padding;

  @override
  State<Acordeao> createState() => _AcordeaoState();
}

class _AcordeaoState extends State<Acordeao> {
  late bool _aberto = widget.inicialmenteAberto;

  void _trocar() {
    setState(() => _aberto = !_aberto);
    widget.aoTrocar?.call(_aberto);
  }

  @override
  Widget build(BuildContext context) {
    final duracao = MovimentoReduzido.of(context)
        ? Duration.zero
        : LucenaMotion.acordeao;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: MotionKeys.cabecalhoDoAcordeao,
          button: true,
          expanded: _aberto,
          child: InkWell(
            onTap: _trocar,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: widget.padding,
                child: Row(
                  children: [
                    Expanded(child: widget.cabecalho),
                    AnimatedRotation(
                      key: MotionKeys.setaDoAcordeao,
                      turns: _aberto ? .5 : 0,
                      duration: duracao,
                      curve: LucenaMotion.emphasized,
                      child: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(end: _aberto ? 1 : 0),
          duration: duracao,
          curve: LucenaMotion.emphasized,
          child: widget.child,
          builder: (context, t, filho) => ClipRect(
            key: MotionKeys.corpoDoAcordeao,
            child: t == 0
                ? const SizedBox(width: double.infinity)
                : Align(
                    alignment: Alignment.topCenter,
                    heightFactor: t,
                    child: Opacity(opacity: t, child: filho),
                  ),
          ),
        ),
      ],
    );
  }
}
