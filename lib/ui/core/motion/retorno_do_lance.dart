import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../keys/motion_keys.dart';
import '../theme/app_colors.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';
import 'selo_na_peca.dart';

/// Acerto ou erro do lance do aluno.
enum TipoDeRetorno { acerto, erro }

/// O sinal de acerto e de erro, igual em todo exercício (H-ANI-11): lição,
/// prática, "Vale aqui?", armadilha, treino por partes, Escola e Corrida.
/// Monte-o sobre o [TabuleiroAnimado] logo que a peça chega, com uma key nova
/// a cada tentativa.
///
/// A [casa] nunca muda de cor (Gabriel, 04/11): fica só o destaque de último
/// lance do tabuleiro, e o rei em xeque segue com o destaque do xeque.
///
/// - **Acerto:** o selo ✓ salta e o tabuleiro respira 1,5% (320 ms).
///   Vibração leve.
/// - **Erro:** o selo ✗ salta e o tabuleiro fica parado (sem tremida). Aos
///   1100 ms, [aoVoltar] devolve a peça à casa de origem. Vibração média.
///
/// Com movimento reduzido, o selo aparece parado, sem respiro. A vibração segue o ajuste do app ([vibrar]).
class RetornoDoLance extends StatefulWidget {
  const RetornoDoLance({
    required this.tipo,
    required this.casa,
    required this.orientacao,
    required this.tamanho,
    required this.vibrar,
    required this.child,
    this.aoVoltar,
    super.key,
  });

  final TipoDeRetorno tipo;

  /// A casa de destino do lance.
  final Square casa;
  final Side orientacao;

  /// Lado do tabuleiro.
  final double tamanho;

  /// A vibração ligada nos ajustes do app.
  final bool vibrar;

  /// O tabuleiro ([TabuleiroAnimado]).
  final Widget child;

  /// No erro, quando a peça deve voltar à casa de origem.
  final VoidCallback? aoVoltar;

  /// A escala do tabuleiro em [t] (0 a 1 dos 320 ms do respiro).
  static final respiro = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: LucenaMotion.escalaDoRespiro,
      ).chain(CurveTween(curve: LucenaMotion.emphasizedDecelerate)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: LucenaMotion.escalaDoRespiro,
        end: 1,
      ).chain(CurveTween(curve: LucenaMotion.emphasized)),
      weight: 50,
    ),
  ]);

  @override
  State<RetornoDoLance> createState() => _RetornoDoLanceState();
}

class _RetornoDoLanceState extends State<RetornoDoLance>
    with SingleTickerProviderStateMixin {
  bool get _acerto => widget.tipo == TipoDeRetorno.acerto;

  Duration get _total =>
      _acerto ? LucenaMotion.respiroDoTabuleiro : LucenaMotion.voltaDoErro;

  late final _tempo = AnimationController(vsync: this, duration: _total)
    ..addStatusListener((status) {
      if (status.isCompleted && !_acerto) widget.aoVoltar?.call();
    });

  bool _reduzido = false;
  bool _comecou = false;

  /// A fração do [_total] que [trecho] ocupa, desde o começo.
  Interval _ate(Duration trecho) =>
      Interval(0, trecho.inMicroseconds / _total.inMicroseconds);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_comecou) return;
    _comecou = true;
    _reduzido = MovimentoReduzido.of(context);
    if (widget.vibrar) {
      _acerto ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
    }
    _tempo.forward();
  }

  @override
  void dispose() {
    _tempo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = _acerto ? AppColors.successColor : AppColors.errorColor;
    final respiro = _ate(LucenaMotion.respiroDoTabuleiro);
    return AnimatedBuilder(
      animation: _tempo,
      builder: (context, tabuleiro) {
        final t = _tempo.value;
        final escala = _reduzido || !_acerto
            ? 1.0
            : RetornoDoLance.respiro.transform(respiro.transform(t));
        return Transform.scale(
          key: MotionKeys.tabuleiroDoRetorno,
          scale: escala,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              tabuleiro!,
              SeloNaPeca(
                casa: widget.casa,
                orientacao: widget.orientacao,
                tamanho: widget.tamanho,
                cor: cor,
                child: Icon(
                  _acerto ? Icons.check : Icons.close,
                  color: AppColors.chessWhiteColor,
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
