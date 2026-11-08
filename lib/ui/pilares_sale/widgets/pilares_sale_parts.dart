import 'package:flutter/material.dart';

import '../../core/motion/cartao_de_plano.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';

/// Peças da venda do Pilares (T85, frente D2). Ficam dentro da frente até a
/// junção decidir se sobem para `core` (registro na PR).

/// O rótulo de seção e o cartão com as linhas ícone, título e texto ("O que
/// você leva", "O que continua com você"). Oferta, fim da demo e assinatura
/// encerrada usam o mesmo.
class PilaresBenefitSection extends StatelessWidget {
  const PilaresBenefitSection({
    required this.label,
    required this.items,
    this.compact = false,
    super.key,
  });

  final String label;
  final List<(IconData, String, String)> items;

  /// O cartão mais justo do fim da demonstração (`PropV2DemoOferta`):
  /// margem 12, 8 entre os itens, ícone centrado e título 16/24.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppShape.card),
            border: Border.all(color: AppColors.cardOutline),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
            child: Column(
              children: [
                for (final (index, (icon, title, text)) in items.indexed) ...[
                  if (index > 0)
                    SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                  Row(
                    crossAxisAlignment: compact
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Icon(
                        icon,
                        color: colors.primary,
                        size: AppIconSize.standard,
                      ),
                      SizedBox(width: compact ? AppSpacing.lg : AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: compact
                                  ? theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 16,
                                      height: 24 / 16,
                                      fontWeight: FontWeight.w500,
                                    )
                                  : theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// O cartão de um plano na oferta (H-VEN-03): radio à esquerda, raio 20,
/// contorno 2 px primário quando marcado.
class PilaresPlanCard extends StatelessWidget {
  const PilaresPlanCard({
    required this.title,
    required this.text,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
    this.badgeKey,
    this.loading = false,
    super.key,
  });

  final String title;
  final String text;
  final String price;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;
  final Key? badgeKey;

  /// A loja ainda não devolveu o preço: o valor pisca.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // H-ANI-26: contorno, fundo e ponto do rádio trocam em 250 ms.
    return CartaoDePlano(
      selecionado: selected,
      aoTocar: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (badge case final badge?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    key: badgeKey,
                    height: 22,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: colors.primaryContainer,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontSize: 12,
                        height: 1,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AnimatedOpacity(
            opacity: loading ? 0.3 : 1,
            duration: AppMotion.state,
            child: Text(
              price,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// O cartão de texto com linhas (o "Como funciona a assinatura").
class PilaresInfoCard extends StatelessWidget {
  const PilaresInfoCard({required this.title, required this.lines, super.key});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: AppColors.cardOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            for (final line in lines) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                line,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// O aviso no topo (erro da compra, sem internet, "não achou"): ícone e
/// texto num cartão de raio 16.
class PilaresNotice extends StatelessWidget {
  const PilaresNotice({
    required this.icon,
    required this.text,
    this.error = false,
    super.key,
  });

  final IconData icon;
  final String text;

  /// Vermelho do erro (#FCE4E1 e #BA1A1A); sem ele, o azul do aviso.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: error ? AppColors.errorSurface : colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppIconSize.standard,
            color: error ? colors.error : colors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O fim de um passo da compra (Concluída, Pendente, Restaurada): círculo
/// de 96 com o ícone, título, texto e os botões embaixo. Sem app bar.
class PilaresResultScreen extends StatelessWidget {
  const PilaresResultScreen({
    required this.icon,
    required this.title,
    required this.text,
    required this.actions,
    this.done = true,
    this.titleKey,
    this.textKey,
    this.onBack,
    super.key,
  });

  final IconData icon;
  final String title;
  final String text;
  final List<Widget> actions;

  /// Verde de concluído; sem ele, o amarelo de espera.
  final bool done;
  final Key? titleKey;
  final Key? textKey;

  /// O voltar do sistema (sem app bar).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack?.call();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppColors.successSurface
                          : AppColors.waitingSurface,
                    ),
                    child: Icon(
                      icon,
                      size: 56,
                      color: done
                          ? AppColors.successOnSurface
                          : AppColors.waitingOnSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    key: titleKey,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    text,
                    key: textKey,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: ActionsFooter(stacked: true, children: actions),
          ),
        ),
      ),
    );
  }
}

/// O selo em pílula (24 de altura, 12/16 peso 500): "Vitalício", "Mensal" e
/// "Demonstração" no cartão do curso; "Grátis" no Catálogo da demo.
class PilaresBadge extends StatelessWidget {
  const PilaresBadge({
    required this.text,
    this.background = AppColors.successSurface,
    this.foreground = AppColors.successOnSurface,
    super.key,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 24),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppShape.extraLarge),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
    ),
  );
}
