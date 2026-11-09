import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/coach/coach.dart';
import '../../core/keys/coach_your_game_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/open_link.dart';
import '../view_models/model_games_cubit.dart';
import '../../core/theme/app_text.dart';

/// As partidas-modelo de uma abertura e o aviso de partida nova.
class ModelGamesScreen extends StatelessWidget {
  const ModelGamesScreen({required this.eco, this.name, super.key});

  final String eco;

  /// O nome da abertura ("Defesa Eslava"); sem ele, o título é genérico.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocProvider(
      create: (c) => createModelGamesCubit(c, eco: eco)..load(),
      child: Scaffold(
        key: YourGameKeys.modelGamesScreen,
        appBar: LucenaAppBar(title: Text(t.sjModelosTitulo), centerTitle: true),
        body: BlocBuilder<ModelGamesCubit, ModelGamesState>(
          builder: (context, state) => switch (state.status) {
            ModelGamesStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ModelGamesStatus.error => LoadErrorScreen(
              kind: LoadErrorKind.generic,
              onAction: () => context.read<ModelGamesCubit>().load(),
            ),
            ModelGamesStatus.ready => _List(state: state, name: name),
          },
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.state, this.name});

  final ModelGamesState state;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variant = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final opening = name ?? t.sjModelosAberturaGenerica;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        LucenaCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              key: YourGameKeys.modelGamesNoticeKey,
              contentPadding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.sm,
              ),
              value: state.aviso,
              onChanged: (v) =>
                  context.read<ModelGamesCubit>().setNotice(linked: v),
              title: Text(
                t.sjModelosAviso,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: AppWeight.medium,
                ),
              ),
              subtitle: Text(t.sjModelosAvisoTexto(opening), style: variant),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Canvas DPartidasModelo: título, subtítulo e as partidas num cartão
        // só, separadas por divisores.
        LucenaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.sjModelosSecao(opening),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppWeight.medium,
                ),
              ),
              Text(t.sjModelosSecaoTexto, style: variant),
              const SizedBox(height: AppSpacing.md),
              if (state.modelGames.isEmpty)
                EmptyState(
                  key: YourGameKeys.modelGamesEmpty,
                  icon: Icons.emoji_events_outlined,
                  message: t.sjModelosVazio,
                )
              else
                for (final (i, m) in state.modelGames.indexed) ...[
                  if (i > 0) const Divider(height: AppSpacing.lg),
                  _Model(index: i, modelGame: m),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Model extends StatelessWidget {
  const _Model({required this.index, required this.modelGame});

  final int index;
  final ModelGame modelGame;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final url = modelGame.url == null ? null : Uri.tryParse(modelGame.url!);
    final (source, open) = switch (modelGame.source) {
      'historica' => (t.sjModeloFonteHistorica, t.sjModeloAbrirLichess),
      'estudo' => (t.sjModeloFonteEstudo, t.sjModeloAbrirLichess),
      'artigo' => (t.sjModeloFonteArtigo, t.sjModeloAbrirArtigo),
      _ => (t.sjModeloFonteTorneio, t.sjModeloAbrirLichess),
    };
    return Column(
      key: YourGameKeys.modelGame(index),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          source,
          style: theme.textTheme.labelSmall?.copyWith(
            color: primaryColor,
            fontWeight: AppWeight.medium,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          modelGame.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: AppWeight.medium,
          ),
        ),
        if (modelGame.subtitle case final s?)
          Text(
            s,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (url != null)
          TextButton.icon(
            key: YourGameKeys.modelGameOpen(index),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, kButtonHeightCompact),
              foregroundColor: primaryColor,
            ),
            onPressed: () => openLink(context, url),
            icon: const Icon(Icons.open_in_new, size: AppIconSize.compact),
            label: Text(open),
          ),
      ],
    );
  }
}
