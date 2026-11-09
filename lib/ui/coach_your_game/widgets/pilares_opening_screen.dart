import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/use_cases/coach/opening_in_pilares.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../core/keys/coach_your_game_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/highlight_card.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/opening_course_cubit.dart';
import '../../core/theme/app_text.dart';

/// A abertura do ponto fraco no Pilares, para quem não tem o curso: as partes
/// com cadeado, a que trata do ponto fraco em destaque e a oferta.
class PilaresOpeningScreen extends StatelessWidget {
  const PilaresOpeningScreen({
    required this.slot,
    this.part,
    this.chessMove,
    super.key,
  });

  final String slot;

  /// A parte e o lance que o servidor ligou à saída da teoria.
  final int? part;
  final String? chessMove;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) =>
          createOpeningCourseCubit(c, slot: slot, part: part)..load(),
      child: Scaffold(
        key: YourGameKeys.pilaresScreen,
        appBar: LucenaAppBar(
          title: Text(context.l10n.sjSlotNome(slot)),
          centerTitle: true,
        ),
        body: BlocBuilder<OpeningCourseCubit, OpeningCourseState>(
          builder: (context, state) {
            final opening = state.opening;
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (opening == null) {
              return EmptyState(
                icon: Icons.menu_book_outlined,
                message: context.l10n.sjPilaresSemAbertura,
              );
            }
            return _List(opening: opening, part: part, chessMove: chessMove);
          },
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.opening, this.part, this.chessMove});

  final OpeningInPilares opening;
  final int? part;
  final String? chessMove;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final perfil = opening.perfil == 'solido'
        ? t.trainingProfileSolid
        : t.trainingProfileAggressive;
    final color = t.sjSlotCor(opening.slot);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(
          t.sjPilaresLinha(t.trainingPilaresTitle, perfil, color),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: AppWeight.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final p in opening.parts) ...[
          _LockedPart(part: p, highlight: identical(p, opening.highlight)),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        // O mesmo cartão azul de destaque do "Seu estilo" (componente único).
        HighlightCard(
          key: YourGameKeys.pilaresOffer,
          icon: Icons.lock_outline,
          title: t.sjPilaresOfertaTitulo(t.sjSlotNome(opening.slot)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [
                  t.sjPilaresOfertaTexto,
                  if (part != null && chessMove != null)
                    t.sjPilaresOfertaParte(
                      opening.highlight.number,
                      chessMove!,
                    ),
                ].join(' '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                key: YourGameKeys.pilaresDiscover,
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
class _LockedPart extends StatelessWidget {
  const _LockedPart({required this.part, required this.highlight});

  final OpeningPart part;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tile = CourseItemTile(
      key: YourGameKeys.pilaresPart(part.lessonEntry.id),
      state: CourseItemState.locked,
      title: context.l10n.sjPilaresParte(part.number),
      // Canvas DPilaresEslava: cada parte com 1 linha (o título curto da
      // lição), para a oferta caber na primeira tela.
      summary: part.lessonEntry.title,
    );
    if (!highlight) return tile;
    return DecoratedBox(
      key: YourGameKeys.pilaresHighlight,
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
