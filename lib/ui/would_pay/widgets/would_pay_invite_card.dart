import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../data/repositories/would_pay/would_pay_repository.dart';
import '../../../routing/routes.dart';
import '../../core/keys/would_pay_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../view_models/would_pay_cubit.dart';

/// O convite do "Você pagaria?" (E1.26) na lista de aulas, acima do "Sua
/// opinião". Uma vez só, depois da 2ª aula concluída; "Agora não" esconde
/// para sempre. Visível, traz o espaço de baixo ([bottomGap]).
class WouldPayInviteCard extends StatelessWidget {
  const WouldPayInviteCard({this.bottomGap = AppSpacing.lg, super.key});

  final double bottomGap;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => WouldPayInviteCubit(
      wouldPay: context.read<WouldPayRepository>(),
      school: context.read<SchoolProgressRepository>(),
      endgames: context.read<EndgameProgressRepository>(),
    )..load(),
    child: _InviteView(bottomGap: bottomGap),
  );
}

class _InviteView extends StatelessWidget {
  const _InviteView({required this.bottomGap});

  final double bottomGap;

  /// A altura do "Agora não" (40 no canvas `PropV1AnuncioConvite`).
  static const _textButtonHeight = 40.0;

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<WouldPayInviteCubit>();
    await context.push(Routes.wouldPay);
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = context.watch<WouldPayInviteCubit>().state;
    if (!visible) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Container(
        key: WouldPayKeys.invite,
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppShape.medium),
                  ),
                  child: Icon(
                    Icons.payments,
                    size: AppIconSize.standard,
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xs / 2,
                    children: [
                      Text(l10n.payInviteTitle, style: context.cardTitle),
                      Text(
                        l10n.payInviteText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            FilledButton.tonal(
              key: WouldPayKeys.inviteYes,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kButtonHeightCompact),
              ),
              onPressed: () => _open(context),
              child: Text(l10n.payInviteYes),
            ),
            TextButton(
              key: WouldPayKeys.inviteNo,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(_textButtonHeight),
              ),
              onPressed: context.read<WouldPayInviteCubit>().dismiss,
              child: Text(l10n.payInviteNo),
            ),
          ],
        ),
      ),
    );
  }
}
