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
import '../../core/motion/abas_fade_through.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/lista_em_ordem.dart';
import '../../core/theme/app_chip.dart';
import '../../core/theme/app_icon_size.dart';
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
    this.abrirUltima = false,
    super.key,
  });

  final AbaTreinador aba;

  /// A aba Seu jogo vem da outra frente (`lib/ui/treinador_seu_jogo/`); sem
  /// ela, o aviso de "em breve".
  final WidgetBuilder? seuJogo;

  /// Atalho da Home (A10): ao carregar, abre a última partida por cima da
  /// lista se ainda falta analisar ou fazer exercício nela.
  final bool abrirUltima;

  @override
  State<TreinadorScreen> createState() => _TreinadorScreenState();
}

class _TreinadorScreenState extends State<TreinadorScreen> {
  late var _aba = widget.aba;
  late var _abrirUltima = widget.abrirUltima;

  /// Uma vez só, com a lista carregada e o plano: a última partida nova, na
  /// espera ou com exercício pendente abre por cima; feita, fica no Hoje.
  void _talvezAbrirUltima(TreinadorState state) {
    if (!_abrirUltima || state.carregando) return;
    _abrirUltima = false;
    final ultima = state.ultima;
    if (!state.acesso || ultima == null) return;
    final feita = ultima.pronta && _proximo(ultima) == null;
    if (!feita) _abrir(context, ultima);
  }

