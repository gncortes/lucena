import 'package:flutter/material.dart';

import '../../../domain/models/speedrun.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/l10n/l10n.dart';
import '../../journey/widgets/journey_ui.dart';

/// O nome de um speedrun: o degrau (`Degrau Maia 1000`) ou o material do
/// final em figurino.
class SpeedrunTitle extends StatelessWidget {
  const SpeedrunTitle(this.speedrun, {this.style, super.key});

  final Speedrun speedrun;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (speedrun.kind) {
      SpeedrunKind.rung => Text(
        l10n.speedrunRungTitle(
          opponentRefLabel(l10n, speedrun.stages.first.opponent),
        ),
        style: style,
      ),
      SpeedrunKind.ending => SubcategoryMaterialText(
        speedrun.stages.first.position.subcategory,
        style: style,
      ),
    };
  }
}

/// O que se faz no speedrun, numa linha.
String speedrunDescription(AppLocalizations l10n, Speedrun speedrun) =>
    switch (speedrun.kind) {
      SpeedrunKind.rung => l10n.speedrunRungDescription(speedrun.stages.length),
      SpeedrunKind.ending => l10n.speedrunEndingDescription(
        opponentRefLabel(l10n, speedrun.stages.first.opponent),
        opponentRefLabel(l10n, speedrun.stages.last.opponent),
      ),
    };
