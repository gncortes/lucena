import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/use_cases/treinador/abertura_no_curso.dart';
import '../../../domain/use_cases/treinador/abertura_no_pilares.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/tip_box.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';

/// A abertura e o número da parte da lição [lessonId] no Pilares, quando ela
/// é parte de uma abertura do curso.
({String slot, int numero})? _parteDaLicao(
  String lessonId,
  TrainingResources resources,
) {
  final licao = resources.lessons.where((l) => l.id == lessonId).firstOrNull;
  if (licao == null) return null;
  final slot =
      resources.openings[lessonId]?.firstOrNull?.openingId ??
      slotDaLicao(lessonId);
  final abertura = aberturaNoPilares(slot: slot, resources: resources);
  final parte = abertura?.partes
      .where((p) => p.licao.id == lessonId)
      .firstOrNull;
  if (parte == null) return null;
  return (slot: slot, numero: parte.numero);
}

/// No alto das Metas de hoje: a lição do Pilares que o Treinador de partidas
/// mandou estudar, com o aviso de onde ela veio.
class MetasDestaqueTreinador extends StatelessWidget {
  const MetasDestaqueTreinador({
    required this.lessonId,
    required this.onOpen,
    super.key,
  });

  final String lessonId;
  final ValueChanged<TrainingLesson> onOpen;

  @override
  Widget build(BuildContext context) {
    final resources = context.select<CourseGuideCubit, TrainingResources?>(
      (c) => c.state.resources,
    );
    final lesson = resources?.lessons
        .where((l) => l.id == lessonId)
        .firstOrNull;
    if (resources == null || lesson == null) return const SizedBox.shrink();
    final t = context.l10n;
    final theme = Theme.of(context);
    // Canvas DMetasEslava: "{abertura} · Parte {n}" e, embaixo, só o título
    // curto da lição (1 linha), para não empurrar o resto das metas.
    final parte = _parteDaLicao(lessonId, resources);
    return Column(
      key: SeuJogoKeys.metasDestaque,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TipBox(
          key: SeuJogoKeys.metasDestaqueAviso,
          text: t.sjMetasDestaqueAviso,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.sjMetasDestaqueSecao,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CourseItemTile(
          key: SeuJogoKeys.metasDestaqueParte,
          state: CourseItemState.next,
          title: parte == null
              ? lesson.title
              : t.sjMetasDestaqueTitulo(t.sjSlotNome(parte.slot), parte.numero),
          summary: parte == null ? null : lesson.title,
          onTap: () => onOpen(lesson),
        ),
      ],
    );
  }
}
