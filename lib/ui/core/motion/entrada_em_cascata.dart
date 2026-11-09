import 'package:flutter/widgets.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

/// O papel de cada item na [EntradaEmCascata], que dá o tempo e o movimento.
enum TipoNaCascata { titulo, texto, numero, selo, botao }

/// Um item da [EntradaEmCascata].
class ItemDaCascata {
  /// Sobe 14 px em 380 ms.
  const ItemDaCascata.titulo(this.child) : tipo = TipoNaCascata.titulo;

  /// Subtítulo, parágrafo ou linha de lista: sobe 10 px em 320 ms.
  const ItemDaCascata.texto(this.child) : tipo = TipoNaCascata.texto;

  /// Número grande ([NumeroQueConta]): entra como o texto e conta em 620 ms.
  const ItemDaCascata.numero(this.child) : tipo = TipoNaCascata.numero;

  /// Emblema ou selo: escala de 0,6 a 1.
  const ItemDaCascata.selo(this.child) : tipo = TipoNaCascata.selo;

  /// O botão principal, sempre o último.
  const ItemDaCascata.botao(this.child) : tipo = TipoNaCascata.botao;

  final TipoNaCascata tipo;
  final Widget child;
}

/// Quando um item entra e quanto demora.
typedef HorarioDaEntrada = ({Duration inicio, Duration duracao});

/// O texto que explica entra em cascata (H-ANI-16, padrão da venda 01b).
///
/// Os itens entram na ordem da lista (título; subtítulo e parágrafos;
/// listas; números contando; selos; o botão por último), com até 70 ms entre
/// eles. Com muitos itens o intervalo encolhe, para o botão chegar em até
/// 1,2 s. Curva `emphasizedDecelerate`.
///
/// Só na primeira entrada da tela ([EntradaDaTela]); o toque fica liberado
/// desde o início. Com movimento reduzido, tudo aparece no lugar, sem
/// contagem.
class EntradaEmCascata extends StatelessWidget {
  const EntradaEmCascata({
    required this.itens,
    this.montar = _coluna,
    this.animar,
    super.key,
  });

  final List<ItemDaCascata> itens;

  /// Arruma os itens já animados (padrão: coluna alinhada ao início).
  final Widget Function(List<Widget> itens) montar;

  /// Nulo: só na primeira entrada da tela.
  final bool? animar;

  // B1: callback de montar (valor padrão const do parâmetro)
  static Widget _coluna(List<Widget> itens) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: itens,
  );

  static Duration _duracao(TipoNaCascata tipo) => switch (tipo) {
    TipoNaCascata.titulo => LucenaMotion.tituloEntra,
    _ => LucenaMotion.textoEntra,
  };

  /// O horário de cada item, na ordem dada.
  static List<HorarioDaEntrada> horarios(List<TipoNaCascata> tipos) {
    if (tipos.isEmpty) return const [];
    var intervalo = LucenaMotion.intervaloDaCascata;
    if (tipos.length > 1) {
      final cabe =
          (LucenaMotion.totalDaCascata - _duracao(tipos.last)) ~/
          (tipos.length - 1);
      if (cabe < intervalo) intervalo = cabe;
    }
    return [
      for (var i = 0; i < tipos.length; i++)
        (inicio: intervalo * i, duracao: _duracao(tipos[i])),
    ];
  }

  /// O fim da cascata, contando os números.
  static Duration total(List<TipoNaCascata> tipos) {
    final todos = horarios(tipos);
    var fim = Duration.zero;
    for (var i = 0; i < todos.length; i++) {
      final (:inicio, :duracao) = todos[i];
      final conta = tipos[i] == TipoNaCascata.numero
          ? LucenaMotion.numeroDaCascata
          : duracao;
      for (final d in [duracao, conta]) {
        if (inicio + d > fim) fim = inicio + d;
      }
    }
    return fim;
  }

  @override
  Widget build(BuildContext context) {
    final tipos = [for (final item in itens) item.tipo];
    final todos = horarios(tipos);
    return RelogioDeEntrada(
      total: total(tipos),
      animar: animar,
      child: montar([
        for (var i = 0; i < itens.length; i++)
          EntradaNoTempo(
            key: MotionKeys.itemDaCascata(i),
            inicio: todos[i].inicio,
            duracao: todos[i].duracao,
            subida: switch (tipos[i]) {
              TipoNaCascata.titulo => LucenaMotion.subidaDoTitulo,
              _ => LucenaMotion.subidaDoTexto,
            },
            escalaDe: tipos[i] == TipoNaCascata.selo
                ? LucenaMotion.escalaDoEmblema
                : 1,
            duracaoDaContagem: tipos[i] == TipoNaCascata.numero
                ? LucenaMotion.numeroDaCascata
                : null,
            child: itens[i].child,
          ),
      ]),
    );
  }
}
