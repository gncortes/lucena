import 'package:flutter/material.dart';

import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/canvas_symbols.dart';
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
        toolbarHeight: 64,
        title: Text(t.courseGuideHelpAction),
        leading: IconButton(
          key: TrainingKeys.helpBack,
          onPressed: onBack,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(CanvasSymbols.arrowBack),
        ),
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
                  Text(
                    t.courseGuideHelpTourBody,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(letterSpacing: 0),
                  ),
                  FilledButton.icon(
                    key: TrainingKeys.helpTour,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(kButtonHeight),
                    ),
                    onPressed: onTour,
                    icon: const Icon(CanvasSymbols.playArrow, fill: 1),
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
                spacing: 4,
                children: [
                  Text(
                    t.courseGuideFaqTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (var i = 0; i < questions.length; i++) ...[
                    Container(
                      decoration: i == 0
                          ? null
                          : BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                            ),
                      child: ExpansionTile(
                        key: TrainingKeys.faq(i + 1),
                        initiallyExpanded: i == 0,
                        maintainState: true,
                        minTileHeight: 48,
                        visualDensity: VisualDensity.standard,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 6),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          questions[i],
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize: 14,
                                height: 20 / 14,
                                letterSpacing: 0,
                              ),
                        ),
                        children: [
                          // Canvas summary margin-bottom -12 plus answer top 6.
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                answers[i],
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: 14,
                                      height: 20 / 14,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
