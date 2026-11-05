import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../keys/motion_keys.dart';
import '../theme/app_shape.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O cartão de onde uma [RotaQueAbre] cresce (H-ANI-04 por rota). Enquanto a
/// tela aberta está à mostra, o cartão some do lugar, para não aparecer em
/// dobro; na volta, ele reaparece quando a tela termina de encolher.
///
/// O [id] liga o cartão à rota. O [child] é desenhado também dentro do
/// retângulo que cresce: não pode ter `GlobalKey`.
class OrigemQueAbre extends StatefulWidget {
  const OrigemQueAbre({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  State<OrigemQueAbre> createState() => _OrigemQueAbreState();
}

class _OrigemQueAbreState extends State<OrigemQueAbre> {
  /// Por id, as origens montadas na ordem em que entraram: vale a última. A
  /// mesma lição pode estar em duas telas empilhadas (catálogo e capítulo);
  /// fechar a de cima não apaga a de baixo.
  static final _origens = <String, List<_OrigemQueAbreState>>{};

  static _OrigemQueAbreState? daVez(String id) => _origens[id]?.lastOrNull;

  void _entra(String id) => (_origens[id] ??= []).add(this);

  void _sai(String id) {
    final lista = _origens[id];
    if (lista == null) return;
    lista.remove(this);
    if (lista.isEmpty) _origens.remove(id);
  }

  final _escondida = ValueNotifier(false);

  /// Falso entre sair da árvore e ser descartada (a folha que fecha).
  bool _ativa = true;

  @override
  void deactivate() {
    _ativa = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _ativa = true;
  }

  /// O retângulo do cartão na tela, ou nulo se ainda não tem tamanho.
  Rect? get retangulo {
    if (!mounted || !_ativa) return null;
    final caixa = context.findRenderObject();
    if (caixa is! RenderBox || !caixa.attached || !caixa.hasSize) return null;
    return caixa.localToGlobal(Offset.zero) & caixa.size;
  }

  @override
  void initState() {
    super.initState();
    _entra(widget.id);
  }

  @override
  void didUpdateWidget(OrigemQueAbre antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.id == widget.id) return;
    _sai(antigo.id);
    _entra(widget.id);
  }

  @override
  void dispose() {
    _sai(widget.id);
    _escondida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _escondida,
    builder: (context, escondida, filho) =>
        Opacity(opacity: escondida ? 0 : 1, child: filho),
    child: widget.child,
  );
}

/// A página do go_router que cresce do retângulo da [OrigemQueAbre] de mesmo
/// [id] até a tela inteira, e volta a ele no pop (H-ANI-04): a mesma curva e o
/// mesmo tempo do [CartaoQueAbre] (450 ms; com [venda], 560 ms e raio 21). O
/// cartão segue desenhado no retângulo e a tela aberta aparece por cima entre
/// 20% e 40% do tempo.
///
/// É o padrão para cartão que abre uma tela com rota; o `CartaoQueAbre` fica
/// para o que não é rota. Sem a origem na tela, a página entra só em fade. Com
/// movimento reduzido, fade de 100 ms, sem retângulo.
class RotaQueAbre<T> extends CustomTransitionPage<T> {
  RotaQueAbre({
    required BuildContext context,
    required String id,
    required Widget child,
    bool venda = false,
    LocalKey? key,
  }) : this._(
         id: id,
         venda: venda,
         reduzir: MovimentoReduzido.of(context),
         child: child,
         key: key,
       );

  RotaQueAbre._({
    required String id,
    required bool venda,
    required bool reduzir,
    required super.child,
    super.key,
  }) : super(
         transitionDuration: _duracao(venda: venda, reduzir: reduzir),
         reverseTransitionDuration: _duracao(venda: venda, reduzir: reduzir),
         transitionsBuilder: (context, animacao, _, tela) => reduzir
             ? FadeTransition(opacity: animacao, child: tela)
             : _Crescendo(
                 id: id,
                 raio: venda ? LucenaMotion.raioDaVenda : AppShape.large,
                 animacao: animacao,
                 child: tela,
               ),
       );

