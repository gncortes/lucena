import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

/// A compra concluída (H-ANI-27, clipe 09): o círculo com ✓ escala de 0,6 a
/// 1 em 380 ms (DEC) e o ✓ salta (0 → 1,18 → 1); um anel vai a 1,7 e some em
/// 700 ms, uma vez; o [titulo] e o [texto] sobem 14 px em 300 ms; os [itens]
/// entram como a lista da venda (H-ANI-16: sobem 10 px em 320 ms, 70 ms entre
/// eles) e os [botoes] entram por último, 100 ms entre eles.
///
/// Ocupa a tela: o círculo verde-claro com ✓ verde, o título e o texto no
/// centro, e os [botoes] presos embaixo (canvas `PropV2CompraConcluida`).
///
/// Anima sempre que aparece. Com movimento reduzido, pronto e sem anel.
class SucessoDaCompra extends StatelessWidget {
  const SucessoDaCompra({
    required this.titulo,
    required this.texto,
    required this.botoes,
    this.itens = const [],
    this.tamanho = 88,
    this.icone = Icons.check_rounded,
    this.fundo = AppColors.successSurface,
    this.cor = AppColors.successOnSurface,
    super.key,
  });

  final Widget titulo;
  final Widget texto;
  final List<Widget> botoes;

  /// Linhas abaixo do [texto] (o que o curso traz), em cascata.
  final List<Widget> itens;

  /// O diâmetro do círculo.
  final double tamanho;

  /// O ícone no círculo, o [fundo] do círculo e a [cor] do ícone e do anel:
  /// o ✓ verde da compra; o presente azul no Curso liberado (H-R5-62).
  final IconData icone;
  final Color fundo;
  final Color cor;

  static Duration _inicioDoItem(int i) =>
      LucenaMotion.textoDaCompra + LucenaMotion.intervaloDaCascata * (i + 2);

  Duration _inicioDoBotao(int i) {
    final depoisDosItens = itens.isEmpty
        ? Duration.zero
        : _inicioDoItem(itens.length - 1) + LucenaMotion.intervaloDosBotoes;
    final primeiro = depoisDosItens > LucenaMotion.botoesDaCompra
        ? depoisDosItens
        : LucenaMotion.botoesDaCompra;
    return primeiro + LucenaMotion.intervaloDosBotoes * i;
  }

  static final _check = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: LucenaMotion.picoDoCheck,
      ).chain(CurveTween(curve: LucenaMotion.emphasizedDecelerate)),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: LucenaMotion.picoDoCheck,
        end: 1.0,
      ).chain(CurveTween(curve: LucenaMotion.emphasized)),
      weight: 40,
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final ultimo = botoes.isEmpty
        ? (itens.isEmpty
                  ? LucenaMotion.textoDaCompra
                  : _inicioDoItem(itens.length - 1)) +
              LucenaMotion.textoEntra
        : _inicioDoBotao(botoes.length - 1) + LucenaMotion.sobeDaCompra;
    final total = ultimo > LucenaMotion.anelDaCompra
        ? ultimo
        : LucenaMotion.anelDaCompra;
    return RelogioDeEntrada(
      total: total,
      animar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: _Corpo(this),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                for (final (i, botao) in botoes.indexed)
                  EntradaNoTempo(
                    inicio: _inicioDoBotao(i),
                    duracao: LucenaMotion.sobeDaCompra,
                    subida: LucenaMotion.subidaDoTexto,
                    child: botao,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O corpo da tela: o círculo com ✓, o título, o texto e os itens.
class _Corpo extends StatelessWidget {
  const _Corpo(this.owner);

  final SucessoDaCompra owner;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // O anel cresce para fora do círculo sem reservar espaço: a lista do
        // Curso liberado cabe em 360×740.
        SizedBox.square(
          dimension: owner.tamanho,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              NoTempo(
                inicio: Duration.zero,
                duracao: LucenaMotion.anelDaCompra,
                curva: LucenaMotion.linear,
                builder: (context, v, _) => v >= 1
                    ? const SizedBox.shrink()
                    : Opacity(
                        key: MotionKeys.anelDaCompra,
                        opacity: 1 - v,
                        child: Transform.scale(
                          scale:
                              1 +
                              (LucenaMotion.escalaDoAnel - 1) *
                                  LucenaMotion.emphasizedDecelerate.transform(
                                    v,
                                  ),
                          child: Container(
                            width: owner.tamanho,
                            height: owner.tamanho,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: owner.cor, width: 2),
                            ),
                          ),
                        ),
                      ),
              ),
              NoTempo(
                inicio: Duration.zero,
                duracao: LucenaMotion.circuloDaCompra,
                builder: (context, v, filho) => Transform.scale(
                  key: MotionKeys.circuloDaCompra,
                  scale:
                      LucenaMotion.escalaDoCirculo +
                      (1 - LucenaMotion.escalaDoCirculo) * v,
                  child: filho,
                ),
                child: Container(
                  width: owner.tamanho,
                  height: owner.tamanho,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: owner.fundo,
                  ),
                  alignment: Alignment.center,
                  child: NoTempo(
                    inicio: Duration.zero,
                    duracao: LucenaMotion.circuloDaCompra,
                    curva: LucenaMotion.linear,
                    builder: (context, v, filho) => Transform.scale(
                      key: MotionKeys.checkDaCompra,
                      scale: SucessoDaCompra._check.transform(v),
                      child: filho,
                    ),
                    child: Icon(
                      owner.icone,
                      color: owner.cor,
                      size: owner.tamanho * .58,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        EntradaNoTempo(
          inicio: LucenaMotion.tituloDaCompra,
          duracao: LucenaMotion.sobeDaCompra,
          subida: LucenaMotion.subidaDoTitulo,
          child: owner.titulo,
        ),
        const SizedBox(height: AppSpacing.sm),
        EntradaNoTempo(
          inicio: LucenaMotion.textoDaCompra,
          duracao: LucenaMotion.sobeDaCompra,
          subida: LucenaMotion.subidaDoTitulo,
          child: owner.texto,
        ),
        for (final (i, item) in owner.itens.indexed) ...[
          SizedBox(height: i == 0 ? AppSpacing.lg : AppSpacing.sm),
          EntradaNoTempo(
            inicio: SucessoDaCompra._inicioDoItem(i),
            duracao: LucenaMotion.textoEntra,
            subida: LucenaMotion.subidaDoTexto,
            alinhamento: AlignmentDirectional.centerStart,
            child: item,
          ),
        ],
      ],
    );
  }
}
