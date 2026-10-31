import 'package:flutter/widgets.dart';

abstract final class TrainingEntryKeys {
  static const back = ValueKey('training-entry-back');
  static const account = ValueKey('training-entry-account');
  static const google = ValueKey('training-entry-google');
  static const email = ValueKey('training-entry-email');
  static const speech = ValueKey('training-entry-speech');
  static const loading = ValueKey('training-entry-loading');
  static const failure = ValueKey('training-entry-failure');
  static const retry = ValueKey('training-entry-retry');
  static const storage = ValueKey('training-entry-storage');
  static const offline = ValueKey('training-goals-offline');
  static const unpublished = ValueKey('training-unpublished');
}