  static Duration _duracao({required bool venda, required bool reduzir}) =>
      reduzir
      ? LucenaMotion.fadeReduzido
      : venda
      ? LucenaMotion.cartaoDaVenda
      : LucenaMotion.cartaoAbre;
}

class _Crescendo extends StatefulWidget {
  const _Crescendo({
    required this.id,
    required this.raio,
    required this.animacao,
    required this.child,
  });

  final String id;
  final double raio;
  final Animation<double> animacao;
  final Widget child;

  @override
  State<_Crescendo> createState() => _CrescendoState();
}

class _CrescendoState extends State<_Crescendo> {
  /// A origem escondida por esta rota, para mostrar de novo ao sair.
  _OrigemQueAbreState? _origem;

  /// O último retângulo da origem: vale se ela sair da árvore no meio.
  Rect? _inicio;

  /// Ida com a curva; volta com ela invertida, como no container transform.
  late final _ida = CurvedAnimation(
    parent: widget.animacao,
    curve: LucenaMotion.curvaDoCartao,
    reverseCurve: LucenaMotion.curvaDoCartao.flipped,
  );

  late final _telaAberta = CurvedAnimation(
    parent: widget.animacao,
    curve: LucenaMotion.fadeDaTelaAberta,
  );

  @override
  void initState() {
    super.initState();
    widget.animacao.addStatusListener(_mudouOEstado);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mudouOEstado(widget.animacao.status);
    });
  }

  void _mudouOEstado(AnimationStatus estado) {
    final origem = _OrigemQueAbreState.daVez(widget.id);
    if (origem != _origem) _mostra();
    _origem = origem;
    origem?._escondida.value = !estado.isDismissed;
  }

  void _mostra() {
    final origem = _origem;
    if (origem != null && origem.mounted) origem._escondida.value = false;
  }

  @override
  void dispose() {
    widget.animacao.removeStatusListener(_mudouOEstado);
    _ida.dispose();
    _telaAberta.dispose();
    // No dispose a árvore está travada: se a origem sai no mesmo quadro
    // (go para o Início com a pilha inteira), ela ainda está montada, mas
    // inativa. Mostrar de novo fica para depois do quadro.
    final origem = _origem;
    if (origem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (origem.mounted) origem._escondida.value = false;
      });
    }
    super.dispose();
  }

  /// A árvore é a mesma do começo ao fim da abertura (só mudam os valores):
  /// a tela aberta não perde o estado quando a animação termina.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) => AnimatedBuilder(
      animation: widget.animacao,
      builder: (context, _) {
        final tela = limites.biggest;
        // A origem da abertura vale até ela sair da árvore (a folha que fecha):
        // depois fica o último retângulo, sem pular para outra de mesmo id.
        final presa = _origem;
        final origem = presa == null
            ? _OrigemQueAbreState.daVez(widget.id)
            : (presa.mounted && presa._ativa ? presa : null);
        final animando = !widget.animacao.isCompleted;
        if (animando) _inicio = origem?.retangulo ?? _inicio;
        final inicio = _inicio;
        final cresce = animando && inicio != null;
        final t = cresce ? _ida.value : 1.0;
        final quadro = cresce
            ? Rect.lerp(inicio, Offset.zero & tela, t)!
            : Offset.zero & tela;
        return Stack(
          children: [
            Positioned.fromRect(
              rect: quadro,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.raio * (1 - t)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cresce && origem != null)
                      IgnorePointer(
                        child: _Encaixa(
                          tamanho: inicio.size,
                          child: origem.widget.child,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    FadeTransition(
                      opacity: inicio == null ? widget.animacao : _telaAberta,
                      child: _Encaixa(tamanho: tela, child: widget.child),
                    ),
                  ],
                ),
              ),
            ),
            if (cresce)
              Positioned.fromRect(
                rect: quadro,
                child: const IgnorePointer(
                  child: SizedBox.expand(key: MotionKeys.rotaQueAbre),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// Desenha o [child] no [tamanho] dele, encaixado na largura do retângulo.
class _Encaixa extends StatelessWidget {
  const _Encaixa({required this.tamanho, required this.child});

  final Size tamanho;
  final Widget child;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.fitWidth,
    alignment: Alignment.topLeft,
    clipBehavior: Clip.hardEdge,
    child: SizedBox.fromSize(size: tamanho, child: child),
  );
}
