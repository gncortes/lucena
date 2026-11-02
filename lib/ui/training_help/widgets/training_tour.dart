import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_course.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_button.dart';
import '../../core/widgets/sheet_close_button.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';

/// Explicitly requested tour. The route owns the guide behind this overlay and
/// navigation after durable completion; this widget never opens itself.
class TrainingTour extends StatefulWidget {
  const TrainingTour({
    required this.child,
    required this.onTab,
    required this.onClose,
    super.key,
  });
  final Widget child;
  final ValueChanged<CourseGuideTab> onTab;
  final VoidCallback onClose;
  @override
  State<TrainingTour> createState() => _TrainingTourState();
}

class _TrainingTourState extends State<TrainingTour> {
  var _step = 0;
  var _saving = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onTab(CourseGuideTab.lesson);
    });
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await context.read<CourseGuideCubit>().markTourSeen();
    if (!mounted) return;
    if (saved) {
      widget.onClose();
    } else {
      setState(() {
        _saving = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final titles = [
      t.courseGuideTour1Title,
      t.courseGuideTour2Title,
      t.courseGuideTour3Title,
      t.courseGuideTour4Title,
    ];
    final bodies = [
      t.courseGuideTour1Body,
      t.courseGuideTour2Body,
      t.courseGuideTour3Body,
      t.courseGuideTour4Body,
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish();
      },
      child: Stack(
        key: TrainingKeys.tourOverlay,
        children: [
          ExcludeSemantics(child: IgnorePointer(child: widget.child)),
          Positioned.fill(
            child: CustomPaint(
              painter: _TourMask(
                step: _step,
                bottom: MediaQuery.paddingOf(context).bottom,
                scrim: AppColors.black.withValues(alpha: .62),
                surface: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: SheetCloseButton(
                    key: TrainingKeys.tourClose,
                    onPressed: _finish,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppShape.large),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.sizeOf(context).height -
                          MediaQuery.paddingOf(context).vertical -
                          250,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          Text(
                            t.courseGuideTourOf(_step + 1, 4),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              titles[_step],
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 20,
                                    height: 1.2,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          Text(
                            bodies[_step],
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(letterSpacing: 0),
                          ),
                          if (_failed)
                            Text(
                              t.trainingExerciseSaveError,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          Row(
                            children: [
                              if (_step < 3)
                                TextButton(
                                  key: TrainingKeys.tourSkip,
                                  onPressed: _saving ? null : _finish,
                                  child: Text(t.courseGuideTourSkip),
                                ),
                              const Spacer(),
                              FilledButton(
                                key: TrainingKeys.tourNext,
                                style: FilledButton.styleFrom(
                                  fixedSize: const Size(140, kButtonHeight),
                                ),
                                onPressed: _saving
                                    ? null
                                    : () {
                                        if (_step == 3 || _failed) {
                                          _finish();
                                          return;
                                        }
                                        setState(() => _step++);
                                        widget.onTab(
                                          CourseGuideTab.values[_step],
                                        );
                                      },
                                child: Text(
                                  _step == 3
                                      ? t.courseGuideTourDone
                                      : t.courseGuideTourNext,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TourMask extends CustomPainter {
  const _TourMask({
    required this.step,
    required this.bottom,
    required this.scrim,
    required this.surface,
  });
  final int step;
  final double bottom;
  final Color scrim, surface;
  @override
  void paint(Canvas canvas, Size size) {
    final width = (size.width - 16) / 4;
    final focus = RRect.fromRectAndRadius(
      Rect.fromLTWH(8 + step * width, size.height - bottom - 80, width, 70),
      const Radius.circular(AppShape.card),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(focus),
      Paint()..color = scrim,
    );
    canvas.drawRRect(
      focus,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final arrowX = (8 + (step + .5) * width).clamp(32.0, size.width - 32);
    final arrowY = size.height - bottom - 100;
    canvas.drawPath(
      Path()
        ..moveTo(arrowX - 8, arrowY - 1)
        ..lineTo(arrowX + 8, arrowY - 1)
        ..lineTo(arrowX, arrowY + 10)
        ..close(),
      Paint()..color = surface,
    );
  }

  @override
  bool shouldRepaint(_TourMask oldDelegate) =>
      step != oldDelegate.step ||
      bottom != oldDelegate.bottom ||
      scrim != oldDelegate.scrim ||
      surface != oldDelegate.surface;
}
