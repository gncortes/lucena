import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/conclusion.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../achievements/widgets/achievement_detail.dart';
import '../../achievements/widgets/achievement_medal.dart';
import '../../achievements/widgets/achievement_toast.dart';
import '../../core/keys/conclusion_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../../domain/models/game_review.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/review/move_quality_ui.dart';
import '../../core/share/share_button.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
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

/// A tela de conclusão (T51, frente B): o resultado sobre a posição final,
/// os dois jogadores frente a frente, as ações, o rating contando, o
/// comentário do adversário, as conquistas e, fixo embaixo, "Analisar a
/// partida". Ela substitui a partida na pilha: fechar volta para onde o
/// jogador estava antes de jogar.
class ConclusionScreen extends StatefulWidget {
  const ConclusionScreen({this.fresh = false, super.key});

  /// A partida acabou agora: as conquistas novas avisam por cima, como no
  /// fim da partida. Reaberta (o app fechado na conclusão), não avisam de
  /// novo.
  final bool fresh;

  @override
  State<ConclusionScreen> createState() => _ConclusionScreenState();
}

class _ConclusionScreenState extends State<ConclusionScreen> {
  // O cartão que vira imagem ao compartilhar e, depois da análise rápida,
  // o resumo dela, logo abaixo.
  final _card = GlobalKey();
  final _analysis = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ConclusionCubit>().state;
    final conclusion = state.conclusion;
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      key: ConclusionKeys.screen,
      appBar: AppBar(
        leading: IconButton(
          key: ConclusionKeys.close,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _close(context),
        ),
        actions: [
          if (conclusion != null)
            ShareIconButton(
              key: ConclusionKeys.share,
              boundary: _card,
              extra: [if (state.review != null) _analysis],
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
      body: !state.ready
          ? const SkeletonList()
          : conclusion == null
          ? const SizedBox.shrink()
          : Stack(
              children: [
                _Body(
                  state: state,
                  conclusion: conclusion,
                  card: _card,
                  analysis: _analysis,
                ),
                if (widget.fresh && conclusion.achievements.isNotEmpty)
                  AchievementToasts(
                    achievements: conclusion.achievements,
                    characters: state.characters,
                    onTap: (achievement) => showAchievementDetail(
                      context,
                      achievement: achievement,
                      unlocked: conclusion.unlocked[achievement.id],
                      characters: state.characters,
                      speedrunId: conclusion.run?.speedrunId,
                    ),
                  ),
              ],
            ),
    );
  }
}

// Fechar: volta para onde o jogador estava antes da partida (a partida
// foi trocada por esta tela), ou para o início se não há para onde voltar.
void _close(BuildContext context) {
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
  });

  final ConclusionState state;
  final Conclusion conclusion;
  final GlobalKey card;

  /// O cartão da análise rápida (entra na imagem depois de pronta).
  final GlobalKey analysis;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final actions = conclusion.actions;
    // As duas primeiras ações lado a lado, logo abaixo dos jogadores; as de
    // histórico viram links; "Analisar" fica fixo embaixo.
    final main = [
      for (final action in actions)
        if (!_links.contains(action) &&
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
    final feedback = state.feedback;
    final celebrate =
        conclusion.result == ConclusionResult.won &&
        (conclusion.kind == ConclusionKind.speedrunEnd ||
            conclusion.kind == ConclusionKind.marathonEnd ||
            (run?.newRecord ?? false) ||
            conclusion.achievements.isNotEmpty);
    // O que vai na imagem de compartilhar: o resultado e os números, sem
    // botões.
    final shared = <Widget>[
      _Header(state: state, conclusion: conclusion),
      ?_outcome(context, state, conclusion),
      if (conclusion.before != null && conclusion.after != null)
        _Rating(conclusion: conclusion),
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
    final sections = <Widget>[
      RepaintBoundary(
        key: card,
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, section) in shared.indexed)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.lg),
                  child: StaggeredEntrance(index: index, child: section),
                ),
            ],
          ),
        ),
      ),
      // A análise rápida: o botão, o tabuleiro andando e o resumo, no mesmo
      // cartão. Depois de pronta, ela entra na imagem de compartilhar.
      if (state.review != null ||
          (conclusion.gameId != null &&
              (conclusion.game?.moves.isNotEmpty ?? false)))
        RepaintBoundary(
          key: analysis,
          child: _Analysis(state: state, conclusion: conclusion),
        ),
      if (opponent != null && comment != null)
        TeacherSpeech(
          key: ConclusionKeys.comment,
          speechContext: SpeechContext.game,
          teacher: opponent,
          text: comment,
          emotion: state.emotion,
        ),
      if (state.bestLine.isNotEmpty && conclusion.game?.startFen != null)
        _BestLine(state: state, conclusion: conclusion),
      if (feedback.isNotEmpty)
        ReportPanel(
          report: GameReport(
            feedback: feedback,
            achievements: conclusion.achievements,
            unlocked: conclusion.unlocked,
            characters: state.characters,
          ),
        ),
      if (links.isNotEmpty) _Links(conclusion: conclusion, links: links),
    ];
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              // Rolagem simples, não lista preguiçosa: todos os blocos ficam
              // montados, e compartilhar acha o cartão e a análise mesmo com
              // a tela rolada para longe deles.
              child: SingleChildScrollView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.screen,
                  top: AppSpacing.sm,
                  right: AppSpacing.screen,
                  bottom: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, section) in sections.indexed)
                      Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : AppSpacing.lg,
                        ),
                        // O bloco de cima já entra em cascata por dentro.
                        child: index == 0
                            ? section
                            : StaggeredEntrance(
                                index: shared.length + index,
                                child: section,
                              ),
                      ),
                  ],
                ),
              ),
            ),
            // As ações, fixas embaixo: fora da imagem de compartilhar.
            if (main.isNotEmpty) _ActionsBar(state: state, actions: main),
          ],
        ),
        if (celebrate && !motion.disabled)
          const Positioned.fill(child: IgnorePointer(child: Celebration())),
      ],
    );
  }
}

