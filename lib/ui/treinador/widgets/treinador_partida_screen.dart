import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/treinador/treinador_regras.dart';
import '../../../routing/routes.dart';
import '../../core/keys/treinador_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../survey/view_models/viktor_thanks_cubit.dart';
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
        final enviando = state.pedido == PedidoAnalise.enviando;
        if (state.carregando) {
          return LoadSkeletonScreen(title: l.treinadorAnaliseTitulo);
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
            l.treinadorAnaliseTitulo,
            _Carregando(partida: partida, inicio: state.inicioAnalise),
          ),
          StatusPartida.erro => (
            l.treinadorAnaliseTitulo,
            _Erro(partida: partida, enviando: enviando),
          ),
          StatusPartida.pronta when _resumo(partida) => (
            l.treinadorResumoContra(partida.adversario.nome),
            _Resumo(partida: partida, state: state),
          ),
          _ => (
            l.treinadorAnaliseTitulo,
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
            // O nome do adversário quebra a linha, sem reticências.
            title: Text(
              titulo,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
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

/// "Análise da partida": o cartão da partida, o "Como funciona" e, presos no
/// pé, o botão de analisar (nova) ou de começar os exercícios (pronta) e a
/// volta à lista (canvas `DInicioNova` e `DInicio`).
class _Inicio extends StatelessWidget {
  const _Inicio({required this.partida, required this.state});

  final PartidaTreinador partida;
  final TreinadorPartidaState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<TreinadorPartidaCubit>();
    final pronta = partida.pronta;
    final feitos = partida.progresso?.feitos ?? 0;
    final total = partida.exercicios.length;
    final previstos = total > 0
        ? total
        : state.exerciciosPrevistos ??
              TreinadorConfig.padrao.exerciciosPorPartida;
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: TreinadorKeys.inicio,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.screen,
            ),
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
              const SizedBox(height: AppSpacing.lg),
              LucenaCard(
                key: TreinadorKeys.comoFunciona,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.treinadorComoFunciona,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Passo(
                      icon: Icons.extension,
                      titulo: l.treinadorPartidaPasso1Titulo(previstos),
                      texto: l.treinadorPartidaPasso1Texto,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Passo(
                      icon: Icons.timer,
                      titulo: l.treinadorPartidaPasso2Titulo,
                      texto: l.treinadorPartidaPasso2Texto,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Passo(
                      icon: Icons.analytics,
                      titulo: l.treinadorPartidaPasso3Titulo,
                      texto: l.treinadorPartidaPasso3Texto,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Rodape(
          children: [
            if (!pronta)
              BusyButton(
                buttonKey: TreinadorKeys.comecar,
                label: l.treinadorPartidaComecarAnalise,
                busy: state.pedido == PedidoAnalise.enviando,
                onPressed: () => cubit.analisar(),
              )
            else
              BusyButton(
                buttonKey: TreinadorKeys.comecar,
                label: feitos > 0
                    ? l.treinadorContinuar(feitos, total)
                    : l.treinadorComecar,
                onPressed: () => unawaited(
                  context.push(Routes.treinadorExercicios(partida.id)),
                ),
              ),
            BusyButton(
              buttonKey: TreinadorKeys.verPartidas,
              style: BusyButtonStyle.outlined,
              label: l.treinadorPartidaVerMinhas,
              onPressed: () =>
                  context.go(Routes.treinador(aba: AbaTreinador.partidas.name)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Os botões presos no pé da tela, um sobre o outro (canvas: 12 dp entre eles).
class _Rodape extends StatelessWidget {
  const _Rodape({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            c,
          ],
        ],
      ),
    );
  }
}

/// Um item do "Como funciona": o ícone num círculo de 40 dp, o título e o
/// texto (canvas `d_inicio`, `passo`).
class _Passo extends StatelessWidget {
  const _Passo({required this.icon, required this.titulo, required this.texto});

  /// O círculo do ícone no canvas.
  static const _circulo = 40.0;

  final IconData icon;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _circulo,
          height: _circulo,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: AppIconSize.notice,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: theme.textTheme.titleMedium),
              Text(
                texto,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A espera da análise (canvas `DCarregandoMeio`): frase e porcentagem, a
/// barra, o Viktor com a curiosidade e, no pé, a nota e "Me avise". Na fila
/// do grátis a barra corre sem número, porque a análise ainda não começou.
class _Carregando extends StatefulWidget {
  const _Carregando({required this.partida, required this.inicio});

  final PartidaTreinador partida;
  final DateTime? inicio;

  @override
  State<_Carregando> createState() => _CarregandoState();
}

class _CarregandoState extends State<_Carregando> {
  Timer? _timer;

  bool get _naFila => widget.partida.status == StatusPartida.naFila;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_naFila) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _frase(int p) {
    final l = context.l10n;
    if (_naFila) return l.treinadorFilaFrase;
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
    final muted = theme.colorScheme.onSurfaceVariant;
    final p = PorcentagemDaEspera.de(widget.inicio, context.read<Now>()());
    return Column(
      key: TreinadorKeys.carregando,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.screen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _frase(p),
                        key: TreinadorKeys.carregandoFrase,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (!_naFila) ...[
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        l.treinadorPorcentagem(p),
                        key: TreinadorKeys.carregandoPorcentagem,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedProgress(
                  key: TreinadorKeys.carregandoBarra,
                  value: _naFila ? null : p / 100,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _naFila
                      ? l.treinadorFilaSubtitulo
                      : l.treinadorEsperaSubtitulo,
                  key: _naFila
                      ? TreinadorKeys.carregandoFila
                      : TreinadorKeys.carregandoSubtitulo,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _Curiosidade(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.treinadorEsperaNota,
                key: TreinadorKeys.carregandoNota,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.md),
              BusyButton(
                buttonKey: TreinadorKeys.meAvise,
                style: BusyButtonStyle.outlined,
                label: l.treinadorMeAvise,
                onPressed: () {
                  unawaited(context.read<TreinadorPartidaCubit>().meAvise());
                  TreinadorPartidaScreen.voltar(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Você sabia?": a curiosidade dita pelo Viktor no balão das lições, os
/// pontos de paginação e "Outra curiosidade".
class _Curiosidade extends StatelessWidget {
  const _Curiosidade();

  /// Quantos pontos o canvas mostra (6 curiosidades); com o catálogo maior, o
  /// ponto ativo anda em círculo entre eles.
  static const _pontos = 6;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return BlocBuilder<CuriosidadesCubit, CuriosidadesState>(
      builder: (context, c) {
        final atual = c.atual;
        if (atual == null) return const SizedBox.shrink();
        final pontos = math.min(c.todas.length, _pontos);
        return Column(
          key: TreinadorKeys.curiosidade,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppShape.full),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: AppIconSize.compact,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l.treinadorVoceSabia,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<ViktorThanksCubit, Character?>(
              builder: (context, viktor) => viktor == null
                  ? Text(atual.texto, style: theme.textTheme.bodyLarge)
                  : TeacherSpeech(
                      speechContext: SpeechContext.teaching,
                      teacher: viktor,
                      text: atual.texto,
                    ),
            ),
            if (pontos > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      key: TreinadorKeys.curiosidadePontos,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (var i = 0; i < pontos; i++)
                          _Ponto(ativo: i == c.indice % pontos),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  BusyButton(
                    buttonKey: TreinadorKeys.outraCuriosidade,
                    style: BusyButtonStyle.outlined,
                    label: l.treinadorOutraCuriosidade,
                    onPressed: context.read<CuriosidadesCubit>().outra,
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Um ponto da paginação: o ativo é a pílula de 20 dp (canvas `lc-brota`).
class _Ponto extends StatelessWidget {
  const _Ponto({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppMotion.of(context).state,
      width: ativo ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: ativo ? colors.primary : colors.outlineVariant,
        borderRadius: BorderRadius.circular(AppShape.tiny),
      ),
    );
  }
}

/// A análise falhou no servidor.
class _Erro extends StatelessWidget {
  const _Erro({required this.partida, required this.enviando});

  final PartidaTreinador partida;

  /// O pedido de "Tentar de novo" está a caminho.
  final bool enviando;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<TreinadorPartidaCubit>();
    final podeRefazer = partida.podeRefazer;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              key: TreinadorKeys.erro,
              icon: Icons.error_outline,
              title: l.treinadorErroTitulo,
              message: podeRefazer
                  ? l.treinadorErroTexto
                  : l.treinadorErroVariante,
            ),
            // O botão fica fora do `EmptyState`, que não tem estado de envio.
            BusyButton(
              buttonKey: podeRefazer
                  ? TreinadorKeys.erroTentar
                  : TreinadorKeys.erroVoltar,
              style: BusyButtonStyle.tonal,
              label: podeRefazer ? l.loadErrorRetry : l.treinadorVerPartidas,
              busy: podeRefazer ? enviando : null,
              onPressed: podeRefazer
                  ? () => cubit.analisar()
                  : () => context.go(
                      Routes.treinador(aba: AbaTreinador.partidas.name),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O resumo da partida (canvas `DPartida`): o cartão da partida, os números,
/// as fases, as posições-chave e, presos no pé, os dois caminhos.
class _Resumo extends StatelessWidget {
  const _Resumo({required this.partida, required this.state});

  final PartidaTreinador partida;
  final TreinadorPartidaState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final progresso = partida.progresso ?? ProgressoPartida.vazio;
    final total = partida.exercicios.length;
    final fases = [
      (l.treinadorFaseAbertura, partida.fases.abertura),
      (l.treinadorFaseMeio, partida.fases.meio),
      (l.treinadorFaseFinal, partida.fases.finalDaPartida),
    ].where((f) => f.$2 != null).toList();
    final pior = fases.length > 1
        ? fases.map((f) => f.$2!).reduce(math.min)
        : null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: TreinadorKeys.resumo,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.screen,
            ),
            children: [
              LucenaCard(
                key: TreinadorKeys.resumoCartaoPartida,
                padding: EdgeInsets.zero,
                child: LinhaPartida(
                  partida: partida,
                  agora: context.read<Now>()(),
                  acesso: state.acesso,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Numero(
                      key: TreinadorKeys.resumoPrecisao,
                      rotulo: l.treinadorResumoSuaPrecisao,
                      valor: partida.precisao == null
                          ? l.treinadorResumoSemValor
                          : l.treinadorPrecisaoValor(partida.precisao!.round()),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _Numero(
                      key: TreinadorKeys.resumoExercicios,
                      rotulo: l.treinadorExercicios,
                      valor: total == 0
                          ? l.treinadorResumoSemValor
                          : l.treinadorResumoAcertosDeTotal(
                              progresso.acertos,
                              total,
                            ),
                      nota: total == 0 ? null : l.treinadorResumoExerciciosNota,
                    ),
                  ],
                ),
              ),
              if (partida.resumo case final resumo?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(resumo, style: Theme.of(context).textTheme.bodyLarge),
              ],
              if (fases.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _CartaoFases(fases: fases, pior: pior),
              ],
              if (partida.exercicios.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _CartaoPosicoes(partida: partida, progresso: progresso),
              ],
            ],
          ),
        ),
        _Rodape(
          children: [
            if (partida.exercicios.isNotEmpty)
              BusyButton(
                buttonKey: TreinadorKeys.refazer,
                label: l.treinadorRefazer,
                onPressed: () => unawaited(
                  context.push(
                    Routes.treinadorExercicios(partida.id, refazer: true),
                  ),
                ),
              ),
            BusyButton(
              buttonKey: TreinadorKeys.resumoAnalise,
              style: partida.exercicios.isNotEmpty
                  ? BusyButtonStyle.outlined
                  : BusyButtonStyle.filled,
              label: l.treinadorVerAnalise,
              onPressed: () =>
                  unawaited(context.push(Routes.treinadorAnalise(partida.id))),
            ),
          ],
        ),
      ],
    );
  }
}

/// Um número do resumo: valor grande, rótulo e nota opcional.
class _Numero extends StatelessWidget {
  const _Numero({
    required this.rotulo,
    required this.valor,
    this.nota,
    super.key,
  });

  final String rotulo;
  final String valor;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: LucenaCard(
        key: key,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valor, style: theme.textTheme.headlineSmall),
            Text(rotulo, style: theme.textTheme.titleSmall),
            if (nota case final nota?)
              Text(
                nota,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Precisão por fase": a fase mais fraca em azul cheio e as outras em azul
/// claro (canvas `fase`, decisão de 08/11: uma cor só nas barras).
class _CartaoFases extends StatelessWidget {
  const _CartaoFases({required this.fases, required this.pior});

  final List<(String, double?)> fases;
  final double? pior;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LucenaCard(
      key: TreinadorKeys.resumoFases,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.treinadorPrecisaoPorFase, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final (nome, valor) in fases)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(nome, style: theme.textTheme.titleSmall),
                      ),
                      Text(
                        l.treinadorPrecisaoValor(valor!.round()),
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedProgress(
                    value: (valor / 100).clamp(0, 1),
                    color: pior == null || valor == pior
                        ? colors.primary
                        : colors.primary.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Posições-chave": ✓/✗ do aparelho, "Lance N · tema" e o tipo do exercício.
/// Sem resultado neste aparelho (outro aparelho, reinstalação), nem ✓ nem ✗.
class _CartaoPosicoes extends StatelessWidget {
  const _CartaoPosicoes({required this.partida, required this.progresso});

  final PartidaTreinador partida;
  final ProgressoPartida progresso;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return LucenaCard(
      key: TreinadorKeys.resumoPosicoes,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              l.treinadorPosicoesChave,
              style: theme.textTheme.titleMedium,
            ),
          ),
          for (final (i, ex) in partida.exercicios.indexed) ...[
            if (i > 0) const Divider(height: 1),
            _LinhaPosicao(
              partida: partida,
              ex: ex,
              resultado: _resultado(progresso, ex.n),
            ),
          ],
        ],
      ),
    );
  }

  /// Nulo: sem resultado gravado neste aparelho.
  static bool? _resultado(ProgressoPartida p, int n) {
    for (final r in p.resultados) {
      if (r.n == n) return r.acertou;
    }
    return null;
  }
}

class _LinhaPosicao extends StatelessWidget {
  const _LinhaPosicao({
    required this.partida,
    required this.ex,
    required this.resultado,
  });

  final PartidaTreinador partida;
  final ExercicioTreinador ex;
  final bool? resultado;

  /// A altura mínima da linha no canvas.
  static const _altura = 52.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (icone, cor, rotulo) = switch (resultado) {
      true => (
        Icons.check_circle,
        AppColors.of(context).success,
        l.treinadorResumoAcertou,
      ),
      false => (Icons.cancel, colors.error, l.treinadorResumoErrou),
      null => (
        Icons.radio_button_unchecked,
        colors.outline,
        l.treinadorResumoSemResultado,
      ),
    };
    final tipo = switch (ex.tipo) {
      TipoExercicio.adversario => l.treinadorResumoTipoAdversario,
      TipoExercicio.profilaxia => l.treinadorResumoTipoProfilaxia,
      TipoExercicio.seuMelhor => l.treinadorResumoTipoSeuMelhor,
      TipoExercicio.decisivo => l.treinadorResumoTipoDecisivo,
    };
    final brancas = partida.cor == CorPartida.brancas;
    return InkWell(
      key: TreinadorKeys.posicaoChave(ex.n),
      onTap: () => unawaited(
        context.push(
          Routes.treinadorAnalise(
            partida.id,
            lance: TreinadorRegras.meioLance(ex.lance, brancas: brancas),
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _altura),
        child: Row(
          children: [
            Icon(
              icone,
              size: AppIconSize.button,
              color: cor,
              semanticLabel: rotulo,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.tema == null
                          ? l.treinadorLance(ex.lance)
                          : l.treinadorResumoLanceTema(
                              ex.lance,
                              nomeTemaTreinador(l, ex.tema)!,
                            ),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      tipo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
