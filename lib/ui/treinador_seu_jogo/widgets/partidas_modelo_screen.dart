import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/open_link.dart';
import '../view_models/partidas_modelo_cubit.dart';
import '../../core/theme/app_text.dart';

/// As partidas-modelo de uma abertura e o aviso de partida nova.
class PartidasModeloScreen extends StatelessWidget {
  const PartidasModeloScreen({required this.eco, this.nome, super.key});

  final String eco;

  /// O nome da abertura ("Defesa Eslava"); sem ele, o título é genérico.
  final String? nome;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocProvider(
      create: (c) => createModelGamesCubit(c, eco: eco)..load(),
      child: Scaffold(
        key: SeuJogoKeys.modelosScreen,
        appBar: LucenaAppBar(title: Text(t.sjModelosTitulo), centerTitle: true),
        body: BlocBuilder<PartidasModeloCubit, PartidasModeloState>(
          builder: (context, state) => switch (state.status) {
            PartidasModeloStatus.carregando => const Center(
              child: CircularProgressIndicator(),
            ),
            PartidasModeloStatus.erro => LoadErrorScreen(
              kind: LoadErrorKind.generic,
              onAction: () => context.read<PartidasModeloCubit>().load(),
            ),
            PartidasModeloStatus.pronto => _Lista(state: state, nome: nome),
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.state, this.nome});

  final PartidasModeloState state;
  final String? nome;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variante = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final abertura = nome ?? t.sjModelosAberturaGenerica;
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
              key: SeuJogoKeys.modelosAviso,
              contentPadding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.sm,
              ),
              value: state.aviso,
              onChanged: (v) =>
                  context.read<PartidasModeloCubit>().definirAviso(ligado: v),
              title: Text(
                t.sjModelosAviso,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: AppWeight.medium,
                ),
              ),
              subtitle: Text(t.sjModelosAvisoTexto(abertura), style: variante),
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
                t.sjModelosSecao(abertura),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppWeight.medium,
                ),
              ),
              Text(t.sjModelosSecaoTexto, style: variante),
              const SizedBox(height: AppSpacing.md),
              if (state.modelos.isEmpty)
                EmptyState(
                  key: SeuJogoKeys.modelosVazio,
                  icon: Icons.emoji_events_outlined,
                  message: t.sjModelosVazio,
                )
              else
                for (final (i, m) in state.modelos.indexed) ...[
                  if (i > 0) const Divider(height: AppSpacing.lg),
                  _Modelo(indice: i, modelo: m),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Modelo extends StatelessWidget {
  const _Modelo({required this.indice, required this.modelo});

  final int indice;
  final PartidaModelo modelo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final primaria = theme.colorScheme.primary;
    final url = modelo.url == null ? null : Uri.tryParse(modelo.url!);
    final (fonte, abrir) = switch (modelo.fonte) {
      'historica' => (t.sjModeloFonteHistorica, t.sjModeloAbrirLichess),
      'estudo' => (t.sjModeloFonteEstudo, t.sjModeloAbrirLichess),
      'artigo' => (t.sjModeloFonteArtigo, t.sjModeloAbrirArtigo),
      _ => (t.sjModeloFonteTorneio, t.sjModeloAbrirLichess),
    };
    return Column(
      key: SeuJogoKeys.modelo(indice),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fonte,
          style: theme.textTheme.labelSmall?.copyWith(
            color: primaria,
            fontWeight: AppWeight.medium,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          modelo.titulo,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: AppWeight.medium,
          ),
        ),
        if (modelo.subtitulo case final s?)
          Text(
            s,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (url != null)
          TextButton.icon(
            key: SeuJogoKeys.modeloAbrir(indice),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, kButtonHeightCompact),
              foregroundColor: primaria,
            ),
            onPressed: () => openLink(context, url),
            icon: const Icon(Icons.open_in_new, size: AppIconSize.compact),
            label: Text(abrir),
          ),
      ],
    );
  }
}
