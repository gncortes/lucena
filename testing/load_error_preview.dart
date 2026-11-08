// Native evidence harness. Not an application release entrypoint.
import 'package:flutter/material.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';

void main() => runApp(const _Preview());

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  static const cases = [
    (LoadErrorKind.generic, true, false),
    (LoadErrorKind.offline, true, false),
    (LoadErrorKind.noSpace, true, true),
    (LoadErrorKind.unavailable, true, false),
    (LoadErrorKind.notFound, false, false),
    (LoadErrorKind.engine, true, false),
    (LoadErrorKind.launch, false, false),
    (LoadErrorKind.launchAgain, false, false),
    (LoadErrorKind.generic, false, false),
    (LoadErrorKind.noSpace, true, false),
  ];
  int index = 0;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: appSupportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: child!,
    ),
    home: LoadErrorScreen(
      kind: cases[index].$1,
      onAction: () => setState(() => index = (index + 1) % cases.length),
      onBack: cases[index].$2 ? () => setState(() => index = 0) : null,
      onFreeSpace: cases[index].$3 ? () => setState(() => index = 0) : null,
    ),
  );
}
