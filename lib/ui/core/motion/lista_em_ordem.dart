import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

// B1: callback de montar (valor padrão const do parâmetro)
Widget _coluna(List<Widget> itens) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: itens,
);

/// Lista ou grade que entra em ordem estrita, de cima para baixo (H-ANI-17):
/// cada linha faz fade e sobe 10 px em 300 ms (`emphasizedDecelerate`).
///
/// - **Lista longa** ([ListaEmOrdem.new]): 30 ms entre linhas; da 12ª em
///   diante o intervalo para de somar.
/// - **Feitos e checks** ([ListaEmOrdem.feitos]): 90 ms fixos entre itens.
///
/// O que nasce abaixo da dobra entra pronto. Só na primeira carga da tela
/// ([EntradaDaTela]): filtrar, trocar de aba ou voltar mostra a lista
/// pronta. Com movimento reduzido, tudo no lugar.
class ListaEmOrdem extends StatelessWidget {
  const ListaEmOrdem({
    required this.itens,
    this.montar = _coluna,
    this.animar,
    super.key,
  }) : _feitos = false;

  const ListaEmOrdem.feitos({
    required this.itens,
    this.montar = _coluna,
    this.animar,
    super.key,
  }) : _feitos = true;

  final List<Widget> itens;

  /// Arruma as linhas já animadas (coluna, `Wrap`, `GridView`...).
  final Widget Function(List<Widget> itens) montar;

  /// Nulo: só na primeira entrada da tela.
  final bool? animar;

  final bool _feitos;

  /// Quando a linha [i] começa a entrar.
  static Duration inicio(int i, {bool feitos = false}) => feitos
      ? LucenaMotion.intervaloDosFeitos * i
      : LucenaMotion.intervaloDaLista *
            (i < LucenaMotion.linhasQueEsperam
                ? i
                : LucenaMotion.linhasQueEsperam);

  @override
  Widget build(BuildContext context) {
    final ultimo = itens.isEmpty ? 0 : itens.length - 1;
    return RelogioDeEntrada(
      total: inicio(ultimo, feitos: _feitos) + LucenaMotion.itemDaLista,
      animar: animar,
      child: montar([
        for (var i = 0; i < itens.length; i++)
          EntradaNoTempo(
            key: MotionKeys.itemDaLista(i),
            inicio: inicio(i, feitos: _feitos),
            duracao: LucenaMotion.itemDaLista,
            subida: LucenaMotion.subidaDoTexto,
            prontoForaDaTela: true,
            child: itens[i],
          ),
      ]),
    );
  }
}

/// Passos numerados ligados por linha (H-ANI-17, "Como o curso funciona"):
/// o passo entra em 300 ms, o conector desce do topo em 240 ms, e só então
/// vem o passo seguinte. Com muitos passos, todos os tempos encolhem na
/// mesma proporção para caber em 2 s.
///
/// Só na primeira entrada da tela. Com movimento reduzido, tudo no lugar e
/// o conector inteiro.
class PassosComConector extends StatelessWidget {
  const PassosComConector({
    required this.passos,
    this.conector,
    this.montar = _coluna,
    this.animar,
    super.key,
  });

  final List<Widget> passos;

  /// A linha entre dois passos; nulo, um traço vertical de 2 × 24 px na cor
  /// do contorno, alinhado ao início.
  final Widget? conector;

  /// Arruma passos e conectores, já intercalados.
  final Widget Function(List<Widget> partes) montar;

  /// Nulo: só na primeira entrada da tela.
  final bool? animar;

  /// A proporção dos tempos para [n] passos caberem em 2 s.
  static double _escala(int n) {
    if (n == 0) return 1;
    final cheio =
        LucenaMotion.passoEntra * n + LucenaMotion.conectorDesce * (n - 1);
    final limite = LucenaMotion.totalDosPassos;
    return cheio <= limite ? 1 : limite.inMicroseconds / cheio.inMicroseconds;
  }

  @override
  Widget build(BuildContext context) {
    final n = passos.length;
    final e = _escala(n);
    final passo = LucenaMotion.passoEntra * e;
    final desce = LucenaMotion.conectorDesce * e;
    final linha =
        conector ??
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 2,
            height: 24,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );
    return RelogioDeEntrada(
      total: n == 0 ? Duration.zero : passo * n + desce * (n - 1),
      animar: animar,
      child: montar([
        for (var i = 0; i < n; i++) ...[
          EntradaNoTempo(
            key: MotionKeys.passo(i),
            inicio: (passo + desce) * i,
            duracao: passo,
            subida: LucenaMotion.subidaDoTexto,
            child: passos[i],
          ),
          if (i < n - 1)
            _Conector(
              key: MotionKeys.conector(i),
              inicio: (passo + desce) * i + passo,
              duracao: desce,
              child: linha,
            ),
        ],
      ]),
    );
  }
}

class _Conector extends StatelessWidget {
  const _Conector({
    required this.inicio,
    required this.duracao,
    required this.child,
    super.key,
  });

  final Duration inicio;
  final Duration duracao;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!RelogioDeEntrada.animando(context)) return child;
    return NoTempo(
      inicio: inicio,
      duracao: duracao,
      builder: (context, t, linha) => Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.diagonal3Values(1, t, 1),
        child: linha,
      ),
      child: child,
    );
  }
}
