import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/rating_conversion.dart';
import '../../../routing/routes.dart';
import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/choice_card.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../level/view_models/level_cubit.dart';
import '../../level/widgets/level_ui.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../view_models/tour_cubit.dart';

/// O passo "Nível" do tour (canvas `PropV1AbEstNivel`): cinco cartões de
/// rádio. "Estou começando" vem marcado. Cada via grava o nível pelo
/// `LevelCubit` e o tour segue para a região.
class TourLevelStep extends StatelessWidget {
  const TourLevelStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LevelCubit>();
    return BlocConsumer<LevelCubit, LevelState>(
      listenWhen: (previous, current) => current.finished && !previous.finished,
      listener: (context, state) {
        // Fecha o Lichess/Chess.com/teste que estiverem por cima e segue.
        final route = ModalRoute.of(context);
        Navigator.of(context).popUntil((each) => each == route);
        cubit.acknowledged();
        unawaited(context.read<TourCubit>().next());
      },
      builder: (context, state) {
        if (!state.ready) return const SizedBox(height: 240);
        Widget card(
          LevelChoice option,
          String title,
          String body, {
          IconData? icon,
          VoidCallback? onTap,
        }) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ChoiceCard(
            key: LevelKeys.option(option),
            icon: icon,
            title: title,
            body: body,
            selected: state.choice == option,
            onTap: onTap ?? () => cubit.select(option),
          ),
        );
        final band = state.band;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(
                LevelChoice.zero,
                l10n.tourLevelZeroTitle,
                l10n.tourLevelZeroText,
                icon: Icons.school,
              ),
              card(
                LevelChoice.test,
                l10n.levelTestTitle,
                state.placed == null
                    ? l10n.levelTestBody
                    : l10n.levelStart(levelRung(context, state, state.placed!)),
                icon: Icons.quiz,
              ),
              card(
                LevelChoice.lichess,
                l10n.levelLichessTitle,
                l10n.levelLichessText,
                icon: Icons.link,
              ),
              card(
                LevelChoice.chess,
                l10n.levelChessTitle,
                l10n.levelChessText,
              ),
              card(
                LevelChoice.band,
                l10n.tourLevelBandTitle,
                band == null
                    ? l10n.tourLevelBandText
                    : l10n.tourLevelBandStart(
                        RatingConversion.startRung(band.rating),
                      ),
                icon: Icons.trending_up,
                onTap: () => _pickBand(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _pickBand(BuildContext context) async {
  final cubit = context.read<LevelCubit>();
  final picked = await showLucenaSheet<RatingLevel>(
    context,
    sheetKey: LevelKeys.bandSheet,
    builder: (_) => _BandSheet(initial: cubit.state.band),
  );
  if (picked != null) cubit.selectBand(picked);
}

/// "Continuar" do passo Nível: abre o que o cartão marcado pede ou termina.
class TourLevelFooter extends StatelessWidget {
  const TourLevelFooter({super.key});

  Future<void> _continue(BuildContext context, LevelState state) async {
    final cubit = context.read<LevelCubit>();
    switch (state.choice) {
      case LevelChoice.test:
        if (state.testPending) {
          await takeLevelTest(context, finish: false);
        } else {
          await cubit.finish();
        }
      case LevelChoice.lichess:
        if (state.lichess == null) {
          await cubit.connectLichess();
        } else {
          await context.push(Routes.levelLichess, extra: cubit);
        }
      case LevelChoice.chess:
        await context.push(Routes.levelChess, extra: cubit);
      case LevelChoice.band:
        if (state.band == null) {
          await _pickBand(context);
        } else {
          await cubit.finish();
        }
      case LevelChoice.zero:
        await cubit.finish();
      case LevelChoice.known || LevelChoice.manual:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LevelCubit>().state;
    return ActionsFooter(
      children: [
        FilledButton(
          key: LevelKeys.continueButton,
          onPressed: state.ready && !state.lichessBusy
              ? () => _continue(context, state)
              : null,
          child: state.lichessBusy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.levelContinue),
        ),
      ],
    );
  }
}

/// A folha "Rating aproximado" (canvas `CompFolhaEscolha`): quatro faixas e
/// "Confirmar". Só grava em Confirmar; o X e o voltar do sistema só fecham.
class _BandSheet extends StatefulWidget {
  const _BandSheet({required this.initial});

  final RatingLevel? initial;

  @override
  State<_BandSheet> createState() => _BandSheetState();
}

class _BandSheetState extends State<_BandSheet> {
  static const _bands = [
    RatingLevel.beginner,
    RatingLevel.casual,
    RatingLevel.intermediate,
    RatingLevel.advanced,
  ];

  late RatingLevel _selected = widget.initial ?? RatingLevel.casual;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tourBandTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.tourBandHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final band in _bands)
            InkWell(
              key: LevelKeys.bandOption(band),
              onTap: () => setState(() => _selected = band),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: Semantics(
                    selected: _selected == band,
                    inMutuallyExclusiveGroup: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                band.name(l10n),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                band.describe(l10n),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selected == band
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: AppIconSize.standard,
                          color: _selected == band
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ActionsFooter(
            children: [
              FilledButton(
                key: LevelKeys.bandConfirm,
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(l10n.tourBandConfirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
