import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../l10n/l10n.dart';
import 'cartao_pressionavel.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';
import 'relogio_de_entrada.dart';

/// "Conhecer o Pilares" no anúncio (H-ANI-31): entra vindo 12 px da direita
/// em 320 ms (DEC), com fade, e afunda a 0,94 em 220 ms no toque. O botão (e
/// o toque) é o [child]. Com movimento reduzido, no lugar e sem afundar.
class ConhecerQueEntra extends StatelessWidget {
  const ConhecerQueEntra({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => RelogioDeEntrada(
    total: LucenaMotion.entradaDoAnuncio,
    animar: true,
    child: NoTempo(
      inicio: Duration.zero,
      duracao: LucenaMotion.entradaDoAnuncio,
      builder: (context, v, filho) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(LucenaMotion.deslizeDoAnuncio * (1 - v), 0),
          child: filho,
        ),
      ),
      child: KeyedSubtree(
        key: MotionKeys.conhecerDoAnuncio,
        child: CartaoPressionavel(
          escala: LucenaMotion.apertoDoAnuncio,
          afunda: LucenaMotion.afundaDoAnuncio,
          volta: LucenaMotion.afundaDoAnuncio,
          child: child,
        ),
      ),
    ),
  );
}

/// A contagem para fechar o anúncio (H-ANI-31): "Fechar em 3" aparece com
/// fade de 250 ms e cada troca (3 → 2 → 1 → "Fechar") cruza em 200 ms. O
/// toque só fecha quando [restantes] chega a 0.
///
/// A contagem em si (o [Now], a pausa em segundo plano) é da tela; aqui só o
/// texto. Com movimento reduzido, troca seca e a contagem segue.
class ContagemParaFechar extends StatefulWidget {
  const ContagemParaFechar({
    required this.restantes,
    required this.aoFechar,
    this.estilo,
    super.key,
  });

  final int restantes;
  final VoidCallback aoFechar;
  final TextStyle? estilo;

  @override
  State<ContagemParaFechar> createState() => _ContagemParaFecharState();
}

class _ContagemParaFecharState extends State<ContagemParaFechar>
    with SingleTickerProviderStateMixin {
  late final _aparece = AnimationController(
    vsync: this,
    duration: LucenaMotion.contagemAparece,
  );
  var _comecou = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_comecou) return;
    _comecou = true;
    if (MovimentoReduzido.of(context)) {
      _aparece.value = 1;
    } else {
      _aparece.forward();
    }
  }

  @override
  void dispose() {
    _aparece.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduzido = MovimentoReduzido.of(context);
    final pronto = widget.restantes <= 0;
    final texto = pronto
        ? l10n.licaoAdClose
        : l10n.licaoAdCloseIn(widget.restantes);
    return Semantics(
      button: true,
      enabled: pronto,
      child: GestureDetector(
        key: MotionKeys.contagemParaFechar,
        behavior: HitTestBehavior.opaque,
        onTap: pronto ? widget.aoFechar : null,
        child: FadeTransition(
          opacity: _aparece,
          child: AnimatedSwitcher(
            duration: reduzido ? Duration.zero : LucenaMotion.trocaDaContagem,
            layoutBuilder: (atual, anteriores) => Stack(
              alignment: Alignment.center,
              children: [...anteriores, ?atual],
            ),
            child: Text(texto, key: ValueKey(texto), style: widget.estilo),
          ),
        ),
      ),
    );
  }
}
