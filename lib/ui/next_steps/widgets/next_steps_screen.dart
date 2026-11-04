import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/next_steps_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/shimmer_conteudo.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/view_models/course_availability_cubit.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/skeleton.dart';
import '../../home/widgets/path_card.dart';

/// Os próximos passos depois do "Seu nível" ou da Escola concluída (canvas
/// `PropV1InicioProximosPassos`): o Pilares do Xadrez recomendado, Problemas,
/// Treinar finais e Jornada. Sem lição liberada (ou com a leitura falhando) a
/// lista sai sem o Pilares, sem tela de erro. Enquanto o app confere, quatro
/// blocos em esqueleto: a lista só aparece com a resposta.
class NextStepsScreen extends StatelessWidget {
  const NextStepsScreen({this.courseAvailable = _always, super.key});

  /// Quadro do canvas, para a primeira entrada da sessão.
  static const nextStepsEntranceId = 'PropV1InicioProximosPassos';

  /// Há lição liberada. Sem ela, o Pilares não aparece.
  final Future<bool> Function() courseAvailable;

  static Future<bool> _always() async => true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CourseAvailabilityCubit(courseAvailable)..load(),
      child: BlocBuilder<CourseAvailabilityCubit, bool?>(
        builder: (context, course) => _screen(context, course),
      ),
    );
  }

  Widget _screen(BuildContext context, bool? course) {
    final l10n = context.l10n;
    void go(String route) => context.go(route);
    final steps = [
      if (course ?? false)
        PathCard(
          key: NextStepsKeys.option('pilares'),
          icon: Icons.auto_stories,
          title: l10n.homeEndgames,
          body: l10n.homeShortcutEndgamesBody,
          badge: l10n.nextStepsRecommended,
          // Quem não comprou cai na venda; a Venda decide a troca pelo plano
          // para quem já tem o Pilares.
          onTap: () => go(Routes.pilaresSale),
        ),
      PathCard(
        key: NextStepsKeys.option('race'),
        icon: Icons.extension,
        title: l10n.homeRace,
        body: l10n.homeShortcutRaceBody,
        onTap: () => go(Routes.race),
      ),
      PathCard(
        key: NextStepsKeys.option('train'),
        icon: Icons.grid_view,
        title: l10n.homeTrain,
        body: l10n.homeShortcutTrainBody,
        onTap: () => go(Routes.catalog),
      ),
      PathCard(
        key: NextStepsKeys.option('journey'),
        icon: Icons.hiking,
        title: l10n.homeJourney,
        body: l10n.homeShortcutJourneyBody,
        onTap: () => go(Routes.journey),
      ),
    ];
    return EntradaDaTela(
      id: NextStepsScreen.nextStepsEntranceId,
      child: Scaffold(
        key: NextStepsKeys.screen,
        appBar: LucenaAppBar(
          leading: IconButton(
            key: NextStepsKeys.back,
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => go(Routes.home),
          ),
          title: Text(l10n.nextStepsTitle),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                ),
                children: [
                  ShimmerConteudo(
                    carregando: course == null,
                    esqueleto: Column(
                      key: NextStepsKeys.loading,
                      spacing: AppSpacing.sm,
                      children: [
                        for (var i = 0; i < 4; i++)
                          const SkeletonBlock(
                            height: 72,
                            radius: AppShape.large,
                          ),
                      ],
                    ),
                    child: course == null
                        ? const SizedBox.shrink()
                        : EntradaEmCascata(
                            itens: [
                              for (final step in steps)
                                ItemDaCascata.texto(step),
                            ],
                            montar: (itens) => Column(
                              key: NextStepsKeys.block,
                              spacing: AppSpacing.sm,
                              children: itens,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            ActionsFooter(
              children: [
                TextButton(
                  key: NextStepsKeys.home,
                  onPressed: () => go(Routes.home),
                  child: Text(l10n.nextStepsHome),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
