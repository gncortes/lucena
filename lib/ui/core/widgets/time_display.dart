import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/endgame_position.dart';
import 'goal_style.dart';

enum TimeDisplayType { clock, stopwatch, countdown, record, duration, pace }

enum TimeDisplaySize { inline, pill, block }

enum TimeDisplayState { normal, active, low, paused, highlight }

enum TimeDisplayPresentation { decorated, plain }

/// Presentation only: callers format [value] and localize [semanticsLabel],
/// including the type, value, label and any meaningful running/low state.
/// Numbers remain LTR while labels inherit the surrounding direction.
class TimeDisplay extends StatelessWidget {
  const TimeDisplay({
    required this.value,
    required this.semanticsLabel,
    this.type = TimeDisplayType.stopwatch,
    this.size = TimeDisplaySize.pill,
    this.state = TimeDisplayState.normal,
    this.presentation = TimeDisplayPresentation.decorated,
    this.label,
    this.textKey,
    this.progress,
    this.side = Side.white,
    this.width,
    this.valueWidget,
    this.icon,
    super.key,
  }) : assert(progress == null || (progress >= 0 && progress <= 1)),
       assert(width == null || (width > 0 && width < double.infinity));

  final String value;
  final String semanticsLabel;
  final TimeDisplayType type;
  final TimeDisplaySize size;
  final TimeDisplayState state;

  /// Plain numbers for callers that provide their own icon and surrounding
  /// layout. No capsule, internal padding or icon; text grows with accessibility
  /// settings. Existing presentations remain decorated by default.
  final TimeDisplayPresentation presentation;
  final String? label;
  final Key? textKey;

  /// Optional remaining fraction, displayed only for countdown blocks.
  final double? progress;
  final Side side;

  /// Fixed-width, single-row presentation for compact clocks (96/124 dp).
  /// Callers must allow more width when accessibility text needs more room.
  final double? width;

  /// Caller-styled numbers, e.g. ClockText with smaller tenths. [value] remains
  /// the formatted source; [semanticsLabel] still replaces child semantics.
  final Widget? valueWidget;

  /// Troca o ícone do tipo (o `icone` do `CompTempo`). Nulo: o do tipo.
  final IconData? icon;

