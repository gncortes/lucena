import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/keys/lesson_script_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/canvas_symbols.dart';

/// As cores do rodapé da demonstração (canvas `T70-etapa1-estados`, `.cb`):
/// o trilho e o arco do anel, e o cinza do anel pausado e do botão sem uso.
abstract final class ScriptDemoColors {
  static const track = Color(0xFFDCE3F0);
  static const arc = Color(0xFF7FA0D6);
  static const off = Color(0xFFB9BDC7);
}

/// Os controles da demonstração (etapa 2), à direita do ← redondo: ↻
/// repetir, ⏮ lance anterior, ⏸/▶ e o ⏭ principal com o anel do tempo de
/// leitura (Gabriel, 14/10/2026; canvas `T70-etapa1-estados`, E12). O ⏭ faz
/// o mesmo que o botão principal da etapa; o anel cheio também avança. Na
/// teoria (etapa 1, [full] falso), só ⏸/▶ e o Continuar que enche (Gabriel,
/// 16/10/2026).
class ScriptDemoControls extends StatelessWidget {
  const ScriptDemoControls({
    required this.playing,
    required this.progress,
    required this.remaining,
    required this.tick,
    required this.canStepBack,
    required this.mainTooltip,
    required this.onRepeat,
    required this.onStepBack,
    required this.onToggle,
    required this.onNext,
    this.speaking = false,
    this.full = true,
    this.canvasLayout = false,
    super.key,
  });

  final bool playing;

  /// Com ↻ e ⏮ (a demonstração); falso, só ⏸/▶ e o Continuar (a teoria).
  final bool full;
  final bool canvasLayout;

  /// A voz do Viktor está falando: o anel espera parado (sem ficar cinza).
  final bool speaking;

  /// O quanto do passo já passou (0 a 1) quando o estado saiu.
  final double progress;

  /// O tempo que falta para o passo acabar: o anel enche nele.
  final Duration remaining;

  /// Muda a cada passo: o anel recomeça.
  final int tick;
  final bool canStepBack;

  /// O rótulo do botão principal da etapa (Continuar, Próxima etapa).
  final String mainTooltip;
  final VoidCallback onRepeat;
  final VoidCallback onStepBack;
  final VoidCallback onToggle;
  final VoidCallback onNext;

  /// O espaço entre os botões (canvas, `.foot` gap 12).
  static const gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (full) ...[
          ScriptDemoButton(
            buttonKey: LessonScriptKeys.demoRepeat,
            icon: canvasLayout ? CanvasSymbols.replay : Icons.replay_rounded,
            tooltip: l10n.lessonDemoReplay,
            onPressed: onRepeat,
          ),
          const SizedBox(width: gap),
          ScriptDemoButton(
            buttonKey: LessonScriptKeys.demoStepBack,
            icon: canvasLayout
                ? CanvasSymbols.skipPrevious
                : Icons.skip_previous_rounded,
            tooltip: l10n.lessonDemoBack,
            onPressed: canStepBack ? onStepBack : null,
          ),
          const SizedBox(width: gap),
        ],
        ScriptDemoButton(
          buttonKey: LessonScriptKeys.demoToggle,
          icon: canvasLayout
              ? playing
                    ? CanvasSymbols.pause
                    : CanvasSymbols.playArrow
              : playing
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          tooltip: playing ? l10n.lessonDemoPause : l10n.lessonDemoPlay,
          onPressed: onToggle,
        ),
        const SizedBox(width: gap),
        if (full)
          Padding(
            // O anel passa 4 dp do botão: o rodapé guarda o espaço dele.
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: SizedBox.square(
              dimension: _DemoRing.diameter,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _DemoRing(
                    playing: playing,
                    speaking: speaking,
                    progress: progress,
                    remaining: remaining,
                    tick: tick,
                  ),
                  ScriptDemoButton(
                    buttonKey: LessonScriptKeys.primary,
                    icon: canvasLayout
                        ? CanvasSymbols.skipNext
                        : Icons.skip_next_rounded,
                    tooltip: mainTooltip,
                    onPressed: onNext,
                    main: true,
                  ),
                ],
              ),
            ),
          )
        else
          // Mesma altura do anel: o tabuleiro não se mexe entre a teoria e a
          // demonstração.
          SizedBox(
            height: _DemoRing.diameter,
            child: Center(
              child: _FillButton(
                label: mainTooltip,
                onPressed: onNext,
                playing: playing,
                speaking: speaking,
                progress: progress,
                remaining: remaining,
                tick: tick,
                canvasLayout: canvasLayout,
              ),
            ),
          ),
      ],
    );
  }
}

