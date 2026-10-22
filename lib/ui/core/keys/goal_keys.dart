import 'package:flutter/widgets.dart';

import '../../../domain/models/goal_preference.dart';

/// "O que você quer fazer?" e a folha que troca o objetivo, no Perfil.
abstract final class GoalKeys {
  static const screen = Key('goal.screen');
  static const back = Key('goal.back');
  static const viktor = Key('goal.viktor');
  static const speech = Key('goal.speech');
  static const continueButton = Key('goal.continue');
  static const haveAccount = Key('goal.haveAccount');
  static const sheet = Key('goal.sheet');
  static const sheetSave = Key('goal.sheetSave');

  /// Um dos três cartões (na pergunta e na folha).
  static Key option(GoalPreference goal) => Key('goal.option.${goal.name}');
}
