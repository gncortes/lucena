import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/treinador/seu_jogo_filtro_repository.dart';
import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/treinador/resumo_seu_jogo.dart';
import '../../../routing/frentes/treinador_seu_jogo_routes.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/chip_lucena.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/tip_box.dart';
import '../view_models/seu_jogo_cubit.dart';
import 'foco_card.dart';
import 'seu_jogo_pecas.dart';
import 'seu_jogo_textos.dart';

/// Cria o view model da aba com o que o app já registrou.
SeuJogoCubit criarSeuJogoCubit(BuildContext context) => SeuJogoCubit(
  repository: context.read<TreinadorRepository>(),
  filtro: context.read<SeuJogoFiltroRepository>(),
  now: context.read<Now>(),
)..load();

/// A aba Seu jogo em tela própria (aberta de fora do casco do Treinador).
class SeuJogoScreen extends StatelessWidget {
  const SeuJogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: SeuJogoKeys.screen,
      appBar: LucenaAppBar(title: Text(context.l10n.sjTitulo)),
      body: const SeuJogoAba(),
    );
  }
}

/// O corpo da aba Seu jogo, sem Scaffold, para o casco de três abas do
/// Treinador. Usa o [SeuJogoCubit] de cima, se houver; senão cria o seu.
class SeuJogoAba extends StatelessWidget {
  const SeuJogoAba({super.key});

  @override
  Widget build(BuildContext context) {
    final temCubit = context.select<SeuJogoCubit?, bool>((c) => c != null);
    if (temCubit) return const _Corpo();
    return BlocProvider(create: criarSeuJogoCubit, child: const _Corpo());
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SeuJogoCubit>().state;
    final resumo = state.resumo;
    return KeyedSubtree(
      key: SeuJogoKeys.aba,
      child: switch (state.status) {
        SeuJogoStatus.carregando => const Center(
          key: SeuJogoKeys.carregando,
          child: CircularProgressIndicator(),
        ),
        SeuJogoStatus.erro => LoadErrorScreen(
          key: SeuJogoKeys.erro,
          kind: LoadErrorKind.generic,
          onAction: () => context.read<SeuJogoCubit>().load(),
        ),
        SeuJogoStatus.pronto when resumo == null || state.partidas.isEmpty =>
          _SemPartidas(),
        SeuJogoStatus.pronto => _Lista(state: state, resumo: resumo!),
      },
    );
  }
}

class _SemPartidas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          key: SeuJogoKeys.vazio,
          icon: Icons.insights,
          title: t.sjVazioTitulo,
          message: t.sjVazioTexto,
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.state, required this.resumo});

  final SeuJogoState state;
  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final plataforma = t.plataformaNome(state.plataforma);
    final semNoRitmo = resumo.partidas == 0;
    final itens = <Widget>[
      _Ritmos(ritmo: state.ritmo),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Text(
          semNoRitmo
              ? t.sjVazioRitmo(t.ritmoNome(state.ritmo))
              : resumo.poucas
              ? t.sjBasePoucas(resumo.partidas, plataforma)
              : t.sjBase(resumo.partidas, plataforma),
          key: SeuJogoKeys.base,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      if (semNoRitmo)
        const SizedBox.shrink()
      else if (resumo.poucas) ...[
        _EstiloCard(state: state, resumo: resumo),
        _PrecisaoMedia(resumo: resumo),
        TipBox(key: SeuJogoKeys.poucasAviso, text: t.sjPoucasAviso),
      ] else ...[
        _Numeros(resumo: resumo),
        if (resumo.foco case final foco?) FocoCard(foco: foco),
        _Fases(resumo: resumo),
        _Semanas(resumo: resumo),
        _EstiloCard(state: state, resumo: resumo),
        if (resumo.temas.isNotEmpty) _Temas(resumo: resumo),
        if (resumo.ritmos.isNotEmpty) _RitmosAproveitamento(resumo: resumo),
        _Cores(resumo: resumo),
        if (resumo.aberturas.isNotEmpty) _Aberturas(resumo: resumo),
        if (_aberturaDosModelos(resumo) case final a?)
          _LinkModelos(abertura: a),
      ],
    ];
    return ListView.separated(
      key: const PageStorageKey('seuJogo.lista'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: itens.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => itens[i],
    );
  }
}

