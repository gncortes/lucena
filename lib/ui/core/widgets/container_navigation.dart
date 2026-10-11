import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Container transform for Android UI entry points. Canonical/deep-link
/// navigation remains the caller's responsibility on other platforms.
/// This imperative route deliberately does not replace the GoRouter URI.
class ContainerNavigation extends StatefulWidget {
  const ContainerNavigation({
    required this.closedBuilder,
    required this.openBuilder,
    required this.onFallback,
    required this.color,
    this.shape = const RoundedRectangleBorder(),
    this.routeName,
    this.onClosed,
    super.key,
  });

  /// Close the imperative entry before changing the canonical route.
  /// Capture the router before calling this: destination context is disposed.
  static void leave(BuildContext context, VoidCallback navigate) {
    final scope = context.getInheritedWidgetOfExactType<_ContainerExitScope>();
    if (scope == null) {
      navigate();
    } else {
      scope.close(navigate);
    }
  }

  static bool canClose(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ContainerExitScope>() != null;

  static void close(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ContainerExitScope>()?.close(null);

  final Widget Function(BuildContext, VoidCallback) closedBuilder;
  final WidgetBuilder openBuilder;
  final Future<void> Function() onFallback;
  final Color color;
  final ShapeBorder shape;
  final String? routeName;
  final VoidCallback? onClosed;

  @override
  State<ContainerNavigation> createState() => _ContainerNavigationState();
}

class _ContainerNavigationState extends State<ContainerNavigation> {
  bool _opening = false;
  Widget? _destination;
  VoidCallback? _closeAction;
  VoidCallback? _afterClose;
  bool _closeRequested = false;
  Future<void>? _routeFinished;

  void _requestClose(VoidCallback? navigate) {
    if (_closeRequested) return;
    _closeRequested = true;
    _afterClose = navigate;
    _closeAction?.call();
  }

  Widget _buildDestination(BuildContext context) {
    _routeFinished ??= ModalRoute.of(context)?.completed.then<void>((_) {});
    return _destination ??= _ContainerExitScope(
      close: _requestClose,
      child: widget.openBuilder(context),
    );
  }

  Future<void> _finish() async {
    // Navigator.push completes when pop starts. Wait for removal as well,
    // so a canonical navigation cannot land behind the closing container.
    await _routeFinished;
    _closed();
  }

  void _closed() {
    final navigate = _afterClose;
    _afterClose = null;
    _closeAction = null;
    _closeRequested = false;
    _routeFinished = null;
    _destination = null;
    if (!mounted) return;
    setState(() => _opening = false);
    widget.onClosed?.call();
    navigate?.call();
  }

  void _open(VoidCallback action) {
    if (_opening) return;
    setState(() => _opening = true);
    action();
  }

  Future<void> _fallback() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onFallback();
    } finally {
      _closed();
    }
  }

  Future<void> _withoutMotion() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          settings: RouteSettings(name: widget.routeName),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, _, _) {
            _closeAction = () => Navigator.of(context).pop();
            return _buildDestination(context);
          },
        ),
      );
    } finally {
      await _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || Theme.of(context).platform != TargetPlatform.android) {
      return widget.closedBuilder(context, _fallback);
    }
    // Zero-duration OpenContainer does not reliably restore its hidden
    // source. Reduced motion uses a plain zero-transition page instead.
    if (AppMotion.of(context).disabled) {
      return widget.closedBuilder(context, _withoutMotion);
    }
    return OpenContainer<void>(
      tappable: false,
      closedColor: widget.color,
      openColor: Theme.of(context).colorScheme.surface,
      closedElevation: 0,
      openElevation: 0,
      closedShape: widget.shape,
      transitionDuration: AppMotion.of(context).screen,
      routeSettings: RouteSettings(name: widget.routeName),
      onClosed: (_) => _finish(),
      closedBuilder: (context, open) =>
          widget.closedBuilder(context, () => _open(open)),
      // The package reparents this subtree while transforming. Cache only
      // for this opening, so the destination's provider owns one Cubit.
      openBuilder: (context, close) {
        _closeAction = () => close();
        return _buildDestination(context);
      },
    );
  }
}

class _ContainerExitScope extends InheritedWidget {
  const _ContainerExitScope({required this.close, required super.child});
  final void Function(VoidCallback?) close;

  @override
  bool updateShouldNotify(_ContainerExitScope oldWidget) => false;
}
