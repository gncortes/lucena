import 'package:flutter/material.dart';

import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_button.dart';
import '../../core/widgets/lucena_app_bar.dart';

class TrainingHelpScreen extends StatelessWidget {
  const TrainingHelpScreen({
    required this.onBack,
    required this.onTour,
    super.key,
  });
  final VoidCallback onBack, onTour;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final questions = [
      t.courseGuideFaq1Question,
      t.courseGuideFaq2Question,
      t.courseGuideFaq3Question,
      t.courseGuideFaq4Question,
      t.courseGuideFaq5Question,
      t.courseGuideFaq6Question,
    ];
    final answers = [
      t.courseGuideFaq1Answer,
      t.courseGuideFaq2Answer,
      t.courseGuideFaq3Answer,
      t.courseGuideFaq4Answer,
      t.courseGuideFaq5Answer,
      t.courseGuideFaq6Answer,
    ];
    return Scaffold(
      key: TrainingKeys.helpScreen,
      appBar: LucenaAppBar(
        title: Text(t.courseGuideHelpAction),
        leading: BackButton(key: TrainingKeys.helpBack, onPressed: onBack),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppShape.large),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  Text(
                    t.courseGuideHelpTourTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(t.courseGuideHelpTourBody),
                  FilledButton.icon(
                    key: TrainingKeys.helpTour,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(kButtonHeight),
                    ),
                    onPressed: onTour,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(t.courseGuideHelpTourAction),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppShape.large),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.courseGuideFaqTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (var i = 0; i < questions.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ExpansionTile(
                      key: TrainingKeys.faq(i + 1),
                      initiallyExpanded: i == 0,
                      maintainState: true,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        questions[i],
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(answers[i]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
