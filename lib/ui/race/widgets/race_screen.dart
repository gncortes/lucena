import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/race_cubit.dart';
import 'race_game_view.dart';
import 'race_intro_view.dart';
import 'race_result_view.dart';
import 'race_review_view.dart';

/// A Corrida de problemas: abertura, corrida, resultado e revisão numa tela
/// só; o [RaceCubit] diz em que ponto ela está.
class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // O relógio do jogador vem do relógio do aparelho, a cada décimo.
    _timer = Timer.periodic(
      AppMotion.clockRefresh,
      (_) => context.read<RaceCubit>().tick(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // De volta do segundo plano, o tempo que passou conta.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<RaceCubit>().resumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RaceCubit>();
    return BlocBuilder<RaceCubit, RaceState>(
      builder: (context, state) {
        final playing = state.phase == RacePhase.playing;
        final reviewing = state.phase == RacePhase.reviewing;
        // Voltar no meio da corrida a abandona; na revisão, volta ao
        // resultado.
        return PopScope(
          canPop: !playing && !reviewing,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (playing) unawaited(cubit.quit());
            if (reviewing) cubit.closeReview();
          },
          child: Scaffold(
            key: RaceKeys.screen,
            appBar: _appBar(context, state),
            body: SafeArea(
              bottom: false,
              child: switch (state.phase) {
                RacePhase.loading => const SizedBox.shrink(),
                RacePhase.intro => RaceIntroView(state: state),
                RacePhase.playing => RaceGameView(state: state),
                RacePhase.finished => RaceResultView(state: state),
                RacePhase.reviewing => RaceReviewView(state: state),
              },
            ),
          ),
        );
      },
    );
  }

  // A barra de cada fase: a revisão diz em que erro está, o resultado fecha
  // com um X à esquerda.
  PreferredSizeWidget _appBar(BuildContext context, RaceState state) {
    final l10n = context.l10n;
    switch (state.phase) {
      case RacePhase.finished:
        return LucenaAppBar(
          leading: IconButton(
            key: RaceKeys.close,
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(l10n.raceTitle),
        );
      case RacePhase.reviewing:
        return LucenaAppBar(
          title: Text(
            l10n.raceReviewTitle(state.reviewIndex + 1, state.mistakes.length),
            key: RaceKeys.reviewTitle,
          ),
        );
      case RacePhase.loading || RacePhase.intro || RacePhase.playing:
        return LucenaAppBar(title: Text(l10n.raceTitle));
    }
  }
}
