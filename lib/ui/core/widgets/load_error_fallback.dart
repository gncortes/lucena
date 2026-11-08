import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'load_error.dart';

/// Safe even when the failing build is above the application's MaterialApp.
Widget buildLoadErrorFallback(FlutterErrorDetails details) =>
    const _LoadErrorFallback();

class _LoadErrorFallback extends StatelessWidget {
  const _LoadErrorFallback();

  @override
  Widget build(BuildContext context) {
    final locale = basicLocaleListResolution(
      WidgetsBinding.instance.platformDispatcher.locales,
      appSupportedLocales,
    );
    final view = View.maybeOf(context);
    final media =
        MediaQuery.maybeOf(context) ??
        (view == null ? const MediaQueryData() : MediaQueryData.fromView(view));
    // Supply only the dependencies of the error screen, never another app or
    // navigator. This also works before the application's localizations exist.
    return MediaQuery(
      data: media,
      child: Localizations(
        locale: locale,
        delegates: AppLocalizations.localizationsDelegates,
        child: Theme(
          data: AppTheme.light,
          child: LoadErrorScreen(
            kind: LoadErrorKind.generic,
            onAction: () {},
            showAction: false,
          ),
        ),
      ),
    );
  }
}
