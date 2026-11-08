import 'package:flutter/material.dart';

import '../../../domain/models/race.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import 'race_result_view.dart';

/// Todos os problemas da Corrida, em miniaturas (o "Ver os N" do resultado).
class RaceProblemsScreen extends StatelessWidget {
  const RaceProblemsScreen({
    required this.answers,
    required this.problems,
    super.key,
  });

  final List<RaceAnswer> answers;
  final List<RaceProblem> problems;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: RaceKeys.problemsScreen,
    appBar: LucenaAppBar(title: Text(context.l10n.raceProblemsTitle)),
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: scrollPadding(
          context,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
        ),
        children: [
          RaceProblemGrid(
            tiles: (size) => [
              for (final (index, answer) in answers.indexed)
                RaceProblemTile(
                  key: RaceKeys.problemTile(index),
                  size: size,
                  answer: answer,
                  problem: problems
                      .where((p) => p.id == answer.problemId)
                      .firstOrNull,
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
