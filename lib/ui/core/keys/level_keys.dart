import 'package:flutter/widgets.dart';

import '../../level/view_models/level_cubit.dart';

/// "Seu nível" e a conta opcional, que vêm depois do tour.
abstract final class LevelKeys {
  static const screen = Key('level.screen');
  static const viktor = Key('level.viktor');
  static const speech = Key('level.speech');
  static const next = Key('level.next');
  static const back = Key('level.back');

  /// Um dos três cartões.
  static Key option(LevelChoice choice) => Key('level.option.${choice.name}');
}

abstract final class AccountKeys {
  static const screen = Key('account.screen');
  static const close = Key('account.close');
  static const google = Key('account.google');
  static const email = Key('account.email');
  static const later = Key('account.later');
}
