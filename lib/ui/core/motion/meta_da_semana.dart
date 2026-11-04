import 'package:flutter/material.dart';

import 'entradas_vistas.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// A meta do dia na Sequência (H-ANI-28), sem bloco novo na tela: quando
/// hoje está [cumprida], os ✓ dos dias anteriores saem em onda, o anel de
/// hoje fecha em 450 ms, o ✓ de hoje salta e o contador sobe com um salto.
/// Tudo em 1,2 s, só na primeira entrada da tela na sessão.
///
/// Um relógio só para a tela: os pedaços leem o [TempoDaMeta] de
/// [MetaDaSemana.of]. Sem festa (meta não cumprida, tela já vista, movimento
/// reduzido ou fora de uma [MetaDaSemana]), o tempo fica no fim.
class MetaDaSemana extends StatefulWidget {
  const MetaDaSemana({
    required this.cumprida,
    required this.child,
    this.animar,
    super.key,
  });

  final bool cumprida;
  final Widget child;

  /// Força animar ou não; nulo segue a primeira entrada da tela.
  final bool? animar;

  /// O tempo da festa em volta, ou o fim sem festa.
  static TempoDaMeta of(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<_EscopoDaMeta>();
    return TempoDaMeta(escopo?.valor ?? 1, festa: escopo?.festa ?? false);
  }

  @override
  State<MetaDaSemana> createState() => _MetaDaSemanaState();
}

class _MetaDaSemanaState extends State<MetaDaSemana>
    with SingleTickerProviderStateMixin {
  late final _controle = AnimationController(
    vsync: this,
    duration: LucenaMotion.celebracaoDaMeta,
    value: 1,
  )..addListener(() => setState(() {}));
  var _iniciado = false;
  var _celebrou = false;
  late bool _pode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _pode =
        widget.animar ??
        (EntradaDaTela.primeira(context) && !MovimentoReduzido.of(context));
    _talvez();
  }

  @override
  void didUpdateWidget(MetaDaSemana antigo) {
    super.didUpdateWidget(antigo);
    if (!antigo.cumprida) _talvez();
  }

  void _talvez() {
    if (!widget.cumprida || _celebrou || !_pode) return;
    _celebrou = true;
    _controle.forward(from: 0);
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EscopoDaMeta(
    valor: _controle.value,
    festa: _celebrou,
    child: widget.child,
  );
}

class _EscopoDaMeta extends InheritedWidget {
  const _EscopoDaMeta({
    required this.valor,
    required this.festa,
    required super.child,
  });

  final double valor;
  final bool festa;

  @override
  bool updateShouldNotify(_EscopoDaMeta antigo) =>
      antigo.valor != valor || antigo.festa != festa;
}

/// O instante da festa da meta ([valor], de 0 a 1 em 1,2 s) e o que cada
/// pedaço mostra nele.
class TempoDaMeta {
  const TempoDaMeta(this.valor, {this.festa = false});

  final double valor;

  /// A tela comemorou hoje (está comemorando ou já acabou).
  final bool festa;

  Duration get _agora => LucenaMotion.celebracaoDaMeta * valor;

  static double _trecho(Duration agora, Duration inicio, Duration duracao) =>
      ((agora - inicio).inMicroseconds / duracao.inMicroseconds).clamp(
        0.0,
        1.0,
      );

  /// O tempo linear do anel de hoje (0 a 1), para o [PintorDoAnel].
  double get anel => _trecho(_agora, Duration.zero, LucenaMotion.anelDaMeta);

  /// A escala do ✓ de hoje: salta quando o anel fecha.
  double get checkDeHoje => LucenaMotion.salto.transform(
    _trecho(_agora, LucenaMotion.anelDaMeta, LucenaMotion.saltoDaMeta),
  );

  /// A escala do ✓ do [i]-ésimo dia anterior da sequência, em onda.
  double checkAnterior(int i) => LucenaMotion.salto.transform(
    _trecho(
      _agora,
      LucenaMotion.intervaloDosFeitos * i,
      LucenaMotion.saltoDaMeta,
    ),
  );

  /// O contador ainda mostra o valor de ontem.
  bool get contadorAntes => _agora < LucenaMotion.contadorDaMeta;

  /// A escala do contador no salto, depois de [LucenaMotion.contadorDaMeta].
  double get contador => LucenaMotion.salto.transform(
    _trecho(_agora, LucenaMotion.contadorDaMeta, LucenaMotion.saltoDaMeta),
  );
}