  /// As cores do relógio por lado e estado (`CompTempo` tipo relógio):
  /// caixa, número e borda. Parado, a caixa fica como a do lado, sem
  /// opacidade, com o número mais fraco; pouco tempo é igual nos dois lados.
  static (Color background, Color foreground, Color border) clockColors(
    ColorScheme colors,
    Side side,
    TimeDisplayState state,
  ) {
    final white = side == Side.white;
    return switch (state) {
      TimeDisplayState.low => (
        colors.errorContainer,
        colors.onErrorContainer,
        colors.error,
      ),
      TimeDisplayState.paused => (
        white ? AppColors.white : AppColors.ink,
        white
            ? colors.onSurfaceVariant
            : AppColors.white.withValues(alpha: 0.72),
        colors.outlineVariant,
      ),
      _ => (
        white ? AppColors.white : AppColors.ink,
        white ? AppColors.ink : AppColors.white,
        colors.onSurface,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final plain = presentation == TimeDisplayPresentation.plain;
    final clock = type == TimeDisplayType.clock;
    final block = size == TimeDisplaySize.block;
    final inline = size == TimeDisplaySize.inline;
    final compact = width != null && !block;
    final running =
        state == TimeDisplayState.active || state == TimeDisplayState.low;
    final clockPalette = TimeDisplay.clockColors(colors, side, state);
    final (background, foreground, accent) = clock
        ? (clockPalette.$1, clockPalette.$2, clockPalette.$2)
        : switch (state) {
            TimeDisplayState.normal => (
              block
                  ? colors.surfaceContainerLow
                  : colors.surfaceContainerHighest,
              colors.onSurface,
              colors.onSurfaceVariant,
            ),
            TimeDisplayState.active => (
              colors.surface,
              colors.onSurface,
              colors.onSurface,
            ),
            TimeDisplayState.low => (
              colors.errorContainer,
              colors.onErrorContainer,
              colors.error,
            ),
            TimeDisplayState.paused => (
              colors.surfaceContainerHighest,
              colors.onSurfaceVariant,
              colors.onSurfaceVariant,
            ),
            // Recorde: verde de sucesso do GoalStyle, sólido, com troféu e
            // tempo em branco (T67d, variante B; 5,1:1 no claro).
            TimeDisplayState.highlight => (
              GoalStyle.of(context, PositionGoal.win).color,
              AppColors.white,
              AppColors.white,
            ),
          };
    final shownIcon =
        icon ??
        switch (type) {
          TimeDisplayType.clock => running ? Icons.av_timer_outlined : null,
          TimeDisplayType.stopwatch => Icons.timer_outlined,
          TimeDisplayType.countdown => Icons.hourglass_top_rounded,
          TimeDisplayType.record =>
            state == TimeDisplayState.highlight
                ? Icons.emoji_events_rounded
                : Icons.emoji_events_outlined,
          TimeDisplayType.duration => Icons.schedule_outlined,
          TimeDisplayType.pace => Icons.bolt_rounded,
        };
    final labelWidget = label == null || label!.isEmpty
        ? null
        : Text(
            label!,
            maxLines: compact ? 1 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: theme.textTheme.labelLarge?.copyWith(
              color: clock || state == TimeDisplayState.highlight
                  ? foreground
                  : colors.onSurfaceVariant,
            ),
          );
    final numbers = valueWidget == null
        ? Text(
            value,
            key: textKey,
            textDirection: TextDirection.ltr,
            maxLines: compact ? 1 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style:
                (block
                        ? theme.textTheme.displaySmall
                        : inline
                        ? theme.textTheme.labelLarge
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                      color: plain
                          ? state == TimeDisplayState.low
                                ? colors.error
                                : colors.onSurface
                          : foreground,
                      fontSize: plain
                          ? 16
                          : (block ? 44 : (inline ? 14 : (clock ? 22 : 20))),
                      height: plain ? 1.5 : null,
                      fontWeight: inline ? AppWeight.strong : AppWeight.heavy,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
          )
        : Directionality(
            textDirection: TextDirection.ltr,
            child: KeyedSubtree(key: textKey, child: valueWidget!),
          );
    if (plain) {
      return Semantics(
        container: true,
        label: semanticsLabel,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: numbers,
        ),
      );
    }
    final children = <Widget>[
      if (shownIcon != null)
        SizedBox.square(
          dimension: block ? 32 : (inline ? 16 : 20),
          child: Icon(
            shownIcon,
            size: block
                ? AppIconSize.large
                : (inline ? AppIconSize.small : AppIconSize.button),
            color: accent,
          ),
        ),
      if (!block && labelWidget != null)
        if (compact) Flexible(child: labelWidget) else labelWidget,
      if (compact) Flexible(child: numbers) else numbers,
    ];
    final content = compact
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: clock
                ? MainAxisAlignment.end
                : MainAxisAlignment.center,
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) const SizedBox(width: AppSpacing.xs),
                child,
              ],
            ],
          )
        : Wrap(
            alignment: clock ? WrapAlignment.end : WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: inline ? 4 : 8,
            runSpacing: AppSpacing.xs,
            children: children,
          );
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          minHeight: block ? 0 : (clock ? 44 : (inline ? 28 : 40)),
          minWidth: clock && !block && width == null ? (inline ? 72 : 116) : 0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: block ? 16 : (compact || inline ? 8 : 12),
          vertical: block ? 16 : 4,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(
            block ? AppShape.large : (clock ? AppShape.small : AppShape.full),
          ),
          border: clock
              ? Border.all(width: 2, color: clockPalette.$3)
              : state == TimeDisplayState.active
              ? Border.all(color: colors.outlineVariant)
              : null,
        ),
        child: block
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (labelWidget != null) ...[
                    labelWidget,
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  content,
                  if (type == TimeDisplayType.countdown &&
                      progress != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppShape.full),
                      child: SizedBox(
                        height: 8,
                        child: ColoredBox(
                          color: colors.surfaceContainerHighest,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: progress!.clamp(0.0, 1.0),
                              heightFactor: 1,
                              child: ColoredBox(
                                color: state == TimeDisplayState.low
                                    ? colors.error
                                    : colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : content,
      ),
    );
  }
}
