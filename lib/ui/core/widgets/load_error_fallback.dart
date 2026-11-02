import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'load_error.dart';

/// Safe even when the failing build is above the application's MaterialApp.
Widget buildLoadErrorFallback(FlutterErrorDetails details) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: appSupportedLocales,
  home: LoadErrorScreen(
    kind: LoadErrorKind.generic,
    onAction: () {},
    showAction: false,
  ),
);
