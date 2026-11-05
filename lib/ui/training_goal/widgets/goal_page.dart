import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/use_cases/training/goal/goal_view.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../course_guide/widgets/training_load_error.dart';
import '../view_models/training_goal_cubit.dart';
import '../../core/motion/barra_que_enche.dart';
import '../../core/motion/entrada_em_cascata.dart';

/// Moldura das telas do fluxo do objetivo: título só com texto, carregando e
/// erro únicos da base D0, rodapé fixo opcional.
class GoalPage extends StatelessWidget {
  const GoalPage({
    required this.screenKey,
    required this.title,
    required this.onBack,
    required this.builder,
    this.footer,
    this.backKey,
    this.centerTitle = true,
    this.titleOf,
    this.progressOf,
    this.titleKey,
    this.cascata = false,
    super.key,
  });

  final Key screenKey;
  final Key? backKey;
  final String title;

  /// Título à esquerda onde o quadro pede (Registrar, Semana, Meus torneios).
  final bool centerTitle;

  /// Título e progresso que dependem do estado (a barra do teste).
  final String Function(GoalView view)? titleOf;
  final double? Function(GoalView view)? progressOf;
  final Key? titleKey;
  final VoidCallback onBack;
  final List<Widget> Function(BuildContext context, GoalView view) builder;
  final Widget Function(BuildContext context, GoalView view)? footer;

  /// H-ANI-16: o texto que explica entra em cascata (o primeiro item como
  /// título), só na primeira entrada da tela.
  final bool cascata;

  List<Widget> _corpo(BuildContext context, GoalView view) {
    final filhos = builder(context, view);
    if (!cascata || filhos.isEmpty) return filhos;
    return [
      EntradaEmCascata(
        itens: [
          for (final (i, filho) in filhos.indexed)
            i == 0 ? ItemDaCascata.titulo(filho) : ItemDaCascata.texto(filho),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrainingGoalCubit>();
    return BlocBuilder<TrainingGoalCubit, TrainingGoalState>(
      builder: (context, state) {
        final view = state.view;
        if (view == null) {
          if (state.failed) {
            return trainingLoadError(context, state.failure, cubit.load);
          }
          return LoadSkeletonScreen(title: title);
        }
        return Scaffold(
          key: screenKey,
          appBar: LucenaAppBar(
            centerTitle: centerTitle,
            title: Text(titleOf?.call(view) ?? title, key: titleKey),
            bottom: switch (progressOf?.call(view)) {
              final value? => PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: BarraQueEnche(valor: value, altura: 4),
              ),
              null => null,
            },
            leading: IconButton(
              key: backKey,
              onPressed: onBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    children: _corpo(context, view),
                  ),
                ),
                if (footer != null) GoalFooter(child: footer!(context, view)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// O rodapé fixo dos quadros do objetivo e do Guia: botão de 52 na largura
/// toda, 16 nas laterais e embaixo.
class GoalFooter extends StatelessWidget {
  const GoalFooter({required this.child, super.key});
  final Widget child;

  static const _size = WidgetStatePropertyAll(Size.fromHeight(kButtonHeight));

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      0,
      AppSpacing.screen,
      AppSpacing.screen,
    ),
    child: FilledButtonTheme(
      data: FilledButtonThemeData(
        style: FilledButtonTheme.of(context).style
            ?.copyWith(minimumSize: _size),
      ),
      child: OutlinedButtonTheme(
        data: OutlinedButtonThemeData(
          style: OutlinedButtonTheme.of(context).style
              ?.copyWith(minimumSize: _size),
        ),
        child: child,
      ),
    ),
  );
}
