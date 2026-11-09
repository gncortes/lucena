import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/pilares_before_home_cubit.dart';

/// A oferta antes do Início (H-VEN-15, quadro `PropV2OfertaAntesInicio`):
/// tela cheia com o X à esquerda (decisão de 03/11). O X e o voltar fecham e
/// deixam o Início; "Conhecer o plano" abre a venda do plano.
class PilaresBeforeHomeScreen extends StatelessWidget {
  const PilaresBeforeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final teacher = context.watch<PilaresBeforeHomeCubit>().state;
    final cubit = context.read<PilaresBeforeHomeCubit>();
    void close() {
      if (context.canPop()) {
        context.pop();
      } else {
        cubit.dismissed();
        context.go(Routes.home);
      }
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.dismissed();
      },
      // H-ANI-16: avatar, nome, título, os três itens e o botão entram em
      // cascata; o X de fechar fica fora e aparece já.
      child: EntradaDaTela(
        id: 'PropV2OfertaAntesInicio',
        child: Scaffold(
          key: PurchaseKeys.beforeHomeSheet,
          appBar: LucenaAppBar(
            leading: IconButton(
              key: PurchaseKeys.beforeHomeClose,
              tooltip: l10n.venBeforeHomeClose,
              icon: const Icon(Icons.close),
              onPressed: close,
            ),
          ),
          body: EntradaEmCascata(
            montar: (i) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.xl,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpacing.sm,
                            children: [i[0], i[1], i[2]],
                          ),
                          Column(
                            spacing: AppSpacing.lg,
                            children: [i[3], i[4], i[5]],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                i[6],
              ],
            ),
            itens: [
              ItemDaCascata.selo(_TeacherAvatar(teacher: teacher)),
              ItemDaCascata.texto(const _CourseName()),
              ItemDaCascata.titulo(
                Text(
                  l10n.venBeforeHomeTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ItemDaCascata.texto(
                _Item(icon: Icons.edit_calendar, title: l10n.venBeforeHomePlan),
              ),
              ItemDaCascata.texto(
                _Item(
                  icon: Icons.task_alt,
                  title: l10n.venBenefitGoals,
                  text: l10n.venBeforeHomeGoalsText,
                ),
              ),
              ItemDaCascata.texto(
                _Item(
                  icon: Icons.menu_book,
                  title: l10n.venBenefitChapters,
                  text: l10n.venBeforeHomeChaptersText,
                ),
              ),
              ItemDaCascata.botao(_LearnButton(cubit: cubit)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, this.text});

  final IconData icon;
  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      spacing: AppSpacing.lg,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Icon(icon, size: AppIconSize.standard, color: colors.primary),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (text != null)
                Text(
                  text!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    letterSpacing: 0,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// O avatar do professor (vazio até ele carregar).
class _TeacherAvatar extends StatelessWidget {
  const _TeacherAvatar({required this.teacher});

  final Character? teacher;

  @override
  Widget build(BuildContext context) {
    final teacher = this.teacher;
    return SizedBox.square(
      dimension: CharacterAvatar.versus,
      child: teacher == null
          ? null
          : CharacterAvatar(
              character: teacher,
              size: CharacterAvatar.versus,
              radius: AppSpacing.xl,
            ),
    );
  }
}

/// O nome do curso acima do título.
class _CourseName extends StatelessWidget {
  const _CourseName();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Text(
      l10n.venCourseName,
      style: theme.textTheme.titleSmall?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

/// O botão "Conhecer o plano": registra e abre a venda do plano.
class _LearnButton extends StatelessWidget {
  const _LearnButton({required this.cubit});

  final PilaresBeforeHomeCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: ActionsFooter(
        stacked: true,
        children: [
          BusyButton(
            buttonKey: PurchaseKeys.beforeHomeLearn,
            label: l10n.venBeforeHomeLearn,
            onPressed: () {
              cubit.learn();
              final router = GoRouter.of(context);
              if (context.canPop()) context.pop();
              router.push(D2Paths.plan(origin: PilaresBeforeHomeCubit.origin));
            },
          ),
        ],
      ),
    );
  }
}
