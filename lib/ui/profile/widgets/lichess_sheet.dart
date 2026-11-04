import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';
import '../../level/widgets/level_ui.dart';
import '../view_models/profile_account_cubit.dart';

/// A folha do Lichess conectado (canvas `PropV1LichessPerfil`): a conta, a
/// última leitura dos ratings, atualizar e desconectar.
Future<void> showLichessSheet(
  BuildContext context,
  ProfileAccountCubit cubit,
) => showLucenaSheet<void>(
  context,
  sheetKey: ProfileKeys.lichessSheet,
  builder: (context) => BlocProvider.value(
    value: cubit,
    child: const SafeArea(top: false, child: _LichessSheet()),
  ),
);

class _LichessSheet extends StatefulWidget {
  const _LichessSheet();

  @override
  State<_LichessSheet> createState() => _LichessSheetState();
}

class _LichessSheetState extends State<_LichessSheet> {
  // Os avisos de antes da folha abrir não aparecem nela.
  late final int _openedAt = context
      .read<ProfileAccountCubit>()
      .state
      .noticeCount;

  Future<void> _disconnect(BuildContext context) async {
    final navigator = Navigator.of(context);
    final cubit = context.read<ProfileAccountCubit>();
    await cubit.disconnectLichess();
    // Falhando, o aviso aparece e a folha fica, com o Lichess conectado.
    if (cubit.state.lichess == null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<ProfileAccountCubit>().state;
    final rating = state.lichess;
    // O aviso do Perfil (SnackBar) ficaria atrás da folha: ele vem aqui.
    final notice = state.noticeCount > _openedAt
        ? switch (state.notice) {
            ProfileNotice.failed => l10n.conPerfilFailed,
            ProfileNotice.lichessOffline => l10n.lichessRefreshFailed,
            null => null,
          }
        : null;
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.lichessSheetTitle, hint: l10n.conLichessText),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (rating != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppShape.large),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.insideCard),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link, color: colors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  rating.user,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                l10n.lichessReadAt(
                                  DateFormat.Md(locale)
                                      .format(rating.readAt.toLocal()),
                                ),
                                style: muted,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PlatformRatingsGrid(rating: rating),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.conLichessNote, style: muted),
                if (notice != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    key: ProfileKeys.lichessNotice,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error, color: colors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          notice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        ActionsFooter(
          margin: AppSpacing.xl,
          stacked: true,
          children: [
            // O carregando fica dentro do botão tocado (BusyButton).
            BusyButton(
              key: ProfileKeys.lichessRefresh,
              style: BusyButtonStyle.outlined,
              icon: Icons.refresh,
              label: l10n.lichessRefresh,
              onPressed: state.busy
                  ? null
                  : context.read<ProfileAccountCubit>().refreshLichess,
            ),
            BusyButton(
              key: ProfileKeys.lichessDisconnect,
              style: BusyButtonStyle.text,
              icon: Icons.link_off,
              label: l10n.lichessDisconnect,
              onPressed: state.busy ? null : () => _disconnect(context),
            ),
          ],
        ),
      ],
    );
  }
}