/// As partidas-modelo da abertura do foco; sem foco de abertura, da mais
/// jogada.
ResumoAbertura? _aberturaDosModelos(ResumoSeuJogo resumo) {
  if (resumo.foco case FocoAbertura(:final abertura)) return abertura;
  return resumo.aberturas.firstOrNull;
}

class _Ritmos extends StatelessWidget {
  const _Ritmos({required this.ritmo});

  final Ritmo? ritmo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final r in <Ritmo?>[null, ...Ritmo.values])
          ChipLucena(
            key: SeuJogoKeys.ritmo(r?.wire ?? 'todos'),
            label: Text(t.ritmoNome(r)),
            selecionado: r == ritmo,
            aoEscolher: (_) => context.read<SeuJogoCubit>().escolherRitmo(r),
          ),
      ],
    );
  }
}

/// Os três números do alto: precisão, aproveitamento e a fase com mais erros.
class _Numeros extends StatelessWidget {
  const _Numeros({required this.resumo});

  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variacao = resumo.variacaoPrecisao;
    final fase = resumo.faseMaisErros;
    final borda = BorderSide(color: theme.colorScheme.outlineVariant);
    return DecoratedBox(
      key: SeuJogoKeys.numeros,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: AppColors.cardOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Numero(
                  key: SeuJogoKeys.precisao,
                  valor: resumo.precisao == null
                      ? t.sjSemValor
                      : t.sjPorcento(resumo.precisao!),
                  rotulo: t.sjNumPrecisao,
                  detalhe: variacao == null || variacao == 0
                      ? null
                      : _Variacao(pontos: variacao),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border(left: borda)),
                  child: _Numero(
                    key: SeuJogoKeys.aproveitamento,
                    valor: t.sjPorcento(resumo.aproveitamento.porcento),
                    rotulo: t.sjNumAproveitamento,
                    detalhe: _Pequeno(
                      t.sjNumVitorias(resumo.aproveitamento.vitorias),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border(left: borda)),
                  child: _Numero(
                    key: SeuJogoKeys.errosFase,
                    valor: '${fase == null ? 0 : resumo.errosPorFase[fase]}',
                    rotulo: fase == null
                        ? t.sjNumSemErros
                        : t.sjNumErrosNa(t.faseChave(fase)),
                    detalhe: fase == null ? null : _Pequeno(t.sjNumMaisAlto),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.valor,
    required this.rotulo,
    this.detalhe,
    super.key,
  });

  final String valor, rotulo;
  final Widget? detalhe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          _Pequeno(rotulo),
          ?detalhe,
        ],
      ),
    );
  }
}

