import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/use_cases/lesson_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/lesson_cubit.dart';

/// O ritmo da demonstração, do spike `docs/spikes/T51-ritmo.md`: depois de
/// cada fala, uma pausa; sem voz, um tempo de leitura pelo tamanho dela.
abstract final class DemoPace {
  static const pauseMs = 600;
  static const minReadMs = 2500;
  static const msPerChar = 65;

  /// Teto da espera por lance: a demonstração nunca fica parada mais que isso.
  static const maxWaitMs = 8000;

  /// Quanto esperar depois de uma fala de [length] letras antes do próximo
  /// lance. [spoke]: a voz acabou de falar (só a pausa); senão, o tempo de
  /// leitura. A [speed] da voz vale para os dois; o teto vale sempre.
  static double waitMs({
    required int length,
    required bool spoke,
    required double speed,
  }) {
    final reading = spoke ? 0 : max(minReadMs, length * msPerChar);
    return min((reading + pauseMs) / max(speed, 0.5), maxWaitMs.toDouble());
  }
}

/// Lê os toques no tabuleiro de um passo de estrelas para achar o lance
/// proibido, que o tabuleiro só ignora: arrastar a peça para uma casa aonde
/// ela não anda, ou tocar a peça e depois essa casa. O view model confere o
/// lance e o Viktor explica como a peça anda.
class IllegalStarMoves {
  // A peça do aluno sob o dedo.
  Square? _pressed;

  // A peça escolhida com um toque, esperando o toque no destino.
  Square? _picked;

  void down(BuildContext context, Square? square) {
    final cubit = context.read<LessonCubit>();
    if (square == null) {
      reset();
      return;
    }
    if (_own(cubit.state, square)) {
      _pressed = square;
      return;
    }
    final picked = _picked;
    reset();
    if (picked != null) cubit.refuseStar(picked, square);
  }

  void up(BuildContext context, Square? square) {
    final pressed = _pressed;
    _pressed = null;
    if (pressed == null) return;
    if (square == pressed) {
      // Um toque na peça escolhe; outro na mesma, desfaz.
      _picked = _picked == pressed ? null : pressed;
      return;
    }
    _picked = null;
    if (square != null) context.read<LessonCubit>().refuseStar(pressed, square);
  }

  /// Esquece os toques (gesto cancelado ou passo novo).
  void reset() {
    _pressed = null;
    _picked = null;
  }

  static bool _own(LessonState state, Square square) {
    final fen = state.fen;
    final step = state.current;
    if (fen == null || step == null) return false;
    return LessonRules.starsBoard(fen).pieceAt(square)?.color == step.side;
  }
}

/// Os controles da demonstração: repetir do começo, voltar um lance (e
/// parar ali) e avançar (e seguir sozinha).
class DemoControls extends StatelessWidget {
  const DemoControls({
    required this.state,
    required this.height,
    this.ring,
    super.key,
  });

  final LessonState state;
  final double height;

  /// O anel do ⏭: 0 a 1 contando até o próximo lance, [DemoRing.speaking]
  /// com a voz falando, nulo sem anel (pausada ou no fim).
  final ValueListenable<double?>? ring;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    Widget button(
      Key key,
      IconData icon,
      String tooltip,
      VoidCallback? onPressed, {
      bool main = false,
      ValueListenable<double?>? ring,
    }) => _ControlButton(
      buttonKey: key,
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      main: main,
      ring: ring,
    );
    return _ControlBar(
      wrong: state.wrongDemo,
      children: [
        // Voltar ao passo anterior da lição, como nos outros passos.
        button(
          LessonKeys.backButton,
          Icons.arrow_back,
          l10n.lessonPrevious,
          state.step == 0 ? null : cubit.back,
        ),
        button(
          LessonKeys.demoReplay,
          Icons.replay,
          l10n.lessonDemoReplay,
          cubit.demoReplay,
        ),
        button(
          LessonKeys.demoBack,
          Icons.skip_previous_rounded,
          l10n.lessonDemoBack,
          state.demoMove == 0 ? null : cubit.demoBack,
        ),
        button(
          LessonKeys.demoPause,
          state.demoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          state.demoPlaying ? l10n.lessonDemoPause : l10n.lessonDemoPlay,
          cubit.demoTogglePause,
        ),
        button(
          LessonKeys.demoForward,
          Icons.skip_next_rounded,
          l10n.lessonDemoForward,
          cubit.demoForward,
          main: true,
          ring: ring,
        ),
      ],
    );
  }
}