const _links = {
  ConclusionAction.analyze,
  ConclusionAction.ratingHistory,
  ConclusionAction.gamesHistory,
};

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
          if (fen != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: LayoutBuilder(
                  builder: (context, box) => OverflowBox(
                    maxHeight: box.maxWidth,
                    child: PositionBoard(
                      fen: fen,
                      size: box.maxWidth,
                      orientation: userSide,
                      radius: 0,
                    ),
                  ),
                ),
              ),
            ),
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
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (end != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _reason(l10n, end.reason),
                    key: ConclusionKeys.reason,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
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
                            size: 32,
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
                            ? const ColoredBox(
                                color: Color(0xFF312E2B),
                                child: Icon(
                                  Icons.smart_toy_outlined,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              )
                            : CharacterAvatar(character: opponent, size: 64),
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
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppShape.medium),
            color: winner ? colors.primary : colors.outlineVariant,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppShape.small),
            child: avatar,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        OneLine(
          name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// As ações principais, fixas embaixo, uma embaixo da outra: a principal em
/// cima.
class _ActionsBar extends StatelessWidget {
  const _ActionsBar({required this.state, required this.actions});

  final ConclusionState state;
  final List<ConclusionAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, action) in actions.take(2).indexed) ...[
                if (index > 0) const SizedBox(height: AppSpacing.sm),
                _ActionButton(
                  action: action,
                  primary: index == 0,
                  state: state,
                ),
              ],
            ],
          ),
        ),
      ),
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
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
    );
    final child = OneLine(label);
    return primary
        ? FilledButton.icon(
            key: ConclusionKeys.action(action),
            style: style,
            onPressed: onPressed,
            icon: Icon(icon),
            label: child,
          )
        : OutlinedButton.icon(
            key: ConclusionKeys.action(action),
            style: style,
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
        if (run == null) return null;
        return () => context.push(Routes.speedrun(run.speedrunId));
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
    return Container(
      key: ConclusionKeys.mode,
      padding: const EdgeInsets.all(AppSpacing.insideCard),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
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
              size: 22,
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
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  time == null ? l10n.challengeNoClock : paceLabel(l10n, time),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O rating contando do antigo até o novo.
class _Rating extends StatefulWidget {
  const _Rating({required this.conclusion});

  final Conclusion conclusion;

  @override
  State<_Rating> createState() => _RatingState();
}

class _RatingState extends State<_Rating> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebrate,
  );
  late final _counting = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sem animações: já no valor novo.
    if (AppMotion.of(context).disabled) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final before = widget.conclusion.before!.rating;
    final after = widget.conclusion.after!.rating;
    return Container(
      key: ConclusionKeys.rating,
      padding: const EdgeInsets.all(AppSpacing.insideCard),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.reportRatingLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          AnimatedBuilder(
            animation: _counting,
            builder: (context, _) => RatingValue(
              rating: (before + (after - before) * _counting.value).round(),
              change: ((after - before) * _counting.value).round(),
              up: after >= before,
              large: true,
              valueKey: ConclusionKeys.ratingValue,
              changeKey: ConclusionKeys.ratingDelta,
            ),
          ),
        ],
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
    return Container(
      key: ConclusionKeys.run,
      padding: const EdgeInsets.all(AppSpacing.insideCard),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Perdeu a etapa: o tempo grande não diz nada (o relógio acabou ou
          // a partida se perdeu); fica só o detalhe, para quem quiser.
          if (!_lost) ...[
            Text(
              ended ? l10n.conclusionTotalTime : l10n.conclusionTotalSoFar,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              time(spent),
              key: ConclusionKeys.total,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          if (ended && record != null && !run.newRecord)
            Text(
              '${l10n.speedrunBest}: ${time(record)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
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
              style: theme.textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (fastest) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
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
                              size: 14,
                              color: accent,
                            ),
                            Text(
                              l10n.conclusionFastest,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
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
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
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
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, action) in links.indexed) ...[
            if (index > 0) const Divider(height: 1),
            ListTile(
              key: ConclusionKeys.action(action),
              leading: Icon(switch (action) {
                ConclusionAction.analyze => Icons.insights_rounded,
                ConclusionAction.ratingHistory => Icons.show_chart_rounded,
                _ => Icons.history_rounded,
              }),
              title: Text(switch (action) {
                ConclusionAction.analyze => l10n.conclusionAnalyze,
                ConclusionAction.ratingHistory => l10n.conclusionRatingHistory,
                _ => l10n.statsGamesTitle,
              }),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(switch (action) {
                ConclusionAction.analyze => Routes.game(conclusion.gameId!),
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
    final game = state.conclusion!.game!;
    Position position = Chess.fromSetup(Setup.parseFen(game.startFen!));
    Move? last;
    for (final uci in game.moves.take(state.reviewDone)) {
      final move = Move.parse(uci);
      if (move == null || !position.isLegal(move)) break;
      position = position.play(move);
      last = move;
    }
    return PositionBoard(
      key: ConclusionKeys.reviewBoard,
      fen: position.fen,
      size: size,
      orientation: state.conclusion!.userSide,
      lastMove: last,
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

    return Material(
      key: ConclusionKeys.quickReview,
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(AppShape.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: review == null && !state.reviewing
            ? () => context.read<ConclusionCubit>().quickReview()
            : null,
        child: AnimatedSize(
          duration: motion.component,
          curve: AppMotion.move,
          alignment: Alignment.topCenter,
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

/// O título do cartão: o raio e "Análise rápida", com a linha de baixo.
class _AnalysisTitle extends StatelessWidget {
  const _AnalysisTitle({required this.subtitle, this.trailing});

  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSecondaryContainer;
    return SizedBox(
      height: _AnalysisRunning.titleHeight,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
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
  static const _barHeight = 6.0;

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
        ClipRRect(
          borderRadius: BorderRadius.circular(AppShape.full),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total == 0 ? 0 : state.reviewDone / total),
            duration: AppMotion.of(context).state,
            builder: (context, value, _) =>
                LinearProgressIndicator(value: value, minHeight: _barHeight),
          ),
        ),
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
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
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (mine ?? 0) / 100),
                duration: AppMotion.of(context).celebrate,
                curve: AppMotion.enter,
                builder: (context, value, _) => Container(
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
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

/// "Ver a melhor linha": a linha do Stockfish desde a posição de início,
/// lance a lance, num tabuleiro dentro da própria tela.
class _BestLine extends StatefulWidget {
  const _BestLine({required this.state, required this.conclusion});

  final ConclusionState state;
  final Conclusion conclusion;

  @override
  State<_BestLine> createState() => _BestLineState();
}

class _BestLineState extends State<_BestLine> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = widget.state;
    final cubit = context.read<ConclusionCubit>();
    final line = state.bestLine;
    final ply = state.bestPly;
    // A posição depois do lance mostrado e o nome dele (SAN).
    Position position = Chess.fromSetup(
      Setup.parseFen(widget.conclusion.game!.startFen!),
    );
    Move? last;
    String? san;
    for (final uci in line.take(ply + 1)) {
      final move = Move.parse(uci);
      if (move == null || !position.isLegal(move)) break;
      final (next, name) = position.makeSan(move);
      position = next;
      last = move;
      san = name;
    }
    // Um Material próprio: o toque na linha do título aparece no cartão.
    return Material(
      key: ConclusionKeys.bestLine,
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppShape.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: ConclusionKeys.bestLineToggle,
            leading: Icon(Icons.timeline_rounded, color: colors.primary),
            title: Text(l10n.conclusionBestLine),
            subtitle: Text(l10n.conclusionBestLineHint),
            trailing: Icon(
              _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            onTap: () => setState(() => _open = !_open),
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
                  children: [
                    PositionBoard(
                      key: ConclusionKeys.bestLineBoard,
                      fen: position.fen,
                      size: box.maxWidth,
                      orientation: widget.conclusion.userSide,
                      lastMove: last,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        IconButton.outlined(
                          key: ConclusionKeys.bestLineBack,
                          tooltip: l10n.reviewPrevious,
                          onPressed: ply < 0 ? null : cubit.bestBack,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            ply < 0
                                ? l10n.reviewStartPosition
                                : '${l10n.conclusionBestLineMove(ply + 1, line.length)} · $san',
                            key: ConclusionKeys.bestLineMove,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        IconButton.filled(
                          key: ConclusionKeys.bestLineForward,
                          tooltip: l10n.reviewNext,
                          onPressed: ply + 1 >= line.length
                              ? null
                              : cubit.bestForward,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
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
      // O dourado das medalhas, mais escuro no tema claro para ler bem.
      color: Theme.of(context).brightness == Brightness.dark
          ? AchievementMedal.gold[1]
          : AchievementMedal.gold[2],
      title: l10n.speedrunNewRecord,
    );
  }
  final fulfilled = conclusion.fulfilled;
  if (fulfilled == null) return null;
  return OutcomeStrip(
    key: ConclusionKeys.goal,
    mark: fulfilled ? OutcomeMark.check : OutcomeMark.cross,
    color: ChangeColors.of(context, up: fulfilled),
    title: fulfilled ? l10n.resultFulfilled : l10n.resultNotFulfilled,
  );
}
