import 'package:flutter/widgets.dart';

/// As telas que já fizeram a entrada nesta sessão (H-ANI-01): "só na primeira
/// entrada" quer dizer uma vez por tela. Voltar, trocar de aba ou rolar não
/// repete. O registro vive com o app (um por sessão) e chega às telas por
/// [EntradasVistasEscopo]; nunca é global estático.
class EntradasVistas {
  final Set<String> _vistas = {};

  /// `true` na primeira vez que a tela [id] pede, e a marca como vista.
  bool primeiraVez(String id) => _vistas.add(id);
}

/// Entrega o [EntradasVistas] da sessão às telas abaixo.
class EntradasVistasEscopo extends InheritedWidget {
  const EntradasVistasEscopo({
    required this.vistas,
    required super.child,
    super.key,
  });

  final EntradasVistas vistas;

  /// O registro da sessão, ou nulo sem escopo em volta (teste de widget
  /// solto): aí toda entrada conta como a primeira.
  static EntradasVistas? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EntradasVistasEscopo>()?.vistas;

  @override
  bool updateShouldNotify(EntradasVistasEscopo oldWidget) =>
      !identical(vistas, oldWidget.vistas);
}

/// Marca uma tela (pelo id do quadro do canvas, como `PropV1TreinoCatalogo`)
/// e decide uma vez, ao montar, se esta é a primeira entrada dela na sessão.
/// Todos os widgets de movimento abaixo leem o mesmo valor por
/// [EntradaDaTela.primeira], para a barra e o número da mesma tela entrarem
/// juntos.
class EntradaDaTela extends StatefulWidget {
  const EntradaDaTela({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  /// `true` na primeira entrada da tela em volta, ou sem tela em volta.
  static bool primeira(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PrimeiraEntrada>()
          ?.primeira ??
      true;

  @override
  State<EntradaDaTela> createState() => _EntradaDaTelaState();
}

class _EntradaDaTelaState extends State<EntradaDaTela> {
  bool? _primeira;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _primeira ??=
        EntradasVistasEscopo.maybeOf(context)?.primeiraVez(widget.id) ?? true;
  }

  @override
  Widget build(BuildContext context) =>
      _PrimeiraEntrada(primeira: _primeira!, child: widget.child);
}

class _PrimeiraEntrada extends InheritedWidget {
  const _PrimeiraEntrada({required this.primeira, required super.child});

  final bool primeira;

  @override
  bool updateShouldNotify(_PrimeiraEntrada oldWidget) =>
      primeira != oldWidget.primeira;
}
