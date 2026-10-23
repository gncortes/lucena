import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/use_cases/visible_lessons.dart';
import '../../../routing/routes.dart';
import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/viktor_conversation.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../view_models/level_cubit.dart';
import 'level_ui.dart';

/// "Seu nível" (canvas `PropV1PerfilNivel`): o teste, o Lichess, o Chess.com,
/// o rating informado ou "aprender do zero". Na primeira abertura, quem não
/// sabe jogar vai para as aulas e os outros para a tela inicial; pelo Perfil,
/// a tela volta para ele.
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> with WidgetsBindingObserver {
  // O app voltou do navegador; sem a volta do Lichess logo depois, a pessoa
  // desistiu do login.
  static const _returnGrace = Duration(seconds: 2);
  Timer? _returned;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _returned?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final cubit = context.read<LevelCubit>();
    if (!cubit.state.lichessBusy) return;
    _returned?.cancel();
    _returned = Timer(_returnGrace, cubit.cancelLichess);
  }

  void _back() {
    if (context.read<LevelCubit>().fromProfile) {
      context.pop();
    } else {
      // Volta para a pergunta do objetivo (o voltar do sistema fecharia o
      // app).
      context.go(Routes.goal);
    }
  }

  void _onFinished(LevelState state) {
    // O nível escolhido já está no perfil.
    context.read<ProfileCubit>().load();
    final fromProfile = context.read<LevelCubit>().fromProfile;
    if (fromProfile && !state.toSchool && state.choice != LevelChoice.zero) {
      // Fecha as telas ligadas e o próprio "Seu nível".
      final route = ModalRoute.of(context);
      Navigator.of(context).popUntil((each) => each == route);
      Navigator.of(context).pop();
      return;
    }
    // O iniciante vai direto para as aulas (a tela inicial fica embaixo).
    context.go(state.toSchool ? Routes.school : Routes.home);
  }

  Future<void> _continue(LevelState state) async {
    final cubit = context.read<LevelCubit>();
    switch (state.choice) {
      case LevelChoice.test:
        if (state.testPending) {
          await takeLevelTest(context, finish: false);
        } else {
          await cubit.finish();
        }
      case LevelChoice.lichess:
        final lichess = state.lichess;
        if (lichess == null) {
          await cubit.connectLichess();
        } else {
          await _open(Routes.levelLichess);
        }
      case LevelChoice.chess:
        await _open(Routes.levelChess);
      case LevelChoice.manual:
        await _open(Routes.levelRating);
      case LevelChoice.zero:
        await cubit.finish();
    }
  }

  Future<void> _open(String route) =>
      context.push(route, extra: context.read<LevelCubit>());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LevelCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<LevelCubit, LevelState>(
          listenWhen: (previous, current) =>
              current.finished && !previous.finished,
          listener: (context, state) => _onFinished(state),
        ),
        // A volta do Lichess (também com o app reaberto por ela).
        BlocListener<LevelCubit, LevelState>(
          listenWhen: (previous, current) =>
              previous.lichess == null && current.lichess != null,
          listener: (context, state) => _open(Routes.levelLichess),
        ),
        BlocListener<LevelCubit, LevelState>(
          listenWhen: (previous, current) =>
              current.errorCount != previous.errorCount &&
              current.error == LevelError.lichessOffline,
          listener: (context, state) =>
              showLucenaSnackBar(context, l10n.levelLichessOffline),
        ),
      ],
      child: BlocBuilder<LevelCubit, LevelState>(
        builder: (context, state) {
          if (!state.ready) return const Scaffold(key: LevelKeys.screen);
          final choice = state.choice;
          final placed = state.placed;
          Widget card(
            LevelChoice option,
            IconData icon,
            String title,
            String body,
          ) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ChoiceCard(
              key: LevelKeys.option(option),
              icon: icon,
              title: title,
              body: body,
              selected: choice == option,
              onTap: () => cubit.select(option),
            ),
          );
          return PopScope(
            canPop: cubit.fromProfile,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: Scaffold(
              key: LevelKeys.screen,
              appBar: LucenaAppBar(
                leading: BackButton(key: LevelKeys.back, onPressed: _back),
                title: Text(l10n.levelTitle),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ViktorConversation(
                      viktor: state.viktor,
                      speech: l10n.levelViktorSay,
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
                          card(
                            LevelChoice.test,
                            Icons.quiz,
                            l10n.levelTestTitle,
                            placed == null
                                ? l10n.levelTestBody
                                : l10n.levelStart(
                                    levelRung(context, state, placed),
                                  ),
                          ),
                          card(
                            LevelChoice.lichess,
                            Icons.link,
                            l10n.levelLichessTitle,
                            l10n.levelLichessText,
                          ),
                          card(
                            LevelChoice.chess,
                            Icons.link,
                            l10n.levelChessTitle,
                            l10n.levelChessText,
                          ),
                          card(
                            LevelChoice.manual,
                            Icons.trending_up,
                            l10n.levelManualTitle,
                            l10n.levelManualText,
                          ),
                          card(
                            LevelChoice.zero,
                            Icons.school,
                            l10n.levelZeroTitle,
                            // Com a Escola escondida, quem não sabe jogar cai
                            // na tela inicial: o texto não promete a Escola.
                            VisibleLessons.school
                                ? l10n.levelZeroText
                                : l10n.levelZeroTextHome,
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
                    key: LevelKeys.continueButton,
                    onPressed: state.lichessBusy
                        ? null
                        : () => _continue(state),
                    child: state.lichessBusy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.levelContinue),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
