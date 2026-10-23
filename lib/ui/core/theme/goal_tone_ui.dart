import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/endgame_position.dart';

/// O objetivo da posição visto como cor e ícone (`GoalStyle`).
extension PositionGoalTone on PositionGoal {
  GoalTone get tone => switch (this) {
    PositionGoal.win => GoalTone.win,
    PositionGoal.draw => GoalTone.draw,
  };
}
