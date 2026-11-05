import 'package:flutter/material.dart';

import '../../core/motion/barra_que_enche.dart';
import '../../core/motion/lucena_motion.dart';
import '../../core/motion/valor_que_anima.dart';

import '../../../domain/models/training/plan_event.dart';
import '../../core/keys/course_guide_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';

/// A faixa do plano acima do cartão da lição (canvas `PropV2LicaoEntradaPlano`):
/// o torneio, a semana, os dias que faltam e uma barra por semana. Tocar abre
/// o plano ([onTap]). Só aparece com plano criado.
class LicaoPlanBand extends StatelessWidget {
  const LicaoPlanBand({
    required this.event,
    required this.now,
    required this.onTap,
    super.key,
  });

  final PlanEvent event;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      key: CourseGuideKeys.licaoPlanBand,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Row(
              spacing: 12,
              children: [
                Icon(Icons.stadium_outlined, color: colors.primary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // H-ANI-18: os dias que faltam contam na entrada. A
                      // contagem começa em 1 para não passar por "é hoje".
                      ValorQueAnima(
                        valor: event.daysLeft(now).toDouble(),
                        duracao: LucenaMotion.numeroConta,
                        builder: (context, agora) {
                          final fim = event.daysLeft(now);
                          final dias = fim == 0
                              ? 0
                              : agora.round().clamp(1, fim);
                          return Text(
                            context.l10n.licaoPlanProgress(
                              event.weekAt(now),
                              event.totalWeeks,
                              dias,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
            Row(
              spacing: 4,
              children: [
                for (final fraction in event.weekFractions(now))
                  Expanded(
                    // H-ANI-13: cada semana enche de 0 na entrada.
                    child: BarraQueEnche(
                      valor: fraction,
                      altura: 6,
                      corDoTrilho: colors.outlineVariant,
                      cor: fraction >= 1
                          ? AppColors.trainingDayCorrect
                          : colors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
