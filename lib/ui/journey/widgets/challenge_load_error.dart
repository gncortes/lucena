import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../../../domain/models/load_failure.dart';
import '../../../routing/routes.dart';
import '../../../config/failure_report.dart';
import '../../core/widgets/load_error.dart';

Widget challengeLoadError(
  BuildContext context,
  LoadFailure failure,
  VoidCallback retry,
) => LoadErrorScreen(
  kind: LoadErrorKind.fromFailure(failure),
  onAction: failure == LoadFailure.notFound
      ? () => context.go(Routes.home)
      : retry,
  onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
  onFreeSpace: Theme.of(context).platform != TargetPlatform.android
      ? null
      : () async {
          try {
            await const AndroidIntent(
              action: 'android.settings.INTERNAL_STORAGE_SETTINGS',
            ).launch();
          } on Object catch (error, stack) {
            reportHandledError(error, stack);
          }
        },
);
