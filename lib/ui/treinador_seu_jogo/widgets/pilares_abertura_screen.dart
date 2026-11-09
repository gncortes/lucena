import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/use_cases/treinador/abertura_no_pilares.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/cartao_destaque.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/curso_da_abertura_cubit.dart';
import '../../core/theme/app_text.dart';

/// A abertura do ponto fraco no Pilares, para quem não tem o curso: as partes
/// com cadeado, a que trata do ponto fraco em destaque e a oferta.
class PilaresAberturaScreen extends StatelessWidget {
  const PilaresAberturaScreen({
    required this.slot,
    this.parte,
    this.lance,
    super.key,
  });

  final String slot;

  /// A parte e o lance que o servidor ligou à saída da teoria.
  final int? parte;
  final String? lance;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) =>
          createOpeningCourseCubit(c, slot: slot, parte: parte)..load(),
      child: Scaffold(
        key: SeuJogoKeys.pilaresScreen,
        appBar: LucenaAppBar(
          title: Text(context.l10n.sjSlotNome(slot)),
          centerTitle: true,
        ),
        body: BlocBuilder<CursoDaAberturaCubit, CursoDaAberturaState>(
          builder: (context, state) {
            final abertura = state.abertura;
            if (state.carregando) {
              return const Center(child: CircularProgressIndicator());
            }
            if (abertura == null) {
              return EmptyState(
                icon: Icons.menu_book_outlined,
                message: context.l10n.sjPilaresSemAbertura,
              );
            }
            return _Lista(abertura: abertura, parte: parte, lance: lance);
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.abertura, this.parte, this.lance});

  final AberturaNoPilares abertura;
  final int? parte;
  final String? lance;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final perfil = abertura.perfil == 'solido'
        ? t.trainingProfileSolid
        : t.trainingProfileAggressive;
    final cor = t.sjSlotCor(abertura.slot);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(
          t.sjPilaresLinha(t.trainingPilaresTitle, perfil, cor),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: AppWeight.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final p in abertura.partes) ...[
          _ParteComCadeado(parte: p, destaque: identical(p, abertura.destaque)),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        // O mesmo cartão azul de destaque do "Seu estilo" (componente único).
        CartaoDestaque(
          key: SeuJogoKeys.pilaresOferta,
          icon: Icons.lock_outline,
          title: t.sjPilaresOfertaTitulo(t.sjSlotNome(abertura.slot)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [
                  t.sjPilaresOfertaTexto,
                  if (parte != null && lance != null)
                    t.sjPilaresOfertaParte(abertura.destaque.numero, lance!),
                ].join(' '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                key: SeuJogoKeys.pilaresConhecer,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(kButtonHeight),
                ),
                onPressed: () =>
                    context.push(D2Paths.plan(origin: 'treinador')),
                child: Text(t.sjPilaresConhecer),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A parte com cadeado; a do ponto fraco ganha o anel azul.
class _ParteComCadeado extends StatelessWidget {
  const _ParteComCadeado({required this.parte, required this.destaque});

  final ParteDaAbertura parte;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final tile = CourseItemTile(
      key: SeuJogoKeys.pilaresParte(parte.licao.id),
      state: CourseItemState.locked,
      title: context.l10n.sjPilaresParte(parte.numero),
      // Canvas DPilaresEslava: cada parte com 1 linha (o título curto da
      // lição), para a oferta caber na primeira tela.
      summary: parte.licao.title,
    );
    if (!destaque) return tile;
    return DecoratedBox(
      key: SeuJogoKeys.pilaresDestaque,
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppShape.card),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: tile,
    );
  }
}
