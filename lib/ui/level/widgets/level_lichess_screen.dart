import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/tip_box.dart';
import '../view_models/level_cubit.dart';
import 'level_ui.dart';

/// "Lichess conectado" (canvas `PropV1PerfilLichessConectado`): os ratings
/// lidos e "Usar esse rating". Com o rating provisório
/// (`PropV1PerfilLichessProvisorio`), o teste vem primeiro.
class LevelLichessScreen extends StatelessWidget {
  const LevelLichessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<LevelCubit>();
    return BlocConsumer<LevelCubit, LevelState>(
      // Recusou ou voltou sem autorizar: o aviso sai no passo Nível.
      listenWhen: (previous, current) =>
          current.errorCount != previous.errorCount &&
          current.error == LevelError.lichessCancelled,
      listener: (context, state) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final lichess = state.lichess;
        final rating = state.lichessRating;
        if (state.lichessOffline) {
          return KeyedSubtree(
            key: LevelKeys.lichessOfflineScreen,
            child: EntradaDaTela(
              id: 'PropV1AbEstLichessSemRede',
              child: LoadErrorScreen(
                kind: LoadErrorKind.offline,
                message: l10n.levelLichessNoNet,
                actionKey: LevelKeys.lichessRetry,
                backKey: LevelKeys.lichessOfflineBack,
                onAction: cubit.connectLichess,
                onBack: () {
                  cubit.dismissOffline();
                  Navigator.of(context).maybePop();
                },
              ),
            ),
          );
        }
        if (lichess == null || rating == null) {
          // Lendo o perfil depois da volta do navegador.
          return const Scaffold(
            key: LevelKeys.lichessScreen,
            body: SafeArea(child: SkeletonList()),
          );
        }
        final provisional = lichess.main!.provisional;
        return Scaffold(
          key: LevelKeys.lichessScreen,
          appBar: LucenaAppBar(title: Text(l10n.levelLichessConnectedTitle)),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  provisional
                      ? l10n.levelLichessProvisionalBack
                      : l10n.levelLichessBack,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PlatformFoundCard(
                title: l10n.levelConnectedAs(lichess.user),
                rating: lichess,
                text: provisional
                    ? l10n.levelProvisionalText
                    : levelStartsAt(context, state, lichess, rating),
              ),
              const SizedBox(height: AppSpacing.lg),
              TipBox(
                text: provisional
                    ? l10n.levelProvisionalTip(rating)
                    : l10n.levelLichessTip,
              ),
            ],
          ),
          bottomNavigationBar: ActionsFooter(
            stacked: true,
            children: provisional
                ? [
                    FilledButton(
                      key: LevelKeys.lichessTest,
                      onPressed: () => takeLevelTest(context, finish: true),
                      child: Text(l10n.levelTakeTest),
                    ),
                    TextButton(
                      key: LevelKeys.lichessUseDefault,
                      onPressed: cubit.useLichess,
                      child: Text(l10n.levelUseDefault(rating)),
                    ),
                  ]
                : [
                    FilledButton(
                      key: LevelKeys.lichessUse,
                      onPressed: cubit.useLichess,
                      child: Text(l10n.levelUseRating),
                    ),
                    const PreferTestButton(),
                  ],
          ),
        );
      },
    );
  }
}
