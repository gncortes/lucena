import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../domain/models/featured.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';
import 'featured_labels.dart';

/// "E agora?" (o "Continuar" do fim da partida): aprender o final, ver finais
/// parecidos, mais finais do torneio e jogar de novo. [tournament] e
/// [tournamentFinals] (quantos finais ele tem) dão o subtítulo do torneio.
Future<void> showFeaturedNext(
  BuildContext context, {
  required FeaturedEndgame endgame,
  FeaturedTournament? tournament,
  int tournamentFinals = 0,
  VoidCallback? onAgain,
}) async {
  final language = Localizations.localeOf(context).languageCode;
  final lessonId = endgame.lessonId;
  String? lessonTitle;
  if (lessonId != null) {
    final texts = await context.read<EndgameLessonRepository>().texts(language);
    lessonTitle = texts.lessonTitle(lessonId);
  }
  if (!context.mounted) return;
  return showLucenaSheet<void>(
    context,
    sheetKey: FeaturedKeys.nextSheet,
    // Folha cinza: o cartão branco aparece sobre ela (canvas).
    color: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: _Next(
        endgame: endgame,
        tournament: tournament,
        tournamentFinals: tournamentFinals,
        lessonTitle: lessonTitle,
        onAgain: onAgain,
        // A tela de baixo é a que navega; a folha só fecha. Com push, o
        // "voltar" da aula e da lista leva de volta ao fim da partida.
        go: (route) {
          Navigator.of(sheetContext).pop();
          context.push(route);
        },
        close: () => Navigator.of(sheetContext).pop(),
      ),
    ),
  );
}

class _Next extends StatelessWidget {
  const _Next({
    required this.endgame,
    required this.tournament,
    required this.tournamentFinals,
    required this.lessonTitle,
    required this.onAgain,
    required this.go,
    required this.close,
  });

  final FeaturedEndgame endgame;
  final FeaturedTournament? tournament;
  final int tournamentFinals;
  final String? lessonTitle;
  final VoidCallback? onAgain;
  final void Function(String route) go;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final lesson = endgame.lessonId;
    final similar = endgame.similarCategory;
    final tournamentId = endgame.tournamentId;
    // Torneio com só este final não tem "mais finais": vai para a lista toda.
    final tournament = tournamentFinals > 1 ? this.tournament : null;
    final tournamentRoute = tournament == null ? null : tournamentId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.featuredNextTitle),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (lesson != null)
                        ListTile(
                          key: FeaturedKeys.nextLesson,
                          leading: const Icon(Icons.auto_stories_outlined),
                          title: Text(l10n.featuredNextLesson),
                          subtitle: lessonTitle == null
                              ? null
                              : Text(l10n.featuredNextLessonSub(lessonTitle!)),
                          onTap: () => go(Routes.endgameLesson(lesson)),
                        ),
                      if (similar != null)
                        ListTile(
                          key: FeaturedKeys.nextSimilar,
                          leading: const Icon(Icons.grid_view_outlined),
                          title: Text(l10n.featuredNextSimilar),
                          subtitle: Text(categoryName(l10n, similar)),
                          onTap: () => go(Routes.catalogCategory(similar)),
                        ),
                      ListTile(
                        key: FeaturedKeys.nextMore,
                        leading: Icon(
                          tournamentRoute == null
                              ? Icons.star_outline_rounded
                              : FeaturedLabels.originIcon(
                                  FeaturedOrigin.tournament,
                                ),
                        ),
                        title: Text(
                          tournamentRoute == null
                              ? l10n.featuredNextMoreAll
                              : l10n.featuredNextMore,
                        ),
                        subtitle: tournament == null
                            ? null
                            : Text(
                                l10n.featuredNextMoreSub(
                                  tournament.nameIn(language),
                                  tournamentFinals,
                                ),
                              ),
                        onTap: () => go(
                          tournamentRoute == null
                              ? Routes.featured
                              : Routes.featuredTournament(tournamentRoute),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAgain != null)
                  FilledButton.tonalIcon(
                    key: FeaturedKeys.nextAgain,
                    icon: const Icon(Icons.replay),
                    label: Text(l10n.featuredPlayAgain),
                    onPressed: () {
                      close();
                      onAgain!();
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
