import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/endgame_position.dart';
import '../theme/app_shape.dart';
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
    // Piece-side colors intentionally stay fixed across light/dark themes.
    const light = Color(0xFFFFFFFF);
    const dark = Color(0xFF262421);
    final darkTheme = theme.brightness == Brightness.dark;
    final (background, foreground, accent) = clock
        ? side == Side.white
              ? (light, dark, dark)
              : (dark, light, light)
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
              darkTheme ? const Color(0xFF0B2E10) : const Color(0xFFFFFFFF),
              darkTheme ? const Color(0xFF0B2E10) : const Color(0xFFFFFFFF),
            ),
          };
    final icon = switch (type) {
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
              fontWeight: block ? FontWeight.w600 : FontWeight.w500,
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
                      fontWeight: inline ? FontWeight.w700 : FontWeight.w800,
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
      if (state == TimeDisplayState.low)
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.error,
            shape: BoxShape.circle,
          ),
          child: const SizedBox.square(dimension: 8),
        ),
      if (icon != null)
        SizedBox.square(
          dimension: block ? 32 : (inline ? 16 : 20),
          child: Icon(
            icon,
            size: block ? 32 : (inline ? 16 : 20),
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
                if (index > 0) const SizedBox(width: 4),
                child,
              ],
            ],
          )
        : Wrap(
            alignment: clock ? WrapAlignment.end : WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: inline ? 4 : 8,
            runSpacing: 4,
            children: children,
          );
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Opacity(
        opacity: clock && state == TimeDisplayState.paused ? 0.55 : 1,
        child: Container(
          width: width,
          constraints: BoxConstraints(
            minHeight: block ? 0 : (clock ? 44 : (inline ? 28 : 40)),
            minWidth: clock && !block && width == null
                ? (inline ? 72 : 116)
                : 0,
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
                ? Border.all(
                    width: 2,
                    // O relógio aceso (a vez) leva a borda primária de 2 px (T73, D1).
                    color: running ? colors.primary : colors.outlineVariant,
                  )
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
                      const SizedBox(height: 8),
                    ],
                    content,
                    if (type == TimeDisplayType.countdown &&
                        progress != null) ...[
                      const SizedBox(height: 8),
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
      ),
    );
  }
}
