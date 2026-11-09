import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../../data/repositories/account/account_invite_repository.dart';
import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/conclusion.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../account/widgets/account_invite_card.dart';
import '../../achievements/widgets/achievement_detail.dart';
import '../../achievements/widgets/achievement_toast.dart';
import '../../core/keys/conclusion_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/load_error.dart';
import '../../../domain/models/game_review.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/review/move_quality_ui.dart';
import '../../core/share/share_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/rating_value.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../core/widgets/versus_intro.dart';
import '../../free_board/view_models/game_reporter.dart';
import '../../free_board/widgets/report_panel.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../settings/widgets/about_screen.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../../domain/models/pace.dart';
import '../../core/pace/pace_ui.dart';
import '../../speedrun/widgets/speedrun_ui.dart';
import '../view_models/conclusion_cubit.dart';
import 'outcome_badge.dart';
import 'resign_learn_list.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/motion/casca_com_atraso.dart';
import '../../core/motion/entrada_em_faixas.dart';
import '../../core/motion/lucena_motion.dart';
import '../../core/motion/valor_que_anima.dart';
import '../../core/motion/barra_que_enche.dart';

/// A tela de conclusão (T51, frente B): o resultado sobre a posição final,
/// os dois jogadores frente a frente, as ações, o rating contando, o
/// comentário do adversário, as conquistas e, fixo embaixo, "Analisar a
/// partida". Ela substitui a partida na pilha: fechar volta para onde o
/// jogador estava antes de jogar.
class ConclusionScreen extends StatefulWidget {
  const ConclusionScreen({this.fresh = false, this.invite, super.key});

  /// A partida acabou agora: as conquistas novas avisam por cima, como no
  /// fim da partida. Reaberta (o app fechado na conclusão), não avisam de
  /// novo.
  final bool fresh;

  /// O convite da conta, uma vez por instalação, no fim de uma partida que
  /// acabou agora (sem ele, nunca convida).
  final AccountInviteRepository? invite;

  @override
  State<ConclusionScreen> createState() => _ConclusionScreenState();
}

class _ConclusionScreenState extends State<ConclusionScreen> {
  // O cartão que vira imagem ao compartilhar e, depois da análise rápida,
  // o resumo dela, logo abaixo.
  final _card = GlobalKey();
  final _analysis = GlobalKey();
  bool _inviteChecked = false;
  bool _inviteAvailable = false;

  // Sem conta e com a partida pronta, fora do meio de um speedrun.
  Future<void> _invite(ConclusionState state) async {
    final invite = widget.invite;
    final conclusion = state.conclusion;
    if (_inviteChecked || invite == null || !widget.fresh) return;
    if (!state.ready || conclusion == null) return;
    if (conclusion.run?.nextChallenge != null) return;
    _inviteChecked = true;
    if (context.read<AccountRepository>().current != null) return;
    if (!await invite.pending()) return;
    if (!mounted) return;
    setState(() => _inviteAvailable = true);
  }

  // O X do cartão vale como "Agora não": some e suspende por 7 dias
  // (H-CON-02).
  Future<void> _closeInvite() async {
    if (!_inviteAvailable) return;
    setState(() => _inviteAvailable = false);
    await widget.invite!.markShown();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _invite(context.read<ConclusionCubit>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ConclusionCubit>().state;
    final conclusion = state.conclusion;
    final language = Localizations.localeOf(context).languageCode;
    if (state.failed || state.missing) {
      return LoadErrorScreen(
        kind: state.missing ? LoadErrorKind.notFound : LoadErrorKind.generic,
        onAction: state.missing
            ? () => context.go(Routes.home)
            : context.read<ConclusionCubit>().reload,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(Routes.home),
      );
    }
    final scaffold = PopScope(
      canPop: conclusion?.run?.nextChallenge == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      child: Scaffold(
        key: ConclusionKeys.screen,
        appBar: LucenaAppBar(
          centerTitle: true,
          // O aviso de conquista cai dentro da faixa da AppBar, entre o X e
          // as ações, sem cobrir nenhum ícone (S3b).
          title:
              widget.fresh &&
                  conclusion != null &&
                  conclusion.achievements.isNotEmpty
              ? AchievementToasts(
                  achievements: conclusion.achievements,
                  characters: state.characters,
                  onTap: (achievement) => showAchievementDetail(
                    context,
                    achievement: achievement,
                    unlocked: conclusion.unlocked[achievement.id],
                    characters: state.characters,
                    speedrunId: conclusion.run?.speedrunId,
                  ),
                )
              : null,
          // O fim do speedrun e da Maratona abre por `go`, sem tela por baixo:
          // a seta leva à lista dos Speedruns, de onde o jogador veio.
          leading: _endsRun(conclusion)
              ? IconButton(
                  key: ConclusionKeys.back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const BackButtonIcon(),
                  onPressed: () => context.go(Routes.speedruns),
                )
              : IconButton(
                  key: ConclusionKeys.close,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _close(context),
                ),
          actions: [
            if (conclusion != null && _winNewGame(conclusion, state))
              IconButton(
                key: ConclusionKeys.appBarNewGame,
                tooltip: l10n.freeBoardNewGame,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.pushReplacement(state.setup!),
              ),
            if (conclusion != null)
              ShareIconButton(
                key: ConclusionKeys.share,
                boundary: _card,
                // A análise só entra pronta: rodando, ela fica fora da imagem
                // (nada de cartão pela metade).
                extra: [
                  if (state.review != null && !state.reviewing) _analysis,
                ],
                tooltip: l10n.conclusionShare,
                fileName: 'lucena-partida.png',
                footer: 'Lucena · ${l10n.homeTagline}',
                text: l10n.conclusionShareText(
                  _shareLine(l10n, conclusion),
                  AboutScreen.websiteFor(language).toString(),
                ),
              ),
          ],
        ),
        // Sem esqueleto à vista: a casca só aparece se o dado demora mais
        // que 0,3 s; o conteúdo entra em faixas (EntradaEmFaixas).
        body: !state.ready || conclusion == null
            ? (state.ready
                  ? const SizedBox.shrink()
                  : const CascaComAtraso(child: SkeletonList()))
            : _Body(
                state: state,
                conclusion: conclusion,
                card: _card,
                analysis: _analysis,
                onAccountInviteClose: _inviteAvailable ? _closeInvite : null,
              ),
      ),
    );
    return BlocListener<ConclusionCubit, ConclusionState>(
      listenWhen: (before, now) => !before.ready && now.ready,
      listener: (context, state) => _invite(state),
      child: scaffold,
    );
  }
}

bool _endsRun(Conclusion? conclusion) =>
    conclusion?.kind == ConclusionKind.speedrunEnd ||
    conclusion?.kind == ConclusionKind.marathonEnd;

// Entre etapas do Clássico, fecha no detalhe sem iniciar a próxima partida.
// A Maratona mantém a continuação própria; os demais resultados voltam.
void _close(BuildContext context) {
  final state = context.read<ConclusionCubit>().state;
  final conclusion = state.conclusion;
  final run = conclusion?.run;
  final next = run?.nextChallenge;
  if (run != null && next != null) {
    if (state.speedrun?.kind != SpeedrunKind.marathon) {
      final target = Routes.speedrun(run.speedrunId);
      final matches = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .matches;
      final previous = matches.length > 1 ? matches[matches.length - 2] : null;
      if (previous is ImperativeRouteMatch &&
          previous.matches.uri.path == Uri.parse(target).path) {
        context.pop();
      } else {
        context.go(target);
      }
      return;
    }
    context.pushReplacement(
      Routes.challengeGame(
        next,
        speedrunId: run.speedrunId,
        attemptId: run.attemptId,
        stage: run.nextStage,
        userTime: run.nextTime,
      ),
    );
    return;
  }
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.home);
  }
}

