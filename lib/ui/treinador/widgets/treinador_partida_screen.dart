import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/treinador/treinador_regras.dart';
import '../../../routing/routes.dart';
import '../../core/keys/treinador_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/section_title.dart';
import '../view_models/curiosidades_cubit.dart';
import '../view_models/treinador_partida_cubit.dart';
import 'linha_partida.dart';
import 'treinador_screen.dart';
import 'treinador_textos.dart';

/// Uma partida do Treinador: o início, a espera da análise, o erro e o
/// resumo, conforme o status que o servidor gravou.
class TreinadorPartidaScreen extends StatelessWidget {
  const TreinadorPartidaScreen({super.key});

  static void voltar(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.treinador());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<TreinadorPartidaCubit, TreinadorPartidaState>(
      listenWhen: (a, b) => a.pedido != b.pedido,
      listener: (context, state) {
        final cubit = context.read<TreinadorPartidaCubit>();
        switch (state.pedido) {
          case PedidoAnalise.cota:
            cubit.pedidoVisto();
            unawaited(context.push(Routes.pilaresSale));
          case PedidoAnalise.recusado || PedidoAnalise.falhou:
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.pedido == PedidoAnalise.recusado
                        ? l.treinadorRecusado
                        : l.treinadorPedidoFalhou,
                  ),
                ),
              );
            cubit.pedidoVisto();
          case PedidoAnalise.nenhum || PedidoAnalise.enviando:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<TreinadorPartidaCubit>();
        if (state.carregando) {
          return LoadSkeletonScreen(title: l.treinadorInicioTitulo);
        }
        if (state.falhou) {
          return LoadErrorScreen(
            kind: LoadErrorKind.offline,
            onAction: cubit.tentarDeNovo,
            onBack: () => voltar(context),
          );
        }
        final partida = state.partida;
        if (partida == null) {
          return LoadErrorScreen(
            kind: LoadErrorKind.notFound,
            onAction: () => context.go(Routes.treinador()),
            onBack: () => voltar(context),
          );
        }
        final (titulo, corpo) = switch (partida.status) {
          StatusPartida.naFila || StatusPartida.analisando => (
            l.treinadorCarregandoTitulo,
            _Carregando(partida: partida, inicio: state.inicioAnalise),
          ),
          StatusPartida.erro => (
            l.treinadorInicioTitulo,
            _Erro(partida: partida),
          ),
          StatusPartida.pronta when _resumo(partida) => (
            l.treinadorResumoTitulo,
            _Resumo(partida: partida),
          ),
          _ => (
            l.treinadorInicioTitulo,
            _Inicio(partida: partida, state: state),
          ),
        };
        return Scaffold(
          key: TreinadorKeys.screen,
          appBar: LucenaAppBar(
            leading: BackButton(
              key: TreinadorKeys.back,
              onPressed: () => voltar(context),
            ),
            title: Text(titulo),
          ),
          body: SafeArea(top: false, child: corpo),
        );
      },
    );
  }

  /// Pronta e sem exercício a fazer: vai direto ao resumo.
  static bool _resumo(PartidaTreinador p) =>
      p.exercicios.isEmpty ||
      (p.progresso ?? ProgressoPartida.vazio).completo(p.exercicios.length);
}

/// "Sua partida": o cartão, como funciona e o botão de analisar (nova) ou
/// de começar os exercícios (pronta).
class _Inicio extends StatelessWidget {
  const _Inicio({required this.partida, required this.state});

