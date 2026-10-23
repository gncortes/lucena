import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/race/race_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/race_rules.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';

/// O que o jogador escolheu na folha "Aquecer antes?".
enum RaceOfferChoice { warm, skip }

/// Antes de uma partida, oferece o aquecimento com problemas do final do
/// desafio ([endgame], o nome dele; [theme], o tema na Corrida). Devolve
/// [RaceOfferChoice.skip] quando não deve oferecer (o jogador pediu para não
/// perguntar mais, ou o banco está vazio) ou quando ele fecha a folha.
Future<RaceOfferChoice> offerRaceWarmUp(
  BuildContext context, {
  required String opponent,
  required String endgame,
  RaceTheme? theme,
  Character? character,
}) async {
  final repository = context.read<RaceRepository>();
  if (!await repository.offersWarmUp()) return RaceOfferChoice.skip;
  final problems = RaceRules.warmUp(await repository.problems(), theme: theme);
  if (problems.isEmpty || !context.mounted) return RaceOfferChoice.skip;
  final choice = await showLucenaSheet<RaceOfferChoice>(
    context,
    sheetKey: RaceKeys.offerSheet,
    builder: (context) => _OfferSheet(
      opponent: opponent,
      endgame: endgame,
      character: character,
      problems: problems,
      repository: repository,
    ),
  );
  return choice ?? RaceOfferChoice.skip;
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({
    required this.opponent,
    required this.endgame,
    required this.character,
    required this.problems,
    required this.repository,
  });

  final String opponent;
  final String endgame;
  final Character? character;
  final List<RaceProblem> problems;
  final RaceRepository repository;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  static const _miniature = 60.0;

  bool _never = false;

  Future<void> _choose(RaceOfferChoice choice) async {
    if (_never) await widget.repository.setOffersWarmUp(value: false);
    if (mounted) Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final character = widget.character;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            leading: character == null
                ? null
                : CharacterAvatar(
                    character: character,
                    size: CharacterAvatar.player,
                  ),
            title: l10n.raceOfferTitle,
            hint: l10n.raceOfferAgainst(widget.endgame, widget.opponent),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.lg,
              children: [
                Text(
                  l10n.raceOfferBody(
                    widget.problems.length,
                    widget.endgame.toLowerCase(),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (index, problem) in widget.problems.indexed)
                      ExcludeSemantics(
                        child: PositionBoard(
                          key: RaceKeys.offerBoard(index),
                          fen: problem.fen,
                          size: _miniature,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          CheckboxListTile(
            key: RaceKeys.offerNever,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            value: _never,
            title: Text(l10n.raceOfferNever),
            subtitle: Text(l10n.raceOfferNeverHint),
            onChanged: (value) => setState(() => _never = value ?? false),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                SizedBox(
                  height: kButtonHeight,
                  child: FilledButton.icon(
                    key: RaceKeys.offerWarm,
                    icon: const Icon(Icons.local_fire_department),
                    label: Text(l10n.raceOfferWarm),
                    onPressed: () => _choose(RaceOfferChoice.warm),
                  ),
                ),
                SizedBox(
                  height: kButtonHeight,
                  child: OutlinedButton(
                    key: RaceKeys.offerSkip,
                    onPressed: () => _choose(RaceOfferChoice.skip),
                    child: Text(l10n.raceOfferSkip),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
