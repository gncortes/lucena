import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/goal_style.dart';
import '../view_models/race_cubit.dart';

/// O placar do alto: o contador de acertos, que dá lugar ao ícone de certo ou
/// de erro (64, animado) a cada lance e volta, já somado, quando o próximo
/// problema entra. Sem som e sem texto: o ícone é o aviso.
class RaceScoreboard extends StatefulWidget {
  const RaceScoreboard({
    required this.count,
    required this.feedback,
    required this.feedbackCount,
    super.key,
  });

  /// A altura reservada em cima do tabuleiro.
  static const height = 88.0;
  static const _icon = 64.0;

  final int count;
  final RaceFeedback? feedback;

  /// Muda a cada lance: o ícone anima de novo mesmo repetindo o resultado.
  final int feedbackCount;

  @override
  State<RaceScoreboard> createState() => _RaceScoreboardState();
}

class _RaceScoreboardState extends State<RaceScoreboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebrate,
  );

  // Enquanto o ícone aparece, o contador ainda mostra o número de antes.
  late int _shown = widget.count;
  RaceFeedback? _playing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Remover animações": o ícone não precisa de movimento, mas o número
    // não pode ficar para trás.
    if (AppMotion.reduced(context)) _settle();
  }

  @override
  void didUpdateWidget(RaceScoreboard old) {
    super.didUpdateWidget(old);
    if (widget.feedbackCount == old.feedbackCount) {
      if (!_controller.isAnimating) _shown = widget.count;
      return;
    }
    if (AppMotion.reduced(context) || widget.feedback == null) {
      _settle();
      return;
    }
    _shown = old.count;
    _playing = widget.feedback;
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) setState(_settle);
    });
  }

  void _settle() {
    _shown = widget.count;
    _playing = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Quanto o intervalo [from, to] da animação já andou, de 0 a 1.
  double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final feedback = _playing;
    final success = ChangeColors.of(context, up: true);
    final error = theme.colorScheme.error;
    return SizedBox(
      key: RaceKeys.scoreboard,
      height: RaceScoreboard.height,
      child: Semantics(
        liveRegion: true,
        label: switch (feedback) {
          RaceFeedback.correct => l10n.raceFeedbackCorrect,
          RaceFeedback.wrong => l10n.raceFeedbackWrong,
          null => null,
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.isAnimating ? _controller.value : 0.0;
            final running = feedback != null && _controller.isAnimating;
            // O contador some rápido, o ícone fica e depois sai para ele
            // voltar.
            final iconIn = _span(t, 0.05, 0.18);
            final iconOut = 1 - _span(t, 0.72, 0.84);
            final iconOpacity = running ? math.min(iconIn, iconOut) : 0.0;
            final counterOpacity = running
                ? 1 - math.max(iconIn, 0) * iconOut
                : 1.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: counterOpacity.clamp(0.0, 1.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_shown',
                        key: RaceKeys.count,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color:
                              running &&
                                  t > 0.84 &&
                                  feedback == RaceFeedback.correct
                              ? success
                              : null,
                        ),
                      ),
                      Text(
                        l10n.raceCorrectsCount(_shown),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (running)
                  Opacity(
                    opacity: iconOpacity.clamp(0.0, 1.0),
                    child: feedback == RaceFeedback.correct
                        ? _CorrectIcon(t: t, color: success, span: _span)
                        : _WrongIcon(t: t, color: error),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// O acerto: o círculo verde pula e uma onda sai dele.
class _CorrectIcon extends StatelessWidget {
  const _CorrectIcon({
    required this.t,
    required this.color,
    required this.span,
  });

  final double t;
  final Color color;
  final double Function(double, double, double) span;

  @override
  Widget build(BuildContext context) {
    final jump = math.sin(math.pi * span(t, 0.05, 0.45));
    final wave = AppMotion.enter.transform(span(t, 0.15, 0.7));
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: (1 - wave).clamp(0.0, 1.0) * 0.4,
          child: Transform.scale(
            scale: 1 + wave * 0.9,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: RaceScoreboard._icon),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -jump * AppSpacing.lg),
          child: Transform.scale(
            scale: 0.8 + 0.2 * AppMotion.pop.transform(span(t, 0.05, 0.3)),
            child: Icon(
              key: RaceKeys.feedbackCorrect,
              Icons.check_circle,
              size: RaceScoreboard._icon,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// O erro: o círculo vermelho pula e treme de lado a lado.
class _WrongIcon extends StatelessWidget {
  const _WrongIcon({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shake = math.sin(t * math.pi * 12) * AppSpacing.sm * (1 - t);
    final jump = math.sin(math.pi * (t / 0.3).clamp(0.0, 1.0));
    return Transform.translate(
      offset: Offset(shake, -jump * AppSpacing.sm),
      child: Icon(
        key: RaceKeys.feedbackWrong,
        Icons.cancel,
        size: RaceScoreboard._icon,
        color: color,
      ),
    );
  }
}

/// As três chances embaixo do relógio: cada erro vira um quadrado vermelho
/// com X.
class RaceChances extends StatelessWidget {
  const RaceChances({required this.errors, required this.total, super.key});

  static const height = 32.0;
  static const _box = 24.0;

  final int errors;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: context.l10n.raceChances(total - errors),
      child: ExcludeSemantics(
        child: SizedBox(
          key: RaceKeys.chances,
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  key: RaceKeys.chance(i, lost: i < errors),
                  duration: AppMotion.of(context).state,
                  width: _box,
                  height: _box,
                  decoration: BoxDecoration(
                    color: i < errors ? colors.error : null,
                    borderRadius: BorderRadius.circular(AppShape.small),
                    border: i < errors
                        ? null
                        : Border.all(
                            color: colors.outlineVariant,
                            width: AppShape.hairline,
                          ),
                  ),
                  child: Icon(
                    Icons.close,
                    size: AppIconSize.small,
                    color: i < errors ? colors.onError : colors.outlineVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