  void _voltar() => context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<TreinadorCubit, TreinadorState>(
      listenWhen: (_, _) => _abrirUltima,
      listener: (context, state) => _talvezAbrirUltima(state),
      builder: (context, state) {
        if (_abrirUltima && !state.carregando) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => mounted ? _talvezAbrirUltima(state) : null,
          );
        }
        if (state.carregando) {
          return LoadSkeletonScreen(title: l.treinadorTitle);
        }
        if (state.falhou && state.partidas.isEmpty) {
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
              // H-ANI-05: a troca de aba em fade through, como nas abas de
              // baixo do resto do app; a barra fica parada.
              : AbasFadeThrough(
                  child: KeyedSubtree(
                    key: ValueKey(_aba),
                    child: switch (_aba) {
                      AbaTreinador.hoje => EntradaDaTela(
                        id: 'TreinadorHoje',
                        child: _Hoje(state: state),
                      ),
                      AbaTreinador.partidas => EntradaDaTela(
                        id: 'TreinadorPartidas',
                        child: _Partidas(state: state),
                      ),
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
                  ),
                ),
          bottomNavigationBar: IconNavigationBar(
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

/// O próximo exercício pendente de uma partida pronta: o mesmo em que a tela
/// de exercícios começa (`ProgressoPartida.proximo`). Nulo se não há nenhum.
ExercicioTreinador? _proximo(PartidaTreinador p) {
  if (!p.pronta) return null;
  final feitos = (p.progresso ?? ProgressoPartida.vazio).feitos;
  return feitos < p.exercicios.length ? p.exercicios[feitos] : null;
}

/// O nome do tema do exercício (`xeque_duplo` → "Xeque duplo"). Tema sem nome
/// no app aparece com o texto do servidor sem os sublinhados.
String? nomeTemaTreinador(AppLocalizations l, String? tema) {
  if (tema == null || tema.isEmpty) return null;
  final texto = tema.replaceAll('_', ' ');
  return l.treinadorHojeTema(
    tema,
    '${texto[0].toUpperCase()}${texto.substring(1)}',
  );
}

/// A aba Hoje: a última partida e os exercícios que faltam.
class _Hoje extends StatelessWidget {
  const _Hoje({required this.state});

  final TreinadorState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final agora = context.read<Now>()();
    final ultima = state.ultima;
    final paraFazer = [
      for (final p in state.partidas)
        if (_proximo(p) case final ex?) (p, ex),
    ];
    return ListView(
      key: TreinadorKeys.hoje,
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.lg),
      children: [
        if (!state.acesso) const _SemPlano(),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        l.treinadorHojeUltima,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    LinhaPartida(
                      partida: ultima,
                      agora: agora,
                      acesso: state.acesso,
                      mostrarResumo: true,
                      onTap: () => _abrir(context, ultima),
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
          SectionTitle(l.treinadorHojeParaFazer),
          if (paraFazer.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l.treinadorHojeEmDia,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else
            // H-ANI-17: a lista entra em ordem na primeira vez.
            ListaEmOrdem(
              itens: [
                for (final (p, ex) in paraFazer)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: CourseItemTile(
                      key: TreinadorKeys.paraFazerExercicio(p.id, ex.n),
                      state: CourseItemState.open,
                      title:
                          nomeTemaTreinador(l, ex.tema) ??
                          l.treinadorLance(ex.lance),
                      summary: l.treinadorHojeExercicio(
                        p.adversario.nome,
                        ex.lance,
                      ),
                      difficulty: ex.estrelas.clamp(1, 3),
                      onTap: () => unawaited(
                        context.push(Routes.treinadorExercicios(p.id)),
                      ),
                    ),
                  ),
              ],
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

  String _contagem(BuildContext context, int n) {
    final l = context.l10n;
    final filtro = state.filtro;
    final nome = switch (filtro.resultado) {
      null => l.treinadorListaPartidas(n),
      Resultado.vitoria => l.treinadorListaVitorias(n),
      Resultado.derrota => l.treinadorListaDerrotas(n),
      Resultado.empate => l.treinadorListaEmpates(n),
    };
    final ritmo = filtro.ritmo;
    if (ritmo != null) {
      return l.treinadorListaContagemRitmo(
        n,
        nome,
        context.ritmo(ritmo).toLowerCase(),
      );
    }
    return l.treinadorListaContagemSite(
      n,
      nome,
      context.plataforma(state.conta?.plataforma ?? Plataforma.lichess),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TreinadorCubit>();
    final agora = context.read<Now>()();
    final filtro = state.filtro;
    final lista = state.filtradas;
    Widget chip(Key key, String label, bool selected, VoidCallback onTap) =>
        ChoiceChip(
          key: key,
          materialTapTargetSize: AppChip.tapTarget,
          visualDensity: AppChip.density,
          label: Text(label),
          showCheckmark: false,
          selected: selected,
          onSelected: (_) => onTap(),
        );
    return ListView(
      key: TreinadorKeys.partidas,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Canvas DPartidasFiltro: uma fileira que rola; "Todas" uma vez só.
        SingleChildScrollView(
          key: TreinadorKeys.filtros,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              chip(
                TreinadorKeys.filtroTodas,
                l.treinadorListaTodas,
                filtro.ritmo == null && filtro.resultado == null,
                () => unawaited(
                  cubit.filtrar(filtro.comRitmo(null).comResultado(null)),
                ),
              ),
              for (final r in Ritmo.values)
                chip(
                  TreinadorKeys.filtroRitmo(r.wire),
                  context.ritmo(r),
                  filtro.ritmo == r,
                  () => unawaited(
                    cubit.filtrar(
                      filtro.comRitmo(filtro.ritmo == r ? null : r),
                    ),
                  ),
                ),
              SizedBox(
                height: AppSpacing.lg,
                child: VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
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
                  () => unawaited(
                    cubit.filtrar(
                      filtro.comResultado(filtro.resultado == r ? null : r),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (state.partidas.isEmpty)
          EmptyState(
            key: TreinadorKeys.partidasVazio,
            icon: Icons.sports_esports_outlined,
            message: l.treinadorHojeVazio(
              context.plataforma(state.conta?.plataforma ?? Plataforma.lichess),
            ),
          )
        else if (lista.isEmpty)
          EmptyState(
            key: TreinadorKeys.partidasVazio,
            icon: Icons.filter_alt_off_outlined,
            message: l.treinadorPartidasVazio,
            actionLabel: l.treinadorLimparFiltros,
            actionKey: TreinadorKeys.limparFiltros,
            onAction: () => unawaited(cubit.limparFiltros()),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
            child: Text(
              _contagem(context, lista.length),
              key: TreinadorKeys.partidasContagem,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          LucenaCard(
            key: TreinadorKeys.partidasBase,
            padding: EdgeInsets.zero,
            // H-ANI-17: as partidas entram em ordem na primeira vez.
            child: ListaEmOrdem(
              itens: [
                for (final (i, p) in lista.indexed)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: AppSpacing.md,
                          endIndent: AppSpacing.md,
                        ),
                      LinhaPartida(
                        partida: p,
                        agora: agora,
                        acesso: state.acesso,
                        onTap: () => _abrir(context, p),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
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
    final colors = theme.colorScheme;
    final plataforma = _plataforma;
    // Canvas DLigarConta: 32 dp dos lados.
    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.xl,
    );
    // Canvas DLigarConta: o bloco centrado na altura, com rolagem se não couber.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        key: TreinadorKeys.ligarConta,
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.maxHeight - padding.vertical,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.link,
                  size: AppIconSize.illustration,
                  color: colors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.treinadorLigarTituloConta,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.treinadorLigarTextoConta,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (plataforma == null) ...[
                  BusyButton(
                    buttonKey: TreinadorKeys.ligarLichess,
                    label: l.treinadorLigarBotao(
                      context.plataforma(Plataforma.lichess),
                    ),
                    onPressed: () =>
                        setState(() => _plataforma = Plataforma.lichess),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BusyButton(
                    buttonKey: TreinadorKeys.ligarChesscom,
                    style: BusyButtonStyle.outlined,
                    label: l.treinadorLigarBotao(
                      context.plataforma(Plataforma.chesscom),
                    ),
                    onPressed: () =>
                        setState(() => _plataforma = Plataforma.chesscom),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.treinadorLigarPrivacidade,
                    key: TreinadorKeys.ligarPrivacidade,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ] else
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
            ),
          ),
        ),
      ),
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
