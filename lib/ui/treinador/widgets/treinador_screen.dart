import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../routing/routes.dart';
import '../../core/keys/treinador_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_chip.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_navigation_bar.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/section_title.dart';
import '../view_models/ligar_conta_cubit.dart';
import '../view_models/treinador_cubit.dart';
import 'linha_partida.dart';
import 'treinador_textos.dart';

/// As abas do Treinador, na ordem da barra.
enum AbaTreinador {
  hoje,
  partidas,
  seuJogo;

  static AbaTreinador parse(String? valor) =>
      values.where((a) => a.name == valor).firstOrNull ?? hoje;
}

/// A casca do Treinador de partidas (T87): Hoje, Partidas e Seu jogo. Sem
/// conta ligada, mostra o "Onde você joga?".
class TreinadorScreen extends StatefulWidget {
  const TreinadorScreen({
    this.aba = AbaTreinador.hoje,
    this.seuJogo,
    super.key,
  });

  final AbaTreinador aba;

  /// A aba Seu jogo vem da outra frente (`lib/ui/treinador_seu_jogo/`); sem
  /// ela, o aviso de "em breve".
  final WidgetBuilder? seuJogo;

  @override
  State<TreinadorScreen> createState() => _TreinadorScreenState();
}

class _TreinadorScreenState extends State<TreinadorScreen> {
  late var _aba = widget.aba;

