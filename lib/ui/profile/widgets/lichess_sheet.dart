import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
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

class _LichessSheet extends StatelessWidget {
  const _LichessSheet();

  Future<void> _disconnect(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<ProfileAccountCubit>().disconnectLichess();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<ProfileAccountCubit>().state;
    final rating = state.lichess;
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.lichessSheetTitle, hint: l10n.lichessSheetText),
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
                Text(l10n.lichessDisconnectNote, style: muted),
              ],
            ),
          ),
        ),
        ActionsFooter(
          margin: AppSpacing.xl,
          stacked: true,
          children: [
            OutlinedButton.icon(
              key: ProfileKeys.lichessRefresh,
              onPressed: state.busy
                  ? null
                  : context.read<ProfileAccountCubit>().refreshLichess,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.lichessRefresh),
            ),
            TextButton.icon(
              key: ProfileKeys.lichessDisconnect,
              onPressed: state.busy ? null : () => _disconnect(context),
              icon: const Icon(Icons.link_off),
              label: Text(l10n.lichessDisconnect),
            ),
          ],
        ),
      ],
    );
  }
}