/// Um botão redondo do rodapé da demonstração: 48 dp, ícone na cor primária,
/// sem fundo; o principal tem 56 dp, fundo primário. Sem ação, cinza.
class ScriptDemoButton extends StatelessWidget {
  const ScriptDemoButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.main = false,
    super.key,
  });

  static const size = 48.0;
  static const mainSize = 56.0;

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool main;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final side = main ? mainSize : size;
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: AppIconSize.standard,
        fill: icon.fontFamily == CanvasSymbols.family ? 1 : null,
      ),
      style: IconButton.styleFrom(
        fixedSize: Size.square(side),
        minimumSize: Size.square(side),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        backgroundColor: main ? colors.primary : Colors.transparent,
        foregroundColor: main ? colors.onPrimary : colors.primary,
        disabledForegroundColor: ScriptDemoColors.off,
      ),
    );
  }
}

/// O relógio do passo: um valor de 0 a 1 que enche de [progress] até o fim
/// em [remaining] enquanto toca e recomeça a cada [tick]. Pausado ou com a
/// voz falando, para. Desenha o anel do ⏭ ou o Continuar que enche.
class _DemoClock extends StatefulWidget {
  const _DemoClock({
    required this.playing,
    required this.speaking,
    required this.progress,
    required this.remaining,
    required this.tick,
    required this.builder,
  });

  final bool playing;
  final bool speaking;
  final double progress;
  final Duration remaining;
  final int tick;
  final Widget Function(BuildContext context, double value) builder;

  @override
  State<_DemoClock> createState() => _DemoClockState();
}

class _DemoClockState extends State<_DemoClock>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _run();
    }
  }

  @override
  void didUpdateWidget(_DemoClock old) {
    super.didUpdateWidget(old);
    if (old.tick != widget.tick ||
        old.playing != widget.playing ||
        old.speaking != widget.speaking ||
        old.progress != widget.progress ||
        old.remaining != widget.remaining) {
      _run();
    }
  }

  void _run() {
    _controller
      ..stop()
      ..value = widget.progress.clamp(0.0, 1.0);
    if (!widget.playing || widget.speaking || AppMotion.reduced(context)) {
      return;
    }
    if (widget.remaining <= Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller.animateTo(
      1,
      duration: widget.remaining,
      curve: AppMotion.linear,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(context, _controller.value),
  );
}

/// O anel do tempo em volta do ⏭: trilho claro e o arco. Pausado, fica
/// cinza.
class _DemoRing extends StatelessWidget {
  const _DemoRing({
    required this.playing,
    required this.speaking,
    required this.progress,
    required this.remaining,
    required this.tick,
  });

  static const diameter = 64.0;
  static const stroke = 3.0;

  final bool playing;
  final bool speaking;
  final double progress;
  final Duration remaining;
  final int tick;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: _DemoClock(
      playing: playing,
      speaking: speaking,
      progress: progress,
      remaining: remaining,
      tick: tick,
      builder: (context, value) => CustomPaint(
        key: LessonScriptKeys.demoRing,
        size: const Size.square(diameter),
        painter: _RingPainter(
          progress: value,
          arc: playing ? ScriptDemoColors.arc : ScriptDemoColors.off,
        ),
      ),
    ),
  );
}

/// O Continuar da teoria (etapa 1) que enche da esquerda para a direita no
/// tempo do passo; cheio, a fala segue (Gabriel, 16/10/2026: variante A,
/// canvas `PropV2TeoriaTimerBarra`). A faixa escurece o botão tocando e
/// clareia pausado.
class _FillButton extends StatelessWidget {
  const _FillButton({
    required this.label,
    required this.onPressed,
    required this.playing,
    required this.speaking,
    required this.progress,
    required this.remaining,
    required this.tick,
    this.canvasLayout = false,
  });

  /// A faixa do tempo sobre o botão (canvas, `corBarra`).
  static const _shade = Color(0x3D000000);
  static const _shadePaused = Color(0x47FFFFFF);

  final String label;
  final VoidCallback onPressed;
  final bool playing;
  final bool speaking;
  final double progress;
  final Duration remaining;
  final int tick;
  final bool canvasLayout;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppShape.full),
    child: Stack(
      children: [
        FilledButton(
          key: LessonScriptKeys.primary,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size(0, kButtonHeightCompact),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            ),
            textStyle: WidgetStatePropertyAll(
              AppButtonText.footer(context)?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: canvasLayout ? 14 : null,
                height: canvasLayout ? 20 / 14 : null,
                letterSpacing: canvasLayout ? .1 : null,
              ),
            ),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _DemoClock(
              playing: playing,
              speaking: speaking,
              progress: progress,
              remaining: remaining,
              tick: tick,
              builder: (context, value) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  key: LessonScriptKeys.theoryFill,
                  widthFactor: value,
                  heightFactor: 1,
                  child: ColoredBox(color: playing ? _shade : _shadePaused),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.arc});

  final double progress;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = _DemoRing.stroke;
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(
      ring,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ScriptDemoColors.track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      ring,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.arc != arc;
}