/// O título do cabeçalho: o resultado ou, no speedrun, a etapa.
String _title(AppLocalizations l10n, Conclusion conclusion) {
  final run = conclusion.run;
  return switch (conclusion.kind) {
    ConclusionKind.speedrunStage when run != null => l10n.conclusionStageWon(
      run.stage + 1,
      run.stageCount,
    ),
    ConclusionKind.speedrunLost when run != null => l10n.conclusionStageLost(
      run.stage + 1,
      run.stageCount,
    ),
    ConclusionKind.marathonLost when run != null => l10n.conclusionStageLost(
      run.stage + 1,
      run.stageCount,
    ),
    ConclusionKind.speedrunEnd => l10n.speedrunFinished,
    ConclusionKind.marathonEnd => l10n.conclusionMarathonDone,
    _ => switch (conclusion.result) {
      ConclusionResult.won => l10n.resultYouWon,
      ConclusionResult.lost => l10n.resultYouLost,
      ConclusionResult.draw => l10n.conclusionDraw,
    },
  };
}

/// A frase do resultado no texto de compartilhar: o título, com o tempo
/// total no fim do speedrun, terminando em pontuação.
String _shareLine(AppLocalizations l10n, Conclusion conclusion) {
  final title = _title(l10n, conclusion);
  final total = conclusion.run?.total;
  final line = total == null ? title : '$title: ${RunTimeFormat.format(total)}';
  if (RegExp(r'[.!?]$').hasMatch(line)) return line;
  // Vitória com exclamação; o resto, com ponto.
  return conclusion.result == ConclusionResult.won ? '$line!' : '$line.';
}

String _reason(AppLocalizations l10n, GameEndReason reason) => switch (reason) {
  GameEndReason.checkmate => l10n.freeBoardCheckmate,
  GameEndReason.stalemate => l10n.freeBoardStalemate,
  GameEndReason.insufficientMaterial => l10n.freeBoardInsufficientMaterial,
  GameEndReason.repetition => l10n.freeBoardRepetition,
  GameEndReason.fiftyMoves => l10n.freeBoardFiftyMoves,
  GameEndReason.timeout => l10n.freeBoardTimeout,
  GameEndReason.timeoutVsInsufficientMaterial =>
    l10n.freeBoardTimeoutVsInsufficientMaterial,
  GameEndReason.resign => l10n.gameResigned,
  GameEndReason.drawAgreed => l10n.freeBoardDrawAgreed,
};

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.conclusion,
    required this.card,
    required this.analysis,
    this.onAccountInviteClose,
  });

  final ConclusionState state;
  final Conclusion conclusion;
  final GlobalKey card;

  /// O cartão da análise rápida (entra na imagem depois de pronta).
  final GlobalKey analysis;

  /// Com o convite da conta na tela (sem conta, fora da suspensão): o X do
  /// cartão.
  final VoidCallback? onAccountInviteClose;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final actions = conclusion.actions;
    // As duas primeiras ações lado a lado, logo abaixo dos jogadores; as de
    // histórico viram links; "Analisar" fica fixo embaixo.
    final winFooter = _winNewGame(conclusion, state);
    final main = [
      for (final action in actions)
        if (!_links.contains(action) &&
            // Vitória: "Nova partida" vai para a barra do alto.
            !(winFooter && action == ConclusionAction.newGame) &&
            // Sem para onde ir (posição sem configuração): sem o botão.
            (action != ConclusionAction.playAgain || state.replay != null) &&
            (action != ConclusionAction.newGame || state.setup != null))
          action,
    ];
    final links = [
      for (final action in actions)
        if (_links.contains(action)) action,
    ];
    final opponent = state.opponent;
    final comment = state.comment;
    final run = conclusion.run;
    final celebrate =
        conclusion.result == ConclusionResult.won &&
        (conclusion.kind == ConclusionKind.speedrunEnd ||
            conclusion.kind == ConclusionKind.marathonEnd ||
            (run?.newRecord ?? false) ||
            conclusion.achievements.isNotEmpty);
    // O que vai na imagem de compartilhar: o resultado e os números, sem
    // botões.
    final outcome = _outcome(context, state, conclusion);
    final rating = conclusion.before != null && conclusion.after != null
        ? _Rating(conclusion: conclusion)
        : null;
    final numbers = _numberBlocks(context, state, conclusion);
    // A análise rápida: o botão, o tabuleiro andando e o resumo, no mesmo
    // cartão. Depois de pronta, ela entra na imagem de compartilhar.
    final quick =
        state.review != null ||
            (conclusion.gameId != null &&
                (conclusion.game?.moves.isNotEmpty ?? false))
        ? _QuickAnalysis(
            state: state,
            conclusion: conclusion,
            analysis: analysis,
          )
        : null;
    final speech = opponent != null && comment != null
        ? _OpponentComment(
            opponent: opponent,
            comment: comment,
            emotion: state.emotion,
          )
        : null;
    final sections = _sectionBlocks(
      context,
      state,
      conclusion,
      links,
      onAccountInviteClose,
      quick,
    );
    // As ações, fixas embaixo: fora da imagem de compartilhar.
    final actionsBar = main.isEmpty
        ? null
        : _ActionsBar(
            state: state,
            actions: main,
            seeAnalysisId: winFooter ? conclusion.gameId : null,
          );
    // O cabeçalho, o resultado e os números vão na imagem de compartilhar.
    final faixas = <FaixaDeEntrada>[
      FaixaDeEntrada('titulo', _Header(state: state, conclusion: conclusion)),
      if (outcome != null) FaixaDeEntrada('subtitulo', outcome),
      if (rating != null) FaixaDeEntrada('placar', rating, conta: true),
      FaixaDeEntrada('ritmo', _Spaced(numbers)),
    ];
    final sharedCount = faixas.length;
    faixas.addAll([
      if (speech != null) FaixaDeEntrada('viktor', speech),
      if (sections.isNotEmpty) FaixaDeEntrada('conquista', _Spaced(sections)),
      if (actionsBar != null) FaixaDeEntrada('botoes', actionsBar),
    ]);
    return Stack(
      children: [
        // S3b: o cabeçalho, o objetivo, o rating (contando), o ritmo, a fala,
        // a conquista e as ações entram em faixas escalonadas; reaberta,
        // tudo já pronto. A AppBar fica fixa o tempo todo.
        EntradaEmFaixas(
          id: 'conclusao-${conclusion.kind.name}-${conclusion.gameId}',
          faixas: faixas,
          montar: (parts) => _Layout(
            parts: parts,
            sharedCount: sharedCount,
            hasActionsBar: actionsBar != null,
            card: card,
          ),
        ),
        if (celebrate && !motion.disabled)
          const Positioned.fill(child: IgnorePointer(child: Celebration())),
      ],
    );
  }
}

