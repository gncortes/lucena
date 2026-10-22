import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/visible_lessons.dart';
import '../../../routing/routes.dart';
import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/choice_card.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/viktor_conversation.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/rating_level_sheet.dart';
import '../view_models/level_cubit.dart';

/// "Seu nível" (canvas `PropV1LinkNivel`): o último passo da primeira
/// abertura. Quem não sabe jogar vai para as aulas; os outros, para a tela
/// inicial. O rating por conta do Lichess ou do Chess.com ainda não existe.
class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LevelCubit>();
    return BlocConsumer<LevelCubit, LevelState>(
      listenWhen: (previous, current) => current.finished && !previous.finished,
      listener: (context, state) {
        // A faixa escolhida já está no perfil.
        context.read<ProfileCubit>().load();
        // O iniciante vai direto para as aulas (a tela inicial fica embaixo).
        context.go(state.toSchool ? Routes.school : Routes.home);
      },
      builder: (context, state) {
        if (!state.ready) return const Scaffold(key: LevelKeys.screen);
        final choice = state.choice;
        // "A Jornada começa no …", com o degrau do teste ou da faixa marcada.
        String start() => l10n.levelStart(
          state.startCharacter?.name ??
              OpponentKind.maia.label(l10n, level: int.parse(state.startRung)),
        );
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.go(Routes.goal);
          },
          child: Scaffold(
            key: LevelKeys.screen,
            appBar: LucenaAppBar(
              // Volta para a pergunta do objetivo (o voltar do sistema fecharia o
              // app).
              leading: BackButton(
                key: LevelKeys.back,
                onPressed: () => context.go(Routes.goal),
              ),
              title: Text(l10n.levelTitle),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ViktorConversation(
                    viktor: state.viktor,
                    speech: state.texts.say('tour.level'),
                    viktorKey: LevelKeys.viktor,
                    speechKey: LevelKeys.speech,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ChoiceCard(
                          key: LevelKeys.option(LevelChoice.test),
                          icon: Icons.quiz,
                          title: l10n.levelTestTitle,
                          body: state.placed != null
                              ? start()
                              : l10n.levelTestBody,
                          selected: choice == LevelChoice.test,
                          onTap: () => _takeTest(context),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ChoiceCard(
                          key: LevelKeys.option(LevelChoice.band),
                          icon: Icons.trending_up,
                          title: l10n.levelBandTitle,
                          body: choice == LevelChoice.band
                              ? start()
                              : l10n.levelBandBody,
                          selected: choice == LevelChoice.band,
                          onTap: () => _pickBand(context),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ChoiceCard(
                          key: LevelKeys.option(LevelChoice.beginner),
                          icon: Icons.school,
                          title: l10n.levelBeginnerTitle,
                          // Com a Escola escondida, o iniciante cai na tela
                          // inicial: o texto não promete a Escola.
                          body: VisibleLessons.school
                              ? l10n.levelBeginnerBody
                              : l10n.levelBeginnerBodyHome,
                          selected: choice == LevelChoice.beginner,
                          onTap: () => cubit.setLevel(RatingLevel.beginner),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: ActionsFooter(
              children: [
                FilledButton(
                  key: LevelKeys.next,
                  onPressed: state.testPending
                      ? () => _takeTest(context)
                      : cubit.finish,
                  child: Text(l10n.tourNext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A folha das faixas (com confirmar); a faixa confirmada fica marcada.
Future<void> _pickBand(BuildContext context) async {
  final cubit = context.read<LevelCubit>();
  final level = await showRatingLevelSheet(
    context,
    selected: cubit.state.level,
  );
  if (level != null) await cubit.setLevel(level);
}

/// Abre o teste de nível. Usado o resultado, o cartão do teste fica marcado;
/// "Prefiro escolher minha faixa" lá dentro volta com a folha das faixas.
Future<void> _takeTest(BuildContext context) async {
  final cubit = context.read<LevelCubit>();
  final used = await context.push<bool>(Routes.placementFrom('tour'));
  if (used == true) {
    await cubit.usePlacement();
  } else if (used == false && context.mounted) {
    await _pickBand(context);
  }
}
