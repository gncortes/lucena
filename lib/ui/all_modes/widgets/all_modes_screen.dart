import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/home_layout.dart';
import '../../../domain/models/rating_level.dart';
import '../../../routing/routes.dart';
import '../../core/keys/all_modes_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../../home/widgets/home_path_ui.dart';
import '../../home/widgets/path_card.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../school/widgets/lesson_finished.dart';

// O item do Lichess não é uma rota do app: abre o site.
const _lichess = 'lichess';

// O nível do jogador, se o perfil estiver à mão.
RatingLevel? _level(BuildContext context) {
  try {
    return context.select((ProfileCubit cubit) => cubit.state?.level);
  } on ProviderNotFoundException {
    return null;
  }
}

/// Todos os modos do app num lugar só, mesmo os que o jogador tirou do
/// destaque da tela inicial: aprender, jogar, ferramentas e o progresso.
class AllModesScreen extends StatelessWidget {
  const AllModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    ({String id, IconData icon, String title, String body, String route}) path(
      HomePath path,
    ) => (
      id: path.name,
      icon: path.icon,
      title: path.title(l10n),
      body: path.body(l10n, null),
      route: path.route,
    );
    final sections = [
      (
        l10n.allModesLearnSection,
        [
          path(HomePath.learn),
          (
            id: 'stars',
            icon: Icons.star_outline_rounded,
            title: l10n.starChallengesTitle,
            body: l10n.starChallengesBody,
            route: Routes.starChallenges,
          ),
          path(HomePath.forYou),
          path(HomePath.endgames),
        ],
      ),
      (
        l10n.allModesPlaySection,
        [
          path(HomePath.journey),
          path(HomePath.train),
          // Às cegas é uma modalidade da partida: escolhe-se o final e,
          // na configuração dele, "Às cegas".
          (
            id: 'blind',
            icon: Icons.record_voice_over_outlined,
            title: l10n.blindTitle,
            body: l10n.allModesBlindBody,
            route: Routes.catalog,
          ),
          // Contra pessoas: no Lichess, fora do app.
          (
            id: 'lichess',
            icon: Icons.public,
            title: l10n.lichessInviteTitle,
            body: l10n.lichessInviteBody,
            route: _lichess,
          ),
          (
            id: 'speedrun',
            icon: HomePath.speedrun.icon,
            title: HomePath.speedrun.title(l10n),
            body: l10n.allModesSpeedrunBody,
            route: Routes.speedruns,
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
            body: l10n.allModesFreeBoardBody,
            route: Routes.freeBoard,
          ),
          (
            id: 'custom',
            icon: Icons.edit_outlined,
            title: l10n.customPositionTitle,
            body: l10n.allModesCustomBody,
            route: Routes.customPosition,
          ),
        ],
      ),
      (
        l10n.allModesProgressSection,
        [
          (
            id: 'rating',
            icon: Icons.show_chart,
            title: l10n.ratingHistory,
            body: l10n.allModesRatingBody,
            route: Routes.rating,
          ),
          (
            id: 'achievements',
            icon: Icons.military_tech_outlined,
            title: l10n.achievementsTitle,
            body: l10n.allModesAchievementsBody,
            route: Routes.achievements,
          ),
        ],
      ),
    ];
    // Quem já joga começa por Jogar; o iniciante, por Aprender.
    final level = _level(context);
    if (level != null && level != RatingLevel.beginner) {
      sections.insert(0, sections.removeAt(1));
    }
    var index = 0;
    return Scaffold(
      key: AllModesKeys.screen,
      appBar: AppBar(title: Text(l10n.allModesTitle)),
      body: ListView(
        padding: scrollPadding(context, left: 16, right: 16),
        children: [
          for (final (title, items) in sections) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 16, 4, 8),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                // Os cartões entram um depois do outro.
                child: StaggeredEntrance(
                  index: index++,
                  child: PathCard(
                    key: AllModesKeys.item(item.id),
                    icon: item.icon,
                    title: item.title,
                    body: item.body,
                    onTap: () => item.route == _lichess
                        ? launchUrl(
                            LichessInvite.url,
                            mode: LaunchMode.externalApplication,
                          )
                        : context.go(item.route),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
