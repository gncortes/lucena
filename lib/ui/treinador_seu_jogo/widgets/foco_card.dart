import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/treinador/abertura_no_curso.dart';
import '../../../domain/use_cases/treinador/resumo_seu_jogo.dart';
import '../../../routing/frentes/treinador_seu_jogo_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../view_models/curso_da_abertura_cubit.dart';
import 'seu_jogo_textos.dart';

/// "Onde focar agora": o ponto que mais pesa nas partidas, com a posição e,
/// quando a abertura é do Pilares, a ligação ao curso.
class FocoCard extends StatelessWidget {
  const FocoCard({required this.foco, super.key});

  final FocoSeuJogo foco;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final primaria = theme.colorScheme.primary;
    final (titulo, texto, botao, destino) = switch (foco) {
      FocoAbertura(:final abertura, :final saida) => (
        t.sjFocoAbertura,
        t.sjFocoAberturaTexto(
          abertura.nome,
          saida.vezes,
          abertura.aproveitamento.partidas,
          t.jogada(lance: saida.lance, pretas: saida.pretas, san: saida.san),
        ),
        t.sjFocoVerPosicao,
        SeuJogoPaths.teoriaDe(saida.partidaRecente),
      ),
      FocoTema(:final tema) => (
        t.temaNome(tema.tema),
        t.sjFocoTemaTexto(tema.posicoes.length),
        t.sjVerPosicoes,
        SeuJogoPaths.temaDe(tema.tema),
      ),
    };
    return DecoratedBox(
      key: SeuJogoKeys.foco,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: AppColors.cardOutline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShape.large),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: primaria, child: const SizedBox(width: 4)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            size: AppIconSize.compact,
                            color: primaria,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t.sjFocoTitulo,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: primaria,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        titulo,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(texto, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: SeuJogoKeys.focoVer,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(kButtonHeight),
                        ),
                        onPressed: () => context.push(destino),
                        child: Text(botao),
                      ),
                      if (foco case FocoAbertura(:final abertura, :final saida))
                        if (slotDaAbertura(
                              eco: abertura.eco,
                              nome: abertura.nome,
                              cor: abertura.cor,
                              curso: abertura.curso,
                            )
                            case final slot?)
                          BlocProvider(
                            key: ValueKey(slot),
                            create: (c) => CursoDaAberturaCubit(
                              training: c.read<TrainingRepository>(),
                              access: c.read<CourseAccessRepository>(),
                              slot: slot,
                              parte: abertura.curso?.parte,
                            )..load(),
                            child: _LigacaoAoCurso(
                              slot: slot,
                              parteDoServidor: abertura.curso?.parte,
                              lance: saida.lance,
                            ),
                          ),
                    ],
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

/// Com o Pilares: a parte em evidência nas metas de hoje. Sem o curso: a
/// abertura com cadeado e a oferta.
class _LigacaoAoCurso extends StatelessWidget {
  const _LigacaoAoCurso({
    required this.slot,
    required this.parteDoServidor,
    required this.lance,
  });

  final String slot;
  final int? parteDoServidor;
  final int lance;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CursoDaAberturaCubit>().state;
    final abertura = state.abertura;
    if (state.carregando || abertura == null) return const SizedBox.shrink();
    final t = context.l10n;
    final primaria = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: TextButton(
        key: SeuJogoKeys.focoCurso,
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        onPressed: () => context.push(
          state.temOCurso
              ? Routes.trainingGoals(
                  TrainingCourse.pilares.name,
                  destaque: abertura.destaque.licao.id,
                )
              : SeuJogoPaths.pilaresDe(
                  slot,
                  parte: parteDoServidor,
                  lance: parteDoServidor == null ? null : '$lance',
                ),
        ),
        child: Text(
          state.temOCurso
              ? t.sjFocoFazerParte(abertura.destaque.numero)
              : t.sjFocoEstudar,
          textAlign: TextAlign.center,
          style: TextStyle(color: primaria, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