  final PartidaTreinador partida;
  final TreinadorPartidaState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TreinadorPartidaCubit>();
    final pronta = partida.pronta;
    final feitos = partida.progresso?.feitos ?? 0;
    final total = partida.exercicios.length;
    return ListView(
      key: TreinadorKeys.inicio,
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        LucenaCard(
          key: TreinadorKeys.cartaoPartida,
          padding: EdgeInsets.zero,
          child: LinhaPartida(
            partida: partida,
            agora: context.read<Now>()(),
            acesso: state.acesso,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!pronta) ...[
          Text(l.treinadorComoFunciona, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final (i, passo) in [
            l.treinadorPasso1,
            l.treinadorPasso2,
            l.treinadorPasso3,
          ].indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(passo, style: theme.textTheme.bodyLarge),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          BusyButton(
            buttonKey: TreinadorKeys.comecar,
            label: l.treinadorAnalisar,
            busy: state.pedido == PedidoAnalise.enviando,
            onPressed: () => cubit.analisar(),
          ),
        ] else
          BusyButton(
            buttonKey: TreinadorKeys.comecar,
            label: feitos > 0
                ? l.treinadorContinuar(feitos, total)
                : l.treinadorComecar,
            onPressed: () =>
                unawaited(context.push(Routes.treinadorExercicios(partida.id))),
          ),
        const SizedBox(height: AppSpacing.sm),
        BusyButton(
          buttonKey: TreinadorKeys.verPartidas,
          style: BusyButtonStyle.text,
          label: l.treinadorVerPartidas,
          onPressed: () =>
              context.go(Routes.treinador(aba: AbaTreinador.partidas.name)),
        ),
      ],
    );
  }
}

/// A espera da análise: frase, porcentagem, curiosidade e "Me avise".
class _Carregando extends StatefulWidget {
  const _Carregando({required this.partida, required this.inicio});

  final PartidaTreinador partida;
  final DateTime? inicio;

  @override
  State<_Carregando> createState() => _CarregandoState();
}

class _CarregandoState extends State<_Carregando> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _frase(int p) {
    final l = context.l10n;
    if (p < 8) {
      return l.treinadorFraseBuscando(
        context.plataformaDaPartida(widget.partida),
      );
    }
    if (p < 25) return l.treinadorFraseRevendo;
    if (p < 45) return l.treinadorFraseOlhando;
    if (p < 65) return l.treinadorFraseMomentos;
    if (p < 80) return l.treinadorFraseSeparando;
    if (p < 90) return l.treinadorFrasePreparando;
    return l.treinadorFraseRetoques;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = PorcentagemDaEspera.de(widget.inicio, context.read<Now>()());
    return ListView(
      key: TreinadorKeys.carregando,
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          _frase(p),
          key: TreinadorKeys.carregandoFrase,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: p / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppShape.tiny),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 48,
              child: Text(
                l.treinadorPorcentagem(p),
                key: TreinadorKeys.carregandoPorcentagem,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        BlocBuilder<CuriosidadesCubit, CuriosidadesState>(
          builder: (context, c) {
            final atual = c.atual;
            if (atual == null) return const SizedBox.shrink();
            return LucenaCard(
              key: TreinadorKeys.curiosidade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.treinadorVoceSabia,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(atual.texto, style: theme.textTheme.bodyLarge),
                  if (c.todas.length > 1) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: BusyButton(
                        buttonKey: TreinadorKeys.outraCuriosidade,
                        style: BusyButtonStyle.text,
                        label: l.treinadorOutraCuriosidade,
                        onPressed: context.read<CuriosidadesCubit>().outra,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        BusyButton(
          buttonKey: TreinadorKeys.meAvise,
          style: BusyButtonStyle.tonal,
          label: l.treinadorMeAvise,
          onPressed: () {
            unawaited(context.read<TreinadorPartidaCubit>().meAvise());
            TreinadorPartidaScreen.voltar(context);
          },
        ),
      ],
    );
  }
}

/// A análise falhou no servidor.
class _Erro extends StatelessWidget {
  const _Erro({required this.partida});

  final PartidaTreinador partida;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<TreinadorPartidaCubit>();
    final podeRefazer = partida.podeRefazer;
    return Center(
      child: SingleChildScrollView(
        child: EmptyState(
          key: TreinadorKeys.erro,
          icon: Icons.error_outline,
          title: l.treinadorErroTitulo,
          message: podeRefazer ? l.treinadorErroTexto : l.treinadorErroVariante,
          actionLabel: podeRefazer ? l.loadErrorRetry : l.treinadorVerPartidas,
          actionKey: podeRefazer
              ? TreinadorKeys.erroTentar
              : TreinadorKeys.erroVoltar,
          onAction: podeRefazer
              ? () => unawaited(cubit.analisar())
              : () => context.go(
                  Routes.treinador(aba: AbaTreinador.partidas.name),
                ),
        ),
      ),
    );
  }
}

/// "Resumo da partida": precisão, exercícios, fases e posições-chave.
class _Resumo extends StatelessWidget {
  const _Resumo({required this.partida});