/// Os números da partida: o modo, o tempo (quando há) e os lances às cegas.
List<Widget> _numberBlocks(
  BuildContext context,
  ConclusionState state,
  Conclusion conclusion,
) {
  final run = conclusion.run;
  return <Widget>[
    _Mode(state: state, conclusion: conclusion),
    // O tempo só quando há tempo a mostrar (perder a primeira etapa logo
    // de cara não tem tempo nenhum).
    if (run != null && _Run.spentOf(run) > Duration.zero)
      _Run(
        run: run,
        kind: conclusion.kind,
        speedrun: state.speedrun,
        characters: state.characters,
      ),
    if (conclusion.blindMoves case final moves?)
      Text(
        context.l10n.conclusionBlindMoves(moves),
        key: ConclusionKeys.blindMoves,
        textAlign: TextAlign.center,
      ),
  ];
}

/// Os blocos sob a fala: relatório, convite da conta, melhor linha, links e,
/// no fim, a análise rápida.
List<Widget> _sectionBlocks(
  BuildContext context,
  ConclusionState state,
  Conclusion conclusion,
  List<ConclusionAction> links,
  VoidCallback? onAccountInviteClose,
  Widget? quick,
) {
  return <Widget>[
    if (state.feedback.isNotEmpty)
      ReportPanel(
        report: GameReport(
          feedback: state.feedback,
          achievements: conclusion.achievements,
          unlocked: conclusion.unlocked,
          characters: state.characters,
        ),
      ),
    // O convite da conta logo abaixo das conquistas
    // (PropV2UxConclusaoConta): "Salve suas conquistas" quando houve
    // conquista nova; sem ela, "Salve seu progresso".
    if (onAccountInviteClose case final onClose?)
      AccountInviteCard(
        key: ConclusionKeys.accountInvite,
        title: conclusion.achievements.isNotEmpty
            ? context.l10n.conCartaoTitleWin
            : context.l10n.conCartaoTitleProgress,
        onClose: onClose,
      ),
    // A partida de novo com o Stockfish no lugar do jogador. Fora da imagem
    // de compartilhar.
    if (context.read<ConclusionCubit>().canPlayBestLine)
      _BestLine(state: state, conclusion: conclusion),
    // Perdeu desistindo: rever a partida e treinar o final (P9 B).
    if (conclusion.end?.reason == GameEndReason.resign &&
        conclusion.result == ConclusionResult.lost &&
        conclusion.run == null)
      ?ResignLearnList.maybe(
        gameId: (conclusion.game?.moves.isNotEmpty ?? false)
            ? conclusion.gameId
            : null,
        lesson: state.finalLesson,
      ),
    if (links.isNotEmpty) _Links(conclusion: conclusion, links: links),
    // A análise rápida anda ali mesmo, no fim da tela: sozinha na partida
    // curta, no toque na longa.
    ?quick,
  ];
}

/// A análise rápida: o botão, o tabuleiro andando e o resumo, no mesmo
/// cartão. Depois de pronta, ela entra na imagem de compartilhar.
class _QuickAnalysis extends StatelessWidget {
  const _QuickAnalysis({
    required this.state,
    required this.conclusion,
    required this.analysis,
  });

  final ConclusionState state;
  final Conclusion conclusion;
  final GlobalKey analysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: ConclusionKeys.analysisShared,
          child: RepaintBoundary(
            key: analysis,
            child: _Analysis(state: state, conclusion: conclusion),
          ),
        ),
        // Abaixo do cartão, fora do RepaintBoundary: a imagem de
        // compartilhar nunca mostra botão.
        if (state.review != null)
          if (conclusion.gameId case final gameId?) ...[
            const SizedBox(height: AppSpacing.sm),
            DetailedReviewButton(gameId: gameId),
          ],
      ],
    );
  }
}

/// A fala do adversário sobre a partida.
class _OpponentComment extends StatelessWidget {
  const _OpponentComment({
    required this.opponent,
    required this.comment,
    required this.emotion,
  });

  final Character opponent;
  final String comment;
  final Emotion emotion;