  void _voltar() => context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<TreinadorCubit, TreinadorState>(
      builder: (context, state) {
        if (state.carregando) {
          return LoadSkeletonScreen(title: l.treinadorTitle);
        }
        if (state.falhou && state.partidas.isEmpty && state.conta == null) {
          return LoadErrorScreen(
            kind: LoadErrorKind.offline,
            onAction: context.read<TreinadorCubit>().tentarDeNovo,
            onBack: _voltar,
          );
        }
        final semConta = state.semConta;
        return Scaffold(
          key: TreinadorKeys.screen,
          appBar: LucenaAppBar(
            leading: BackButton(key: TreinadorKeys.back, onPressed: _voltar),
            title: Text(l.treinadorTitle),
          ),
          body: semConta
              ? _LigarConta(acesso: state.acesso)
              : switch (_aba) {
                  AbaTreinador.hoje => _Hoje(state: state),
                  AbaTreinador.partidas => _Partidas(state: state),
                  AbaTreinador.seuJogo => KeyedSubtree(
                    key: TreinadorKeys.seuJogo,
                    child:
                        widget.seuJogo?.call(context) ??
                        Center(
                          child: EmptyState(
                            icon: Icons.insights,
                            message: l.treinadorSeuJogoEmBreve,
                          ),
                        ),
                  ),
                },
          bottomNavigationBar: semConta
              ? null
              : IconNavigationBar(
                  selectedIndex: _aba.index,
                  onDestinationSelected: (i) =>
                      setState(() => _aba = AbaTreinador.values[i]),
                  tabs: [
                    (
                      key: TreinadorKeys.tabHoje,
                      label: l.treinadorTabHoje,
                      icon: Icons.task_alt,
                    ),
                    (
                      key: TreinadorKeys.tabPartidas,
                      label: l.treinadorTabPartidas,
                      icon: Icons.format_list_bulleted,
                    ),
                    (
                      key: TreinadorKeys.tabSeuJogo,
                      label: l.treinadorTabSeuJogo,
                      icon: Icons.insights,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

void _abrir(BuildContext context, PartidaTreinador p) =>
    unawaited(context.push(Routes.treinadorPartida(p.id)));

/// A aba Hoje: a última partida e os exercícios que faltam.
class _Hoje extends StatelessWidget {
  const _Hoje({required this.state});

  final TreinadorState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final agora = context.read<Now>()();
    final ultima = state.ultima;
    final paraFazer = [
      for (final p in state.partidas)
        if (p.pronta &&
            p.exercicios.isNotEmpty &&
            !(p.progresso ?? ProgressoPartida.vazio).completo(
              p.exercicios.length,
            ))
          p,
    ];
    return ListView(
      key: TreinadorKeys.hoje,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        if (!state.acesso) const _SemPlano(),
        SectionTitle(l.treinadorUltimaPartida),
        if (ultima == null)
          EmptyState(
            key: TreinadorKeys.hojeVazio,
            icon: Icons.sports_esports_outlined,
            message: l.treinadorHojeVazio(
              context.plataforma(state.conta?.plataforma ?? Plataforma.lichess),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DecoratedBox(
              key: TreinadorKeys.ultimaPartida,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.large),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinhaPartida(
                      partida: ultima,
                      agora: agora,
                      acesso: state.acesso,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: BusyButton(
                        buttonKey: TreinadorKeys.verUltimaPartida,
                        label: l.treinadorVerPartida,
                        onPressed: () => _abrir(context, ultima),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (ultima != null) ...[
          const SizedBox(height: AppSpacing.md),
          SectionTitle(l.treinadorParaFazer),
          if (paraFazer.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l.treinadorHojeEmDia,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            )
          else
            for (final p in paraFazer)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: CourseItemTile(
                  key: TreinadorKeys.paraFazer(p.id),
                  state: (p.progresso?.feitos ?? 0) > 0
                      ? CourseItemState.started
                      : CourseItemState.next,
                  title: p.adversario.nome,
                  summary: l.treinadorEstadoExercicios(
                    p.progresso?.feitos ?? 0,
                    p.exercicios.length,
                  ),
                  onTap: () => _abrir(context, p),
                ),
              ),
        ],
      ],
    );
  }
}

/// A aba Partidas: os filtros de ritmo e resultado e a lista.
class _Partidas extends StatelessWidget {
  const _Partidas({required this.state});

  final TreinadorState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<TreinadorCubit>();
    final agora = context.read<Now>()();
    final filtro = state.filtro;
    final lista = state.filtradas;
    Widget chip(Key key, String label, bool selected, VoidCallback onTap) =>
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
          child: ChoiceChip(
            key: key,
            materialTapTargetSize: AppChip.tapTarget,
            visualDensity: AppChip.density,
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap(),
          ),
        );
    Widget linha(String titulo, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            ...chips,
          ],
        ),
      ),
    );
    return Column(
      key: TreinadorKeys.partidas,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        linha(l.treinadorFiltroRitmo, [
          chip(
            TreinadorKeys.filtroRitmo('todos'),
            l.treinadorFiltroTodos,
            filtro.ritmo == null,
            () => unawaited(cubit.filtrar(filtro.comRitmo(null))),
          ),
          for (final r in Ritmo.values)
            chip(
              TreinadorKeys.filtroRitmo(r.wire),
              context.ritmo(r),
              filtro.ritmo == r,
              () => unawaited(cubit.filtrar(filtro.comRitmo(r))),
            ),
        ]),
        linha(l.treinadorFiltroResultado, [
          chip(
            TreinadorKeys.filtroResultado('todos'),
            l.treinadorFiltroTodos,
            filtro.resultado == null,
            () => unawaited(cubit.filtrar(filtro.comResultado(null))),
          ),
          for (final (r, nome) in [
            (Resultado.vitoria, l.treinadorFiltroVitorias),
            (Resultado.derrota, l.treinadorFiltroDerrotas),
            (Resultado.empate, l.treinadorFiltroEmpates),
          ])
            chip(
              TreinadorKeys.filtroResultado(r.wire),
              nome,
              filtro.resultado == r,
              () => unawaited(cubit.filtrar(filtro.comResultado(r))),
            ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: state.partidas.isEmpty
              ? Center(
                  child: EmptyState(
                    key: TreinadorKeys.partidasVazio,
                    icon: Icons.sports_esports_outlined,
                    message: l.treinadorHojeVazio(
                      context.plataforma(
                        state.conta?.plataforma ?? Plataforma.lichess,
                      ),
                    ),
                  ),
                )
              : lista.isEmpty
              ? Center(
                  child: EmptyState(
                    key: TreinadorKeys.partidasVazio,
                    icon: Icons.filter_alt_off_outlined,
                    message: l.treinadorPartidasVazio,
                    actionLabel: l.treinadorLimparFiltros,
                    actionKey: TreinadorKeys.limparFiltros,
                    onAction: () => unawaited(cubit.limparFiltros()),
                  ),
                )
              : ListView.separated(
                  key: TreinadorKeys.partidasBase,
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: AppSpacing.md),
                  itemBuilder: (context, i) => LinhaPartida(
                    partida: lista[i],
                    agora: agora,
                    acesso: state.acesso,
                    onTap: () => _abrir(context, lista[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

/// A caixa de quem não tem o plano de análise (3 análises grátis por semana).
class _SemPlano extends StatelessWidget {
  const _SemPlano();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: LucenaCard(
        key: TreinadorKeys.semPlano,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.treinadorSemPlanoTitulo, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.treinadorSemPlanoTexto,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            BusyButton(
              buttonKey: TreinadorKeys.conhecerPlano,
              style: BusyButtonStyle.tonal,
              label: l.treinadorConhecerPlano,
              onPressed: () => unawaited(context.push(Routes.pilaresSale)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Onde você joga?": escolhe o site e digita o usuário.
class _LigarConta extends StatefulWidget {
  const _LigarConta({required this.acesso});

  final bool acesso;

  @override
  State<_LigarConta> createState() => _LigarContaState();
}

class _LigarContaState extends State<_LigarConta> {
  Plataforma? _plataforma;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final plataforma = _plataforma;
    return ListView(
      key: TreinadorKeys.ligarConta,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l.treinadorLigarTitulo,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.treinadorLigarTexto,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (plataforma == null)
          for (final (p, key) in [
            (Plataforma.lichess, TreinadorKeys.ligarLichess),
            (Plataforma.chesscom, TreinadorKeys.ligarChesscom),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: BusyButton(
                buttonKey: key,
                style: BusyButtonStyle.outlined,
                label: context.plataforma(p),
                onPressed: () => setState(() => _plataforma = p),
              ),
            )
        else
          BlocProvider(
            key: ValueKey(plataforma),
            create: (c) => LigarContaCubit(
              repository: c.read<TreinadorRepository>(),
              plataforma: plataforma,
            ),
            child: _FormConta(
              onTrocar: () => setState(() => _plataforma = null),
            ),
          ),
      ],
    );
  }
}

class _FormConta extends StatelessWidget {
  const _FormConta({required this.onTrocar});

  final VoidCallback onTrocar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<LigarContaCubit>();
    return BlocBuilder<LigarContaCubit, LigarContaState>(
      builder: (context, state) {
        final site = context.plataforma(state.plataforma);
        final erro = switch (state.falha) {
          null => null,
          FalhaLigarConta.naoExiste => l.treinadorContaNaoExiste(site),
          FalhaLigarConta.semResposta => l.treinadorContaSemResposta,
          FalhaLigarConta.semPlano => l.treinadorContaSemPlano,
          FalhaLigarConta.semLogin => l.treinadorContaSemLogin,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: TreinadorKeys.usuario,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onChanged: cubit.digitar,
              onSubmitted: (_) => unawaited(cubit.ligar()),
              decoration: InputDecoration(
                labelText: l.treinadorUsuarioNo(site),
                border: const OutlineInputBorder(),
              ),
            ),
            if (erro != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  erro,
                  key: TreinadorKeys.contaErro,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            BusyButton(
              buttonKey: TreinadorKeys.confirmarConta,
              label: l.treinadorLigarConta,
              busy: state.enviando,
              onPressed: state.podeEnviar ? cubit.ligar : null,
            ),
            if (state.falha == FalhaLigarConta.semPlano) ...[
              const SizedBox(height: AppSpacing.sm),
              BusyButton(
                buttonKey: TreinadorKeys.conhecerPlano,
                style: BusyButtonStyle.tonal,
                label: l.treinadorConhecerPlano,
                onPressed: () => unawaited(context.push(Routes.pilaresSale)),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            BusyButton(
              buttonKey: TreinadorKeys.trocarSite,
              style: BusyButtonStyle.text,
              label: l.treinadorTrocarSite,
              onPressed: onTrocar,
            ),
          ],
        );
      },
    );
  }
}
