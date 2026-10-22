import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/level_source.dart';
import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/tip_box.dart';
import '../view_models/level_cubit.dart';
import 'level_ui.dart';

/// "Informar o rating" (canvas `PropV1PerfilRating`): o número, de onde ele
/// é e a conversão para o Lucena.
class LevelRatingScreen extends StatefulWidget {
  const LevelRatingScreen({super.key});

  @override
  State<LevelRatingScreen> createState() => _LevelRatingScreenState();
}

class _LevelRatingScreenState extends State<LevelRatingScreen> {
  final _rating = TextEditingController();

  @override
  void initState() {
    super.initState();
    final saved = context.read<LevelCubit>().state.manualRating;
    if (saved != null) _rating.text = '$saved';
  }

  @override
  void dispose() {
    _rating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<LevelCubit>();
    return BlocBuilder<LevelCubit, LevelState>(
      builder: (context, state) {
        final typed = state.manualRating;
        final lucena = state.manualLucena;
        return Scaffold(
          key: LevelKeys.ratingScreen,
          appBar: LucenaAppBar(title: Text(l10n.levelManualAppBar)),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            children: [
              TextField(
                key: LevelKeys.ratingField,
                controller: _rating,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (text) => cubit.setManual(int.tryParse(text)),
                decoration: InputDecoration(
                  labelText: l10n.levelManualField,
                  helperText: l10n.levelManualHelp,
                  // Fora de 400 a 3000, a ajuda vira o erro.
                  errorText: typed != null && !state.manualValid
                      ? l10n.levelManualHelp
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.levelManualSource, style: context.cardTitle),
                      const SizedBox(height: AppSpacing.xs),
                      RadioGroup<RatingOrigin>(
                        groupValue: state.manualOrigin,
                        onChanged: (origin) {
                          if (origin != null) cubit.setManualOrigin(origin);
                        },
                        child: Column(
                          children: [
                            for (final origin in RatingOrigin.values)
                              _OriginRow(
                                key: LevelKeys.ratingSource(origin),
                                origin: origin,
                                label: origin.label(l10n),
                                selected: state.manualOrigin == origin,
                              ),
                          ],
                        ),
                      ),
                      if (typed != null && lucena != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.levelManualConverted(
                            typed,
                            state.manualOrigin.name,
                            lucena,
                            levelRung(context, state, lucena),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TipBox(text: l10n.levelManualTip),
            ],
          ),
          bottomNavigationBar: ActionsFooter(
            children: [
              FilledButton(
                key: LevelKeys.ratingUse,
                onPressed: lucena == null ? null : cubit.useManual,
                child: Text(l10n.levelUseRating),
              ),
            ],
          ),
        );
      },
    );
  }
}

extension on RatingOrigin {
  String label(AppLocalizations l10n) => switch (this) {
    RatingOrigin.lichess => l10n.levelSourceLichess,
    RatingOrigin.chesscom => l10n.levelSourceChess,
    RatingOrigin.fide => l10n.levelSourceFide,
    RatingOrigin.cbx => l10n.levelSourceCbx,
    RatingOrigin.unknown => l10n.levelSourceUnknown,
  };
}

/// Uma origem: linha de 44 dp com o rádio à esquerda (como no canvas).
class _OriginRow extends StatelessWidget {
  const _OriginRow({
    required this.origin,
    required this.label,
    required this.selected,
    super.key,
  });

  static const _height = 44.0;
  static const _radioDensity = VisualDensity(horizontal: -4, vertical: -4);

  final RatingOrigin origin;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final group = RadioGroup.maybeOf<RatingOrigin>(context);
    return InkWell(
      onTap: () => group?.onChanged(origin),
      child: SizedBox(
        height: _height,
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Radio<RatingOrigin>(
              value: origin,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: _radioDensity,
            ),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontWeight: selected ? FontWeight.w600 : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