/// Os controles do modo variante (LICOES-V2 §1), fixos no rodapé nos mesmos
/// lugares dos da demonstração: fechar à esquerda, lance anterior no meio e
/// próximo lance no canto. Os dois cursores (a variante da fala e a da
/// explicação) usam estes controles.
class VariationControls extends StatelessWidget {
  const VariationControls({
    required this.canPrevious,
    required this.canNext,
    required this.onExit,
    required this.onBack,
    required this.onForward,
    this.wrong = false,
    super.key,
  });

  final bool canPrevious;
  final bool canNext;

  /// A variante é a linha errada da aula.
  final bool wrong;
  final VoidCallback onExit;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const gap = SizedBox.square(dimension: _ControlButton.size);
    return _ControlBar(
      wrong: wrong,
      children: [
        _ControlButton(
          buttonKey: LessonKeys.variationExit,
          icon: Icons.close_rounded,
          tooltip: l10n.lessonVariationClose,
          onPressed: onExit,
        ),
        gap,
        _ControlButton(
          buttonKey: LessonKeys.variationBack,
          icon: Icons.skip_previous_rounded,
          tooltip: l10n.lessonVariationPrevious,
          onPressed: canPrevious ? onBack : null,
        ),
        gap,
        _ControlButton(
          buttonKey: LessonKeys.variationForward,
          icon: Icons.skip_next_rounded,
          tooltip: l10n.lessonVariationNext,
          onPressed: canNext ? onForward : null,
          main: true,
        ),
      ],
    );
  }
}

/// O trecho do Viktor no modo variante: a linha com o lance da vez em
/// destaque e o texto daquele ponto (até 2 linhas), sem card, entre o
/// tabuleiro e os controles.
class VariationStrip extends StatelessWidget {
  const VariationStrip({
    required this.moves,
    required this.current,
    required this.text,
    super.key,
  });

  /// Os lances da linha como estão escritos ("1...Rf6?", "2.Rf4").
  final List<String> moves;

  /// O lance da vez, de 1 a [moves].length; 0, nenhum.
  final int current;
  final String text;

  static String _shown(int index, String move) =>
      index > 0 ? move.replaceFirst(RegExp(r'^\d+\.\.\.'), '') : move;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = theme.textTheme.bodyLarge!;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            key: LessonKeys.variationStripCurrent,
            TextSpan(
              children: [
                for (final (index, move) in moves.indexed) ...[
                  if (index > 0) const TextSpan(text: ' '),
                  TextSpan(
                    // Notação isolada da direção do texto (RTL); o leitor de
                    // tela lê o lance sem os caracteres de isolamento.
                    // O número das pretas só abre a linha ("1...Re6"); no
                    // meio dela vale a notação da fala ("1.Rf4 Re6").
                    text: '\u2066${_shown(index, move)}\u2069',
                    semanticsLabel: _shown(index, move),
                    style: index + 1 == current
                        ? TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                            backgroundColor: colors.primaryContainer,
                          )
                        : const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            style: body.copyWith(color: colors.onSurface),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: body.copyWith(color: colors.onSurface),
            ),
          ],
        ],
      ),
    );
  }
}