  final PartidaTreinador partida;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final progresso = partida.progresso ?? ProgressoPartida.vazio;
    final total = partida.exercicios.length;
    final brancas = partida.cor == CorPartida.brancas;
    Widget numero(Key key, String rotulo, String valor) => Expanded(
      child: LucenaCard(
        key: key,
        child: Column(
          children: [
            Text(valor, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
    final fases = [
      (l.treinadorFaseAbertura, partida.fases.abertura),
      (l.treinadorFaseMeio, partida.fases.meio),
      (l.treinadorFaseFinal, partida.fases.finalDaPartida),
    ].where((f) => f.$2 != null).toList();
    return ListView(
      key: TreinadorKeys.resumo,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Row(
            children: [
              numero(
                TreinadorKeys.resumoPrecisao,
                l.treinadorPrecisao,
                partida.precisao == null
                    ? '–'
                    : l.treinadorPrecisaoValor(partida.precisao!.round()),
              ),
              const SizedBox(width: AppSpacing.md),
              numero(
                TreinadorKeys.resumoExercicios,
                l.treinadorExercicios,
                total == 0
                    ? '–'
                    : l.treinadorEstadoCompleta(progresso.acertos, total),
              ),
            ],
          ),
        ),
        if (partida.resumo case final resumo?)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Text(resumo, style: theme.textTheme.bodyLarge),
          ),
        if (fases.isNotEmpty) ...[
          SectionTitle(l.treinadorPrecisaoPorFase),
          Padding(
            key: TreinadorKeys.resumoFases,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              children: [
                for (final (nome, valor) in fases)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(nome, style: theme.textTheme.bodyMedium),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (valor! / 100).clamp(0, 1),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(AppShape.tiny),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 44,
                          child: Text(
                            l.treinadorPrecisaoValor(valor.round()),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (partida.exercicios.isNotEmpty) ...[
          SectionTitle(l.treinadorPosicoesChave),
          for (final ex in partida.exercicios)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.xs,
              ),
              child: CourseItemTile(
                key: TreinadorKeys.posicaoChave(ex.n),
                state: _resultado(progresso, ex.n)
                    ? CourseItemState.approved
                    : CourseItemState.open,
                title: l.treinadorLance(ex.lance),
                summary: ex.tema,
                difficulty: ex.estrelas.clamp(1, 3),
                onTap: () => unawaited(
                  context.push(
                    Routes.treinadorAnalise(
                      partida.id,
                      lance: TreinadorRegras.meioLance(
                        ex.lance,
                        brancas: brancas,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BusyButton(
                buttonKey: TreinadorKeys.resumoAnalise,
                label: l.treinadorVerAnalise,
                onPressed: () => unawaited(
                  context.push(Routes.treinadorAnalise(partida.id)),
                ),
              ),
              if (partida.exercicios.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                BusyButton(
                  buttonKey: TreinadorKeys.refazer,
                  style: BusyButtonStyle.outlined,
                  label: l.treinadorRefazer,
                  onPressed: () => unawaited(
                    context.push(
                      Routes.treinadorExercicios(partida.id, refazer: true),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static bool _resultado(ProgressoPartida p, int n) =>
      p.resultados.any((r) => r.n == n && r.acertou);
}
