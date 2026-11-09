import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/home_layout.dart';
import '../../../routing/routes.dart';
import '../../core/keys/all_modes_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../../core/motion/rota_que_abre.dart';
import '../../free_board/widgets/saved_game_sheet.dart';
import '../../home/widgets/home_path_ui.dart';
import '../../home/widgets/path_card.dart';

/// Todos os modos do app num lugar só, mesmo os que o jogador tirou do
/// destaque da tela inicial: aprender, jogar e ferramentas (H-PAR-01).
class AllModesScreen extends StatelessWidget {
  const AllModesScreen({super.key, this.hasBlindCheckpoint});

  final Future<bool> Function()? hasBlindCheckpoint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = _sections(l10n);
    var index = 0;
    return Scaffold(
      key: AllModesKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.allModesTitle)),
      body: ListView(
        key: const PageStorageKey('all-modes'),
        padding: scrollPadding(context, left: 16, right: 16),
        children: [
          for (final (title, items) in sections) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                // Os cartões entram um depois do outro.
                child: StaggeredEntrance(
                  index: index++,
                  child: _origem(
                    item.route,
                    PathCard(
                      key: AllModesKeys.item(item.id),
                      icon: item.icon,
                      title: item.title,
                      body: item.body,
                      onTap: () async {
                        if (item.id == 'freeBoard') {
                          await openFreeBoard(context, preserveOrigin: true);
                          return;
                        }
                        final resume =
                            item.id == 'blind' &&
                            (await hasBlindCheckpoint?.call() ?? false);
                        if (context.mounted) {
                          await context.push(
                            resume
                                ? '${Routes.blindEntry}?resume=1'
                                : item.route,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
      // Fixo embaixo: a lista rola por trás.
      bottomNavigationBar: ActionsFooter(
        children: [
          OutlinedButton.icon(
            key: AllModesKeys.chooseHome,
            onPressed: () => context.push(Routes.homeLayout),
            icon: const Icon(Icons.tune),
            label: Text(l10n.partidaModosChooseHome),
          ),
        ],
      ),
    );
  }
}

/// Um modo da lista: o que o cartão mostra e a rota que ele abre.
typedef _Mode = ({
  String id,
  IconData icon,
  String title,
  String body,
  String route,
});

/// Os modos de cada seção, na ordem em que aparecem.
List<(String, List<_Mode>)> _sections(AppLocalizations l10n) {
  ({String id, IconData icon, String title, String body, String route}) path(
    HomePath path,
    String body,
  ) => (
    id: path.name,
    icon: path.icon,
    title: path.title(l10n),
    body: body,
    route: path.route,
  );
  return [
    (
      l10n.allModesLearnSection,
      [
        (
          id: 'pilares',
          icon: Icons.auto_stories_outlined,
          title: l10n.trainingPilaresTitle,
          body: l10n.partidaModosPilaresBody,
          route: Routes.pilaresSale,
        ),
        (
          id: HomePath.stars.name,
          icon: HomePath.stars.icon,
          title: l10n.starChallengesTitle,
          body: l10n.homeShortcutStarsBody,
          route: HomePath.stars.route,
        ),
      ],
    ),
    (
      l10n.allModesPlaySection,
      [
        path(HomePath.journey, l10n.partidaModosJourneyBody),
        path(HomePath.train, l10n.partidaModosTrainBody),
        path(HomePath.speedrun, l10n.partidaModosSpeedrunBody),
        path(HomePath.race, l10n.allModesRaceBody),
        // Às cegas é uma modalidade da partida: escolhe-se o final e,
        // na configuração dele, "Às cegas".
        (
          id: 'blind',
          icon: Icons.record_voice_over_outlined,
          title: l10n.blindTitle,
          body: l10n.partidaModosBlindBody,
          route: Routes.blindEntry,
        ),
      ],
    ),
    (
      l10n.homeTools,
      [
        (
          id: 'freeBoard',
          icon: Icons.grid_on_outlined,
          title: l10n.freeBoardTitle,
          body: l10n.partidaModosFreeBoardBody,
          route: Routes.freeBoard,
        ),
        (
          id: 'custom',
          icon: Icons.edit_outlined,
          title: l10n.customPositionTitle,
          body: l10n.partidaModosCustomBody,
          route: Routes.customPosition,
        ),
      ],
    ),
  ];
}

/// H-ANI-04: a venda (entrada única) cresce do cartão que a abre.
Widget _origem(String route, Widget card) => route == Routes.pilaresSale
    ? OrigemQueAbre(id: 'venda', child: card)
    : card;