/// O selo "Linha errada": a linha mostrada é o que não fazer.
class WrongLineBadge extends StatelessWidget {
  const WrongLineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = context.l10n.lessonWrongLine;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.errorContainer,
        elevation: 2,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.highlight_off_rounded,
                size: 18,
                color: colors.onErrorContainer,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A fileira dos controles redondos, sobre um esmaecer até o fundo. Na
/// linha errada, o selo vem acima dela. As setas não espelham (`ltr`).
class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.children, this.wrong = false});

  final List<Widget> children;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    return LessonFooterSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wrong)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: WrongLineBadge(key: LessonKeys.wrongLineControls),
            ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Um controle redondo de 48 dp (canvas `redondo`): o principal em destaque,
/// desligado sem ação (0,38), sem elevação.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.main = false,
    this.ring,
  });

  static const size = 48.0;

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool main;

  /// O anel de tempo em volta do botão (só o ⏭ da demonstração).
  final ValueListenable<double?>? ring;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = main ? colors.primary : colors.surfaceContainerHigh;
    final foreground = main ? colors.onPrimary : colors.onSurface;
    final button = IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(size),
        minimumSize: const Size.square(size),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        elevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
      ),
    );
    // Desligado: 0,38 no botão inteiro (fundo e ícone juntos), como no canvas.
    final dimmed = onPressed == null
        ? Opacity(opacity: 0.38, child: button)
        : button;
    final ring = this.ring;
    return SizedBox.square(
      dimension: size,
      child: ring == null
          ? dimmed
          : Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: -DemoRing.outside,
                  top: -DemoRing.outside,
                  child: ExcludeSemantics(
                    child: IgnorePointer(child: DemoRing(progress: ring)),
                  ),
                ),
                dimmed,
              ],
            ),
    );
  }
}

/// O anel de tempo do ⏭ da demonstração: 60 dp (6 fora do botão), traço 3,
/// trilho `outlineVariant`, arco `primary` a partir das 12 h, no sentido
/// horário. Com a voz falando, o trilho fica tracejado e sem arco. Sem valor
/// (demonstração pausada ou no fim), nada. Com movimento reduzido, o arco
/// anda em degraus de 25 %.
class DemoRing extends StatefulWidget {
  const DemoRing({required this.progress, super.key});

  /// 0 a 1; [speaking] com a voz falando; nulo sem anel.
  final ValueListenable<double?> progress;

  /// Valor que marca "falando".
  static const speaking = -1.0;
  static const outside = 6.0;
  static const diameter = 60.0;
  static const stroke = 3.0;

  /// Intervalo entre os tiques da demonstração (a animação do arco).
  static const tick = Duration(milliseconds: 250);

  @override
  State<DemoRing> createState() => _DemoRingState();
}

class _DemoRingState extends State<DemoRing> {
  double _last = 0;