  @override
  Widget build(BuildContext context) {
    return TeacherSpeech(
      key: ConclusionKeys.comment,
      // O mesmo componente de fala do professor, com a ponta para cima
      // ligada ao avatar (S3b).
      speechContext: SpeechContext.teaching,
      teacher: opponent,
      text: comment,
      emotion: emotion,
      // Fala em cartão fora do tabuleiro: 56 (T73, D9; canvas 96d710e).
      avatarSize: CharacterAvatar.speech,
    );
  }
}

/// Os blocos em coluna, com o espaço entre eles.
class _Spaced extends StatelessWidget {
  const _Spaced(this.blocks);

  final Iterable<Widget> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, block) in blocks.indexed)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.lg),
            child: block,
          ),
      ],
    );
  }
}

/// A tela rolável: a imagem de compartilhar (cartão), os outros blocos e as
/// ações fixas embaixo.
class _Layout extends StatelessWidget {
  const _Layout({
    required this.parts,
    required this.sharedCount,
    required this.hasActionsBar,
    required this.card,
  });

  final List<Widget> parts;
  final int sharedCount;
  final bool hasActionsBar;
  final GlobalKey card;

  @override
  Widget build(BuildContext context) {
    final shared = parts.take(sharedCount);
    final rest = parts.skip(sharedCount).toList();
    final bottom = hasActionsBar ? rest.removeLast() : null;
    return Column(
      children: [
        Expanded(
          // Rolagem simples, não lista preguiçosa: todos os blocos
          // ficam montados, e compartilhar acha o cartão e a análise
          // mesmo com a tela rolada para longe deles.
          child: SingleChildScrollView(
            padding: scrollPadding(
              context,
              left: AppSpacing.screen,
              top: AppSpacing.sm,
              right: AppSpacing.screen,
              bottom: AppSpacing.xl,
            ),
            child: _Spaced([
              RepaintBoundary(
                key: card,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _Spaced(shared),
                ),
              ),
              ...rest,
            ]),
          ),
        ),
        ?bottom,
      ],
    );
  }
}

const _links = {ConclusionAction.ratingHistory, ConclusionAction.gamesHistory};

/// O resultado sobre a posição final desfocada e, embaixo, os dois jogadores
/// com o "VS" da entrada da partida.
class _Header extends StatelessWidget {
  const _Header({required this.state, required this.conclusion});

