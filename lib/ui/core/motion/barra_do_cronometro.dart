import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../domain/use_cases/now.dart';
import '../keys/motion_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_shape.dart';
import 'lucena_motion.dart';

/// O tempo da teoria numa barra que esvazia (H-ANI-14, R3-42): linear, pelo
/// relógio ([now]), não por contagem de quadros; 3 s em segundo plano tiram
/// 3 s da barra. Nos últimos 20% do tempo, vai à [corDoFim].
///
/// Informação de tempo: esvazia também com movimento reduzido. A cascata do
/// conteúdo em volta é a `EntradaEmCascata` da tela.
class BarraDoCronometro extends StatefulWidget {
  const BarraDoCronometro({
    required this.inicio,
    required this.duracao,
    required this.now,
    this.pausadoEm,
    this.aoTerminar,
    this.cor,
    this.corDoFim,
    this.altura = 8,
    super.key,
  });

  /// Quando o tempo começou a contar (já descontadas as pausas).
  final DateTime inicio;
  final Duration duracao;
  final Now now;

  /// Com pausa, a barra fica parada neste instante.
  final DateTime? pausadoEm;
  final VoidCallback? aoTerminar;
  final Color? cor;

  /// Padrão: o ouro do tema.
  final Color? corDoFim;
  final double altura;

  @override
  State<BarraDoCronometro> createState() => _BarraDoCronometroState();
}

class _BarraDoCronometroState extends State<BarraDoCronometro>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => _atualizar());
  late double _passado = _medir();
  var _avisou = false;

  double _medir() {
    final agora = widget.pausadoEm ?? widget.now();
    final ms = agora.difference(widget.inicio).inMicroseconds;
    return (ms / widget.duracao.inMicroseconds).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _ligar();
  }

  @override
  void didUpdateWidget(BarraDoCronometro antigo) {
    super.didUpdateWidget(antigo);
    _passado = _medir();
    if (_passado < 1) _avisou = false;
    _ligar();
  }

  void _ligar() {
    final correr = widget.pausadoEm == null && _passado < 1;
    if (correr && !_ticker.isActive) _ticker.start();
    if (!correr && _ticker.isActive) _ticker.stop();
    if (_passado >= 1) _terminou();
  }

  void _atualizar() {
    final passado = _medir();
    if (passado != _passado) setState(() => _passado = passado);
    if (passado >= 1) {
      _ticker.stop();
      _terminou();
    }
  }

  void _terminou() {
    if (_avisou) return;
    _avisou = true;
    final aviso = widget.aoTerminar;
    if (aviso != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) aviso();
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.cor ?? Theme.of(context).colorScheme.primary;
    final corDoFim = widget.corDoFim ?? AppColors.of(context).gold;
    final fim =
        ((_passado - LucenaMotion.fimDoCronometro) /
                (1 - LucenaMotion.fimDoCronometro))
            .clamp(0.0, 1.0);
    return ClipRRect(
      key: MotionKeys.barraDoCronometro,
      borderRadius: BorderRadius.circular(AppShape.full),
      child: LinearProgressIndicator(
        value: 1 - _passado,
        minHeight: widget.altura,
        color: fim == 1 ? corDoFim : Color.lerp(cor, corDoFim, fim),
      ),
    );
  }
}