  /// Muda quando o valor cai (o lance saiu): o arco recomeça em 0 na hora,
  /// sem "desenrolar" de volta.
  int _restarts = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduced = AppMotion.of(context).disabled;
    return ValueListenableBuilder<double?>(
      valueListenable: widget.progress,
      builder: (context, value, _) {
        const diameter = DemoRing.diameter;
        if (value == null) {
          _last = 0;
          return const SizedBox.square(dimension: diameter);
        }
        if (value >= 0) {
          if (value < _last) _restarts++;
          _last = value;
        }
        final isSpeaking = value < 0;
        Widget paint(double v) => CustomPaint(
          key: LessonKeys.demoRing,
          size: const Size.square(diameter),
          painter: _RingPainter(
            progress: v,
            speaking: isSpeaking,
            track: colors.outlineVariant,
            arc: colors.primary,
          ),
        );
        if (isSpeaking) return paint(0);
        if (reduced) return paint((value.clamp(0.0, 1.0) * 4).floor() / 4);
        return TweenAnimationBuilder<double>(
          key: ValueKey(_restarts),
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: DemoRing.tick,
          // Contínuo entre os tiques: linear, não o "enter" das telas.
          curve: AppMotion.linear,
          builder: (context, v, _) => paint(v),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.speaking,
    required this.track,
    required this.arc,
  });

  final double progress;
  final bool speaking;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = DemoRing.stroke;
    // Linha do traço no raio 27 (canvas `redondo`: círculo r=27, traço 3).
    const inset = stroke / 2 + 1.5;
    final rect =
        const Offset(inset, inset) &
        Size(size.width - 2 * inset, size.height - 2 * inset);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    if (speaking) {
      final path = Path()..addOval(rect);
      for (final metric in path.computeMetrics()) {
        var at = 0.0;
        while (at < metric.length) {
          canvas.drawPath(
            metric.extractPath(at, min(at + 3, metric.length)),
            trackPaint,
          );
          at += 6;
        }
      }
      return;
    }
    canvas.drawOval(rect, trackPaint);
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
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
      old.progress != progress ||
      old.speaking != speaking ||
      old.track != track ||
      old.arc != arc;
}

/// O fim de uma parte: o selo de feito, "Parte N concluída" e a próxima
/// parte recomendada (ou o teste final, com todas feitas).
class PartFinished extends StatelessWidget {
  const PartFinished({required this.state, super.key});

  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lessonId = state.lesson!.id;
    final part = state.part!;
    final next = state.nextPart;
    final viktor = state.viktor;
    final motion = AppMotion.of(context);
    final summary = state.texts.partSummary(lessonId, part.id);
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: LessonKeys.partFinished,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: motion.celebrate,
                      curve: AppMotion.pop,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 52,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      // Na última: todas as etapas, e o convite para a prova.
                      next == null
                          ? l10n.lessonAllPartsDone
                          : l10n.lessonPartDone(state.partNumber),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      next == null
                          ? l10n.lessonAllPartsDoneBody
                          : state.texts.partTitle(lessonId, part.id) ?? '',
                      key: next == null ? LessonKeys.allPartsDone : null,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    // O que a etapa ensinou: para bater o olho e decidir se
                    // vale rever.
                    if (summary != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        key: LessonKeys.partSummary,
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppShape.medium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.lessonPartLearned,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(summary, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                    if (viktor != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      TeacherSpeech(
                        teacher: viktor,
                        text: state.speech,
                        emotion: state.emotion,
                        avatarSize: 56,
                        speaks: true,
                        speechContext: SpeechContext.teaching,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Fixos embaixo: rever esta etapa ou seguir.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: LessonKeys.reviewPartButton,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => context.pushReplacement(
                        Routes.endgameLessonSteps(lessonId, part: part.id),
                      ),
                      icon: const Icon(Icons.replay),
                      label: Text(l10n.lessonReviewPart),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      key: LessonKeys.nextPartButton,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      // Na última etapa, o teste final (pela introdução).
                      onPressed: () => context.pushReplacement(
                        next == null
                            ? Routes.endgameExercisesIntro(lessonId)
                            : Routes.endgameLessonSteps(lessonId, part: next),
                      ),
                      icon: Icon(
                        next == null
                            ? Icons.quiz_outlined
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        next == null
                            ? l10n.lessonToFinalTest
                            : l10n.lessonPartNext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!motion.disabled) const Celebration(),
      ],
    );
  }
}

/// O fundo do rodapé da lição (CompRodapeLicao): 24 dp de esmaecer até a cor
/// da tela e, abaixo, fundo sólido, para o texto que rola não aparecer por
/// entre os botões. A fala termina acima do esmaecer (o rodapé inteiro, com
/// ele, entra na altura reservada).
class LessonFooterSurface extends StatelessWidget {
  const LessonFooterSurface({required this.child, super.key});

  final Widget child;

  /// Altura do esmaecer (canvas: 24 dp acima dos botões).
  static const fadeHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    // Mesma cor do painel da lição (canvas: #F4F3F8 no claro).
    final background = Theme.of(context).colorScheme.surfaceContainerLow;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: fadeHeight,
          child: DecoratedBox(
            key: LessonKeys.footerFade,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [background.withValues(alpha: 0), background],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        ColoredBox(
          color: background,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ),
      ],
    );
  }
}