  final ConclusionState state;
  final Conclusion conclusion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final end = conclusion.end;
    final fen = conclusion.finalFen;
    final userSide = conclusion.userSide ?? Side.white;
    final winner = switch (conclusion.result) {
      ConclusionResult.won => userSide,
      ConclusionResult.lost => userSide.opposite,
      ConclusionResult.draw => null,
    };
    final nickname = context.select(
      (ProfileCubit cubit) => cubit.state?.nickname ?? '',
    );
    final opponent = state.opponent;
    final game = conclusion.game;
    final opponentName =
        opponent?.name ??
        (game == null
            ? ''
            : game.opponent.label(l10n, level: game.opponentLevel));
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShape.large),
      child: Stack(
        children: [
          // A posição final, desfocada, no tema do tabuleiro do jogador.
          if (fen != null) _BlurredBoard(fen: fen, userSide: userSide),
          Positioned.fill(
            child: ColoredBox(color: colors.surface.withValues(alpha: 0.72)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                OneLine(
                  _title(l10n, conclusion),
                  key: ConclusionKeys.title,
                  style: context.bigNumber,
                ),
                if (end != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _reason(l10n, end.reason),
                    key: ConclusionKeys.reason,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _Player(
                        key: ConclusionKeys.player,
                        avatar: ColoredBox(
                          color: colors.primary,
                          child: Icon(
                            Icons.person,
                            color: colors.onPrimary,
                            size: AppIconSize.large,
                          ),
                        ),
                        name: nickname.isEmpty
                            ? l10n.profileNicknameDefault
                            : nickname,
                        winner: winner == userSide,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: VersusSeal(),
                    ),
                    Expanded(
                      child: _Player(
                        key: ConclusionKeys.opponent,
                        avatar: opponent == null
                            ? ColoredBox(
                                color: AppColors.chessBlackColor,
                                child: const Icon(
                                  Icons.smart_toy_outlined,
                                  color: AppColors.chessWhiteColor,
                                  size: AppIconSize.large,
                                ),
                              )
                            : CharacterAvatar(
                                character: opponent,
                                size: CharacterAvatar.versus,
                              ),
                        name: opponentName,
                        winner: winner == userSide.opposite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A posição final, desfocada, no tema do tabuleiro do jogador.
class _BlurredBoard extends StatelessWidget {
  const _BlurredBoard({required this.fen, required this.userSide});

  final String fen;
  final Side userSide;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: LayoutBuilder(
          builder: (context, box) => OverflowBox(
            maxHeight: box.maxWidth,
            child: PositionBoard(
              fen: fen,
              size: box.maxWidth,
              orientation: userSide,
              radius: AppShape.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// Um jogador: o retrato e o nome; quem venceu tem a moldura colorida.
class _Player extends StatelessWidget {
  const _Player({
    required this.avatar,
    required this.name,
    required this.winner,
    super.key,
  });

  final Widget avatar;
  final String name;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final frame = Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppShape.medium),
        color: winner ? colors.primary : colors.outlineVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShape.small),
        child: avatar,
      ),
    );
    return Column(
      children: [
        // Quem venceu ganha o brilho girando em volta (sem animações, só a
        // moldura colorida).
        if (winner && !AppMotion.of(context).disabled)
          WinnerGlow(
            key: ConclusionKeys.winnerGlow,
            color: colors.primary,
            child: frame,
          )
        else
          frame,
        const SizedBox(height: AppSpacing.xs),
        OneLine(name, style: theme.textTheme.labelLarge),
      ],
    );
  }
}

/// As ações principais, fixas embaixo, uma embaixo da outra: a principal em
/// cima.
class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.state,
    required this.actions,
    this.seeAnalysisId,
  });

  final ConclusionState state;
  final List<ConclusionAction> actions;

  /// Vitória: o segundo botão é "Ver a análise" desta partida.
  final int? seeAnalysisId;

  @override
  Widget build(BuildContext context) {
    return ActionsFooter(
      stacked: true,
      children: [
        for (final (index, action) in actions.take(2).indexed)
          _ActionButton(action: action, primary: index == 0, state: state),
        if (seeAnalysisId case final id? when actions.length < 2)
          OutlinedButton.icon(
            key: ConclusionKeys.seeAnalysis,
            onPressed: () => context.push(Routes.game(id)),
            icon: const Icon(Icons.insights_rounded),
            label: OneLine(context.l10n.partidaConclusaoVerAnalise),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.primary,
    required this.state,
  });

  final ConclusionAction action;
  final bool primary;
  final ConclusionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, label) = switch (action) {
      ConclusionAction.playAgain => (
        Icons.replay_rounded,
        l10n.resultPlayAgain,
      ),
      ConclusionAction.newGame => (Icons.add_rounded, l10n.freeBoardNewGame),
      ConclusionAction.nextChallenge => (
        Icons.skip_next_rounded,
        l10n.resultNextChallenge,
      ),
      ConclusionAction.nextStage => (
        Icons.skip_next_rounded,
        l10n.speedrunContinue,
      ),
      ConclusionAction.retry => (Icons.replay_rounded, l10n.speedrunRetry),
      ConclusionAction.summary => (
        Icons.timer_outlined,
        l10n.conclusionSummary,
      ),
      ConclusionAction.speedruns => (
        Icons.list_rounded,
        l10n.conclusionSpeedruns,
      ),
      _ => (Icons.arrow_forward_rounded, ''),
    };
    final onPressed = _onPressed(context);
    final child = OneLine(label);
    return primary
        ? FilledButton.icon(
            key: ConclusionKeys.action(action),
            onPressed: onPressed,
            icon: Icon(icon),
            label: child,
          )
        : OutlinedButton.icon(
            key: ConclusionKeys.action(action),
            onPressed: onPressed,
            icon: Icon(icon),
            label: child,
          );
  }

  VoidCallback? _onPressed(BuildContext context) {
    final conclusion = state.conclusion!;
    final run = conclusion.run;
    switch (action) {
      case ConclusionAction.playAgain:
        final replay = state.replay;
        return replay == null ? null : () => context.pushReplacement(replay);
      case ConclusionAction.newGame:
        final setup = state.setup;
        return setup == null ? null : () => context.pushReplacement(setup);
      case ConclusionAction.nextChallenge:
        final next = conclusion.next;
        if (next == null) return null;
        // O mesmo ritmo da partida que acabou.
        final time = conclusion.game?.userTime;
        return () => context.pushReplacement(
          Routes.challengeGame(time == null ? next : next.copyWith(time: time)),
        );
      case ConclusionAction.nextStage:
        final challenge = run?.nextChallenge;
        if (run == null || challenge == null) return null;
        return () => context.pushReplacement(
          Routes.challengeGame(
            challenge,
            speedrunId: run.speedrunId,
            attemptId: run.attemptId,
            stage: run.nextStage,
            userTime: run.nextTime,
          ),
        );
      case ConclusionAction.retry:
        if (run == null) return null;
        return () async {
          final route = await context.read<ConclusionCubit>().retry();
          if (route != null && context.mounted) {
            context.pushReplacement(route);
          }
        };
      case ConclusionAction.summary:
        if (run == null) return null;
        return () =>
            context.push(Routes.speedrunAttempt(run.speedrunId, run.attemptId));
      case ConclusionAction.speedruns:
        // A lista dos speedruns, de onde o jogador veio, para escolher
        // outro.
        return () => context.go(Routes.speedruns);
      case _:
        return null;
    }
  }
}

/// Qual foi a partida: no speedrun e na Maratona, o nome; e o ritmo, com o
/// ícone da categoria (ou "Sem relógio").
class _Mode extends StatelessWidget {
  const _Mode({required this.state, required this.conclusion});

  final ConclusionState state;
  final Conclusion conclusion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final speedrun = state.speedrun;
    final time = speedrun?.time ?? conclusion.game?.userTime;
    final pace = time == null ? null : PaceCategory.of(time);
    return Card(
      key: ConclusionKeys.mode,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                pace == null ? Icons.timer_off_outlined : paceIcon(pace),
                color: colors.onPrimaryContainer,
                size: AppIconSize.standard,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speedrun == null
                        ? l10n.conclusionPace
                        : speedrunName(l10n, state.characters, speedrun),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    time == null
                        ? l10n.challengeNoClock
                        : paceLabel(l10n, time),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O rating contando do antigo até o novo.
class _Rating extends StatelessWidget {
  const _Rating({required this.conclusion});

  final Conclusion conclusion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final before = conclusion.before!.rating;
    final after = conclusion.after!.rating;
    return Card(
      key: ConclusionKeys.rating,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Row(
          children: [
            Icon(Icons.trending_up_rounded, color: colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.reportRatingLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            // O rating conta do antigo ao novo quando os números entram
            // (H-ANI-18); reaberta ou sem animações, já no valor novo.
            ValorQueAnima(
              valor: 1,
              duracao: AppMotion.celebrate,
              builder: (context, t) => RatingValue(
                rating: (before + (after - before) * t).round(),
                change: ((after - before) * t).round(),
                up: after >= before,
                valueKey: ConclusionKeys.ratingValue,
                changeKey: ConclusionKeys.ratingDelta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// No speedrun e na Maratona: o tempo da etapa, o total e o recorde; no fim,
/// o tempo de cada etapa com a melhor e a pior marcadas.
class _Run extends StatefulWidget {
  const _Run({
    required this.run,
    required this.kind,
    this.speedrun,
    this.characters = const [],
  });

  final ConclusionRun run;
  final ConclusionKind kind;

  /// O tempo de relógio gasto até aqui (o que o jogador viu passar).
  static Duration spentOf(ConclusionRun run) => run.spentSoFar;

  /// O speedrun e os personagens: o nome de quem foi enfrentado em cada etapa.
  final Speedrun? speedrun;
  final List<Character> characters;

  @override
  State<_Run> createState() => _RunState();
}

class _RunState extends State<_Run> {
  // O tempo contra cada adversário aparece só ao pedir.
  bool _details = false;

  ConclusionRun get run => widget.run;
  bool get _lost =>
      kind == ConclusionKind.speedrunLost ||
      kind == ConclusionKind.marathonLost;
  ConclusionKind get kind => widget.kind;
  Speedrun? get speedrun => widget.speedrun;
  List<Character> get characters => widget.characters;

  // Contra quem foi a etapa [index]: o personagem ou "Etapa N de M".
  String _opponentOf(BuildContext context, int index) {
    final l10n = context.l10n;
    final stages = speedrun?.stages ?? const <Challenge>[];
    if (index >= stages.length) {
      return l10n.speedrunStageOf(index + 1, run.stageCount);
    }
    // Contra um só adversário (o degrau), o que muda é o final.
    if (stages.map((stage) => stage.opponent).toSet().length == 1) {
      return endgameName(l10n, stages[index].position.subcategory);
    }
    final opponent = stages[index].opponent;
    if (opponent.kind == OpponentKind.stockfish) {
      return Character.stockfish.name;
    }
    return characters.forLevel(opponent.level)?.name ??
        opponent.kind.label(l10n, level: opponent.level);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    String time(Duration value) => RunTimeFormat.format(value);
    final ended =
        kind == ConclusionKind.speedrunEnd ||
        kind == ConclusionKind.marathonEnd;
    // O que conta é o tempo gasto: a soma das etapas jogadas até aqui.
    // As etapas jogadas, com o tempo de relógio de cada uma.
    final played = [
      for (final (index, time) in run.spent.take(run.stage + 1).indexed)
        if (time > Duration.zero) (index, time),
    ];
    final stageTime = run.stage < run.spent.length
        ? run.spent[run.stage]
        : Duration.zero;
    final spent = _Run.spentOf(run);
    final times = [for (final (_, time) in played) time];
    final best = times.length > 1
        ? times.reduce((a, b) => a < b ? a : b)
        : null;
    final longest = times.isEmpty
        ? Duration.zero
        : times.reduce((a, b) => a > b ? a : b);
    final record = run.previousBest;
    // Na Maratona o que conta é o tempo que sobrou no banco, o mesmo valor
    // do resumo; nas demais, o tempo gasto.
    final bankLeft = kind == ConclusionKind.marathonEnd ? run.bankLeft : null;
    return Card(
      key: ConclusionKeys.run,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Perdeu a etapa: o tempo grande não diz nada (o relógio acabou ou
            // a partida se perdeu); fica só o detalhe, para quem quiser.
            if (!_lost) ...[
              Text(
                bankLeft != null
                    ? l10n.marathonLeft
                    : ended
                    ? l10n.conclusionTotalTime
                    : l10n.conclusionTotalSoFar,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                bankLeft != null ? RunTimeFormat.clock(bankLeft) : time(spent),
                key: ConclusionKeys.total,
                textDirection: bankLeft != null ? TextDirection.ltr : null,
                textAlign: TextAlign.center,
                style: context.bigNumber?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            // A etapa que acabou de ser jogada e, no fim, o recorde de antes.
            if (!ended && !_lost && stageTime > Duration.zero)
              Text(
                '${l10n.conclusionStageTime}: ${time(stageTime)}',
                key: ConclusionKeys.stageTime,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            if (ended && record != null && !run.newRecord)
              Text(
                '${l10n.speedrunBest}: ${time(record)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            if (played.length > 1 || (_lost && played.isNotEmpty)) ...[
              if (!_lost) const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton.icon(
                  key: ConclusionKeys.runDetails,
                  onPressed: () => setState(() => _details = !_details),
                  icon: Icon(
                    _details
                        ? Icons.expand_less_rounded
                        : Icons.bar_chart_rounded,
                  ),
                  label: Text(
                    _details
                        ? l10n.conclusionHideDetails
                        : l10n.conclusionDetails,
                  ),
                ),
              ),
              if (_details)
                for (final (index, spent) in played)
                  // As etapas entram uma depois da outra.
                  StaggeredEntrance(
                    index: index,
                    child: _StageRow(
                      number: index + 1,
                      name: _opponentOf(context, index),
                      time: time(spent),
                      share: longest == Duration.zero
                          ? 0
                          : spent.inMilliseconds / longest.inMilliseconds,
                      fastest: spent == best,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Uma etapa no fim do speedrun: o número, contra quem, uma barra do tempo
/// (proporcional à etapa mais longa) e o tempo; a mais rápida em destaque.
class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.number,
    required this.name,
    required this.time,
    required this.share,
    required this.fastest,
  });

  final int number;
  final String name;
  final String time;
  final double share;
  final bool fastest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = fastest
        ? ChangeColors.of(context, up: true)
        : colors.primary;
    return Padding(
      key: ConclusionKeys.stage(number - 1),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(color: accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (fastest) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppShape.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.leaderboard_rounded,
                              size: AppIconSize.small,
                              color: accent,
                            ),
                            Text(
                              l10n.conclusionFastest,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // A barra do tempo, enchendo ao entrar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppShape.full),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: colors.surfaceContainerHighest),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: share),
                          duration: AppMotion.of(context).screen,
                          curve: AppMotion.enter,
                          builder: (context, value, _) => FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: value.clamp(0.0, 1.0),
                            child: ColoredBox(color: accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            time,
            style: theme.textTheme.labelLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Os atalhos de histórico e de resumo, como uma lista de links.
class _Links extends StatelessWidget {
  const _Links({required this.conclusion, required this.links});

  final Conclusion conclusion;
  final List<ConclusionAction> links;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, action) in links.indexed) ...[
            if (index > 0) const Divider(),
            ListTile(
              key: ConclusionKeys.action(action),
              leading: Icon(switch (action) {
                ConclusionAction.ratingHistory => Icons.show_chart_rounded,
                _ => Icons.history_rounded,
              }),
              title: Text(switch (action) {
                ConclusionAction.ratingHistory => l10n.conclusionRatingHistory,
                _ => l10n.statsGamesTitle,
              }),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(switch (action) {
                ConclusionAction.ratingHistory => Routes.ratingAt(
                  game: conclusion.gameId,
                ),
                _ => Routes.ratingAt(game: conclusion.gameId),
              }),
            ),
          ],
        ],
      ),
    );
  }
}

/// O tabuleiro da análise rápida: a posição depois do último lance avaliado,
/// com ele em destaque.
class _ReviewBoard extends StatelessWidget {
  const _ReviewBoard({required this.state, required this.size});

  final ConclusionState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final board = state.reviewBoard;
    return PositionBoard(
      key: ConclusionKeys.reviewBoard,
      fen: board.position.fen,
      size: size,
      orientation: state.conclusion!.userSide,
      lastMove: board.last,
    );
  }
}

/// A análise rápida num cartão só, que muda por dentro: o convite; o
/// tabuleiro com os lances andando enquanto o Stockfish avalia; e, pronta,
/// a precisão num anel e os lances do jogador em quadradinhos. O cartão
/// muda de altura suavemente e o conteúdo troca com um esmaecer.
class _Analysis extends StatelessWidget {
  const _Analysis({required this.state, required this.conclusion});

  final ConclusionState state;
  final Conclusion conclusion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final motion = AppMotion.of(context);
    final review = state.review;
    // Pronta a análise, o cartão encolhe para o resumo, suavemente.
    Widget content(double board) {
      if (review != null) {
        return _AnalysisSummary(
          key: const ValueKey('summary'),
          review: review,
          conclusion: conclusion,
        );
      }
      if (state.reviewing) {
        return _AnalysisRunning(
          key: const ValueKey('running'),
          state: state,
          board: board,
        );
      }
      return const _AnalysisInvite(key: ValueKey('invite'));
    }

    return Card(
      key: ConclusionKeys.quickReview,
      color: colors.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: review == null && !state.reviewing
            ? () => context.read<ConclusionCubit>().quickReview()
            : null,
        // Movimento reduzido: sem AnimatedSize (com duração zero ele se
        // remarca dentro do próprio layout quando a análise chega).
        child: _TamanhoQueAcompanha(
          duracao: motion.component,
          child: LayoutBuilder(
            builder: (context, box) {
              final board = math.min(
                box.maxWidth - 2 * AppSpacing.insideCard,
                280.0,
              );
              final child = content(board);
              return AnimatedSwitcher(
                duration: motion.component,
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: Padding(
                  key: child.key,
                  padding: const EdgeInsets.all(AppSpacing.insideCard),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// [AnimatedSize] quando há movimento; com duração zero, o filho direto.
class _TamanhoQueAcompanha extends StatelessWidget {
  const _TamanhoQueAcompanha({required this.duracao, required this.child});

  final Duration duracao;
  final Widget child;

  @override
  Widget build(BuildContext context) => duracao == Duration.zero
      ? child
      : AnimatedSize(
          duration: duracao,
          curve: AppMotion.move,
          alignment: Alignment.topCenter,
          child: child,
        );
}

/// O título do cartão: o raio e "Análise rápida", com a linha de baixo.
class _AnalysisTitle extends StatelessWidget {
  const _AnalysisTitle({required this.subtitle, this.trailing});

  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSecondaryContainer;
    // Altura mínima, não fixa: com letra grande, a linha de baixo quebra.
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: _AnalysisRunning.titleHeight,
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: ink),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.conclusionQuickReview,
                  style: theme.textTheme.titleSmall?.copyWith(color: ink),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _AnalysisInvite extends StatelessWidget {
  const _AnalysisInvite({super.key});

  @override
  Widget build(BuildContext context) => _AnalysisTitle(
    subtitle: context.l10n.conclusionQuickReviewHint,
    trailing: Icon(
      Icons.chevron_right_rounded,
      color: Theme.of(context).colorScheme.onSecondaryContainer,
    ),
  );
}

class _AnalysisRunning extends StatelessWidget {
  const _AnalysisRunning({required this.state, required this.board, super.key});

  final ConclusionState state;

  /// O lado do tabuleiro.
  final double board;

  static const titleHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final total = state.conclusion?.game?.moves.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnalysisTitle(
          subtitle: context.l10n.reviewRunning(state.reviewDone, total),
        ),
        const SizedBox(height: AppSpacing.md),
        // Os lances andando no tabuleiro, junto com a análise.
        Center(
          child: _ReviewBoard(state: state, size: board),
        ),
        const SizedBox(height: AppSpacing.md),
        BarraQueEnche(valor: total == 0 ? 0 : state.reviewDone / total),
      ],
    );
  }
}

/// O resumo pronto: a precisão do jogador num anel que enche e os lances
/// dele por qualidade, em quadradinhos.
class _AnalysisSummary extends StatelessWidget {
  const _AnalysisSummary({
    required this.review,
    required this.conclusion,
    super.key,
  });

  final GameReview review;
  final Conclusion conclusion;

  /// As qualidades da grade, das boas para as ruins (três por linha).
  static const _shown = [
    MoveQuality.best,
    MoveQuality.excellent,
    MoveQuality.good,
    MoveQuality.inaccuracy,
    MoveQuality.mistake,
    MoveQuality.blunder,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onSecondaryContainer;
    final locale = Localizations.localeOf(context).toString();
    final userWhite = (conclusion.userSide ?? Side.white) == Side.white;
    final fen = conclusion.game?.startFen ?? '';
    final firstIsWhite = fen.split(' ').elementAtOrNull(1) != 'b';
    final counts = review.counts(
      white: userWhite == firstIsWhite,
      firstIsWhite: firstIsWhite,
    );
    final mine = userWhite ? review.whiteAccuracy : review.blackAccuracy;
    Widget tile(MoveQuality quality) => Expanded(
      child: Container(
        key: ConclusionKeys.quality(quality.name),
        margin: const EdgeInsets.all(AppSpacing.xs),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppShape.medium),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MoveQualityBadge(quality, size: 22),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${counts[quality] ?? 0}',
                  style: context.cardTitle?.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              quality.label(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      key: ConclusionKeys.review,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Recuado como os quadradinhos de baixo (que têm margem): as bordas
        // alinham.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              // O quadrado da precisão, sempre todo azul; o número conta até o
              // valor.
              // H-ANI-18: o número conta pelo kit (reduzido: valor final).
              ValorQueAnima(
                valor: (mine ?? 0) / 100,
                duracao: LucenaMotion.numeroConta,
                builder: (context, value) => Container(
                  width: 76,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(AppShape.small),
                  ),
                  child: Text(
                    mine == null
                        ? '–'
                        : '${formatAccuracy(value * 100, locale)}%',
                    key: ConclusionKeys.accuracy,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reviewAccuracy,
                      style: theme.textTheme.titleSmall?.copyWith(color: ink),
                    ),
                    Text(
                      l10n.conclusionReviewTitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final row in [_shown.take(3), _shown.skip(3)])
          Row(children: [for (final quality in row) tile(quality)]),
      ],
    );
  }
}

/// "Ver a melhor linha": a partida de novo desde a posição de início, com o
/// Stockfish no lugar do jogador contra o mesmo adversário. Ao abrir, os
/// lances andam sozinhos no tabuleiro conforme chegam; pronta, dá para
/// voltar e avançar. Embaixo, o aviso de que foi rápido e o caminho para a
/// análise detalhada.
class _BestLine extends StatefulWidget {
  const _BestLine({required this.state, required this.conclusion});

  final ConclusionState state;
  final Conclusion conclusion;

  @override
  State<_BestLine> createState() => _BestLineState();
}

class _BestLineState extends State<_BestLine> {
  bool _open = false;

  void _toggle() {
    setState(() => _open = !_open);
    // A primeira vez que abre, a linha começa a ser jogada.
    if (_open) context.read<ConclusionCubit>().playBestLine();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = widget.state;
    final cubit = context.read<ConclusionCubit>();
    final line = state.bestLine;
    final ply = state.bestPly;
    final running = state.bestLineRunning;
    final game = widget.conclusion.game!;
    // A posição depois do lance mostrado e o nome dele (SAN), do estado.
    final (:position, :last, :san) = state.bestBoard;
    final opponentName =
        state.opponent?.name ??
        game.opponent.label(l10n, level: game.opponentLevel);
    final gameId = widget.conclusion.gameId;
    // Um Material próprio: o toque na linha do título aparece no cartão.
    return Card(
      key: ConclusionKeys.bestLine,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: ConclusionKeys.bestLineToggle,
            leading: Icon(Icons.timeline_rounded, color: colors.primary),
            title: Text(l10n.conclusionBestLine),
            subtitle: Text(l10n.conclusionBestLineHint(opponentName)),
            trailing: Icon(
              _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            onTap: _toggle,
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.insideCard,
                0,
                AppSpacing.insideCard,
                AppSpacing.insideCard,
              ),
              child: LayoutBuilder(
                builder: (context, box) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PositionBoard(
                      key: ConclusionKeys.bestLineBoard,
                      fen: position.fen,
                      size: box.maxWidth,
                      orientation: widget.conclusion.userSide,
                      lastMove: last,
                    ),
                    if (running) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const AnimatedProgress(
                        key: ConclusionKeys.bestLineRunning,
                        value: null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        IconButton.outlined(
                          key: ConclusionKeys.bestLineBack,
                          tooltip: l10n.reviewPrevious,
                          onPressed: running || ply < 0 ? null : cubit.bestBack,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            ply < 0 || san == null
                                ? l10n.reviewStartPosition
                                : '${l10n.conclusionBestLineMove(ply + 1, line.length)} · $san',
                            key: ConclusionKeys.bestLineMove,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        IconButton.filled(
                          key: ConclusionKeys.bestLineForward,
                          tooltip: l10n.reviewNext,
                          onPressed: running || ply + 1 >= line.length
                              ? null
                              : cubit.bestForward,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Foi rápido: o aviso e o caminho para ir mais fundo.
                    Text(
                      l10n.conclusionBestLineDisclaimer,
                      key: ConclusionKeys.bestLineDisclaimer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (gameId != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      DetailedReviewButton(
                        gameId: gameId,
                        buttonKey: ConclusionKeys.bestLineDeeper,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// O resultado em destaque abaixo do cabeçalho: o objetivo cumprido (✓) ou
/// não (✕); no fim do speedrun com recorde, o troféu e o tempo.
Widget? _outcome(
  BuildContext context,
  ConclusionState state,
  Conclusion conclusion,
) {
  final l10n = context.l10n;
  final run = conclusion.run;
  if (run != null && run.newRecord) {
    return OutcomeStrip(
      key: ConclusionKeys.newRecord,
      mark: OutcomeMark.record,
      color: AppColors.record,
      title: l10n.speedrunNewRecord,
    );
  }
  final fulfilled = conclusion.fulfilled;
  if (fulfilled == null) return null;
  // Desistir não é falha de sistema: faixa cinza com a bandeira, sem o
  // vermelho (P9 B).
  if (!fulfilled &&
      conclusion.result == ConclusionResult.lost &&
      conclusion.end?.reason == GameEndReason.resign) {
    return OutcomeStrip(
      key: ConclusionKeys.goal,
      mark: OutcomeMark.flag,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      title: l10n.resultNotFulfilled,
    );
  }
  return OutcomeStrip(
    key: ConclusionKeys.goal,
    mark: fulfilled ? OutcomeMark.check : OutcomeMark.cross,
    color: ChangeColors.of(context, up: fulfilled),
    title: fulfilled ? l10n.resultFulfilled : l10n.resultNotFulfilled,
  );
}

/// "Ver a análise detalhada": a revisão completa da partida [gameId].
class DetailedReviewButton extends StatelessWidget {
  const DetailedReviewButton({
    required this.gameId,
    this.buttonKey = ConclusionKeys.reviewDeeper,
    super.key,
  });

  final int gameId;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: buttonKey,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(kButtonHeight),
      textStyle: AppButtonText.footer(context),
    ),
    onPressed: () => context.push(Routes.game(gameId)),
    icon: const Icon(Icons.insights_rounded),
    label: OneLine(context.l10n.conclusionDetailedReview),
  );
}

/// Vitória de partida comum (com "Jogar novamente" e "Nova partida"): a
/// "Nova partida" sobe para a barra e o rodapé ganha "Ver a análise".
bool _winNewGame(Conclusion conclusion, ConclusionState state) =>
    conclusion.result == ConclusionResult.won &&
    conclusion.gameId != null &&
    conclusion.actions.contains(ConclusionAction.playAgain) &&
    conclusion.actions.contains(ConclusionAction.newGame) &&
    state.setup != null;