class _Pequeno extends StatelessWidget {
  const _Pequeno(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class _Variacao extends StatelessWidget {
  const _Variacao({required this.pontos});

  final int pontos;

  @override
  Widget build(BuildContext context) {
    final subiu = pontos > 0;
    final cor = subiu ? AppColors.successOnSurface : AppColors.trainingDayWrong;
    return Row(
      children: [
        Icon(
          subiu ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: cor,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            context.l10n.sjNumVariacao(pontos.abs()),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cor, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _Fases extends StatelessWidget {
  const _Fases({required this.resumo});

  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final maior = resumo.errosPorFase.values.fold(0, (a, b) => a > b ? a : b);
    return SecaoSeuJogo(
      key: SeuJogoKeys.fases,
      titulo: t.sjFasesTitulo,
      valor: t.sjPartidas(resumo.partidas),
      child: Column(
        children: [
          for (final f in FaseDoJogo.values)
            LinhaComBarra(
              key: SeuJogoKeys.fase(t.faseChave(f)),
              rotulo: t.faseNome(f),
              valor: t.sjErros(resumo.errosPorFase[f] ?? 0),
              fracao: maior == 0 ? 0 : (resumo.errosPorFase[f] ?? 0) / maior,
              destaque: f == resumo.faseMaisErros,
            ),
        ],
      ),
    );
  }
}

class _Semanas extends StatelessWidget {
  const _Semanas({required this.resumo});

  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final valores = [for (final v in resumo.precisaoSemanas) ?v];
    final menor = valores.isEmpty ? 0 : valores.reduce((a, b) => a < b ? a : b);
    final maior = valores.isEmpty ? 0 : valores.reduce((a, b) => a > b ? a : b);
    final ultima = resumo.precisaoSemanas.lastIndexWhere((v) => v != null);
    final semanas = resumo.precisaoSemanas;
    return SecaoSeuJogo(
      key: SeuJogoKeys.semanas,
      titulo: t.sjSemanasTitulo,
      valor: t.sjSemanasUltimas(semanas.length),
      child: SizedBox(
        height: 52,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, v) in semanas.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: v == null
                      ? t.sjSemanaSemPartida(semanas.length - i)
                      : t.sjSemanaPrecisao(semanas.length - i, v),
                  child: Container(
                    height: v == null
                        ? 4
                        : maior == menor
                        ? 40
                        : 16 + 36 * (v - menor) / (maior - menor),
                    decoration: BoxDecoration(
                      color: v == null
                          ? AppColors.sheetSurface
                          : i == ultima
                          ? Theme.of(context).colorScheme.primary
                          : corSuave(context),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.xs),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// O cartão do estilo (leitura do servidor) que abre a tela do estilo.
class _EstiloCard extends StatelessWidget {
  const _EstiloCard({required this.state, required this.resumo});

  final SeuJogoState state;
  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final estilo = state.estatisticas.estilo;
    final partidas = state.estatisticas.partidasAnalisadas > 0
        ? state.estatisticas.partidasAnalisadas
        : resumo.partidas;
    final texto = t.estiloResumo(estilo);
    return Material(
      color: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.large),
        side: const BorderSide(color: AppColors.cardOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: SeuJogoKeys.estilo,
        onTap: () => context.push(SeuJogoPaths.estilo),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    size: AppIconSize.notice,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      t.sjEstiloTitulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      t.sjEstiloNivel(t.nivelNome(estilo.nivel), partidas),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: AppIconSize.button,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(texto, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Poucas partidas: só a precisão média.
class _PrecisaoMedia extends StatelessWidget {
  const _PrecisaoMedia({required this.resumo});

  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return SecaoSeuJogo(
      key: SeuJogoKeys.poucas,
      titulo: t.sjPoucasPrecisaoTitulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resumo.precisao == null
                ? t.sjSemValor
                : t.sjPorcento(resumo.precisao!),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          _Pequeno(t.sjPoucasPrecisaoTexto(resumo.partidas)),
        ],
      ),
    );
  }
}

class _Temas extends StatelessWidget {
  const _Temas({required this.resumo});

  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return SecaoSeuJogo(
      key: SeuJogoKeys.temas,
      titulo: t.sjTemasTitulo,
      child: Column(
        children: [
          for (final tema in resumo.temas)
            InkWell(
              key: SeuJogoKeys.tema(tema.tema),
              borderRadius: BorderRadius.circular(AppShape.small),
              onTap: () => context.push(SeuJogoPaths.temaDe(tema.tema)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.temaNome(tema.tema),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (t.sjTemaDescricao(tema.tema) case final d
                                when d.isNotEmpty)
                              _Pequeno(d),
                          ],
                        ),
                      ),
                      Text(
                        '${tema.posicoes.length}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: AppIconSize.button,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RitmosAproveitamento extends StatelessWidget {
  const _RitmosAproveitamento({required this.resumo});

  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final ritmos = [
      for (final r in Ritmo.values)
        if (resumo.ritmos[r] case final a?) (r, a),
    ];
    final maior = ritmos.fold(
      0,
      (m, e) => e.$2.porcento > m ? e.$2.porcento : m,
    );
    return SecaoSeuJogo(
      key: SeuJogoKeys.ritmos,
      titulo: t.sjRitmosTitulo,
      subtitulo: t.sjRitmosSubtitulo,
      child: Column(
        children: [
          for (final (r, a) in ritmos)
            LinhaComBarra(
              rotulo: t.ritmoNome(r),
              detalhe: t.sjPartidas(a.partidas),
              valor: t.sjPorcento(a.porcento),
              fracao: a.porcento / 100,
              destaque: ritmos.length > 1 && a.porcento == maior,
            ),
        ],
      ),
    );
  }
}

class _Cores extends StatelessWidget {
  const _Cores({required this.resumo});

  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    Widget cor(CorPartida c, Aproveitamento a) => Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sheetSurface,
          borderRadius: BorderRadius.circular(AppShape.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.partidas == 0 ? t.sjSemValor : t.sjPorcento(a.porcento),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                t.corNome(c),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              _Pequeno(t.sjPartidas(a.partidas)),
            ],
          ),
        ),
      ),
    );
    return SecaoSeuJogo(
      key: SeuJogoKeys.cores,
      titulo: t.sjCoresTitulo,
      child: Row(
        children: [
          cor(CorPartida.brancas, resumo.brancas),
          const SizedBox(width: AppSpacing.sm),
          cor(CorPartida.pretas, resumo.pretas),
        ],
      ),
    );
  }
}

class _Aberturas extends StatelessWidget {
  const _Aberturas({required this.resumo});

  final ResumoSeuJogo resumo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final erro = theme.colorScheme.error;
    return SecaoSeuJogo(
      key: SeuJogoKeys.aberturas,
      titulo: t.sjAberturasTitulo,
      child: Column(
        children: [
          for (final (i, a) in resumo.aberturas.take(5).indexed)
            Padding(
              key: SeuJogoKeys.abertura(i),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinhaDaAbertura(abertura: a),
                  if (a.saida case final s?)
                    InkWell(
                      key: SeuJogoKeys.aberturaSaida(i),
                      onTap: () =>
                          context.push(SeuJogoPaths.teoriaDe(s.partidaRecente)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 40),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error,
                              size: AppIconSize.small,
                              color: erro,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                t.sjAberturaSaida(s.lance, s.vezes),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: erro,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: AppIconSize.button,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
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

/// Nome, cor, partidas, aproveitamento e a barra do placar de uma abertura.
class LinhaDaAbertura extends StatelessWidget {
  const LinhaDaAbertura({required this.abertura, super.key});

  final ResumoAbertura abertura;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final a = abertura.aproveitamento;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    abertura.nome,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _Pequeno(
                    t.sjAberturaCorPartidas(
                      t.corNome(abertura.cor),
                      a.partidas,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              t.sjPorcento(a.porcento),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        BarraDoPlacar(
          vitorias: a.vitorias,
          empates: a.empates,
          derrotas: a.derrotas,
        ),
        const SizedBox(height: AppSpacing.xs),
        _Pequeno(t.sjAberturaPlacar(a.vitorias, a.empates, a.derrotas)),
      ],
    );
  }
}

class _LinkModelos extends StatelessWidget {
  const _LinkModelos({required this.abertura});

  final ResumoAbertura abertura;

  @override
  Widget build(BuildContext context) {
    final primaria = Theme.of(context).colorScheme.primary;
    return InkWell(
      key: SeuJogoKeys.modelosLink,
      onTap: () => context.push(
        SeuJogoPaths.modelosDe(abertura.eco, nome: abertura.nome),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: AppIconSize.compact,
                color: primaria,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.sjModelosDe(abertura.nome),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: primaria, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppIconSize.button,
                color: primaria,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
