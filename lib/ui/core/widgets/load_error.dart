import 'package:flutter/material.dart';

import '../../../domain/models/load_failure.dart';

import '../keys/load_error_keys.dart';
import '../l10n/l10n.dart';
import '../theme/canvas_symbols.dart';
import 'actions_footer.dart';
import 'busy_button.dart';

enum LoadErrorKind {
  generic,
  offline,
  noSpace,
  unavailable,
  notFound,
  engine,
  launch,
  launchAgain;

  static LoadErrorKind fromFailure(LoadFailure failure) => switch (failure) {
    LoadFailure.generic => generic,
    LoadFailure.offline => offline,
    LoadFailure.noSpace => noSpace,
    LoadFailure.unavailable => unavailable,
    LoadFailure.notFound => notFound,
    LoadFailure.engine => engine,
  };
}

/// Full-screen loading failure, as specified by Canvas `PropV2ErroPadrao`.
class LoadErrorScreen extends StatelessWidget {
  const LoadErrorScreen({
    required this.kind,
    required this.onAction,
    this.onBack,
    this.onFreeSpace,
    this.showAction = true,
    this.offlineMessage,
    super.key,
  });

  final LoadErrorKind kind;
  final VoidCallback onAction;
  final VoidCallback? onBack;
  final VoidCallback? onFreeSpace;
  final bool showAction;

  /// Replaces the offline text when the screen belongs to a specific course.
  final String? offlineMessage;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final (title, message, icon) = switch (kind) {
      LoadErrorKind.generic => (
        t.loadErrorGenericTitle,
        null,
        CanvasSymbols.error,
      ),
      LoadErrorKind.offline => (
        t.loadErrorOfflineTitle,
        offlineMessage ?? t.loadErrorOfflineMessage,
        CanvasSymbols.wifiOff,
      ),
      LoadErrorKind.noSpace => (
        t.loadErrorNoSpaceTitle,
        null,
        CanvasSymbols.storage,
      ),
      LoadErrorKind.unavailable => (
        t.loadErrorUnavailableTitle,
        null,
        CanvasSymbols.error,
      ),
      LoadErrorKind.notFound => (
        t.loadErrorNotFoundTitle,
        t.loadErrorNotFoundMessage,
        CanvasSymbols.searchOff,
      ),
      // A variante "motor" do erro padrão virou a genérica (T85-D0).
      LoadErrorKind.engine => (
        t.loadErrorGenericTitle,
        null,
        CanvasSymbols.error,
      ),
      LoadErrorKind.launch => (
        t.loadErrorLaunchTitle,
        null,
        CanvasSymbols.error,
      ),
      LoadErrorKind.launchAgain => (
        t.loadErrorLaunchAgainTitle,
        t.loadErrorLaunchAgainMessage,
        CanvasSymbols.error,
      ),
    };
    final freeSpace = kind == LoadErrorKind.noSpace ? onFreeSpace : null;
    final actionLabel = kind == LoadErrorKind.notFound
        ? t.loadErrorHome
        : t.loadErrorRetry;
    return Scaffold(
      key: LoadErrorKeys.screen,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  fill: 0,
                  weight: 300,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 24 / 16,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: !showAction
          ? null
          : ActionsFooter(
              stacked: true,
              children: [
                if (freeSpace != null)
                  _LoadErrorAction(
                    buttonKey: LoadErrorKeys.freeSpace,
                    onAction: freeSpace,
                    label: t.loadErrorFreeSpace,
                    outlined: false,
                  ),
                _LoadErrorAction(
                  buttonKey: LoadErrorKeys.action,
                  onAction: onAction,
                  label: actionLabel,
                  outlined: freeSpace != null,
                ),
                if (kind != LoadErrorKind.notFound && onBack != null)
                  OutlinedButton(
                    key: LoadErrorKeys.back,
                    onPressed: onBack,
                    child: Text(t.loadErrorBack),
                  ),
              ],
            ),
    );
  }
}

class _LoadErrorAction extends StatelessWidget {
  const _LoadErrorAction({
    required this.buttonKey,
    required this.onAction,
    required this.label,
    required this.outlined,
  });
  final Key buttonKey;
  final VoidCallback onAction;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) => BusyButton(
    buttonKey: buttonKey,
    label: label,
    onPressed: onAction,
    style: outlined ? BusyButtonStyle.outlined : BusyButtonStyle.filled,
  );
}
