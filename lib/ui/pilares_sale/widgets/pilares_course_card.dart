import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/links/link_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';
import '../../../domain/models/pilares_access.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../view_models/pilares_course_card_cubit.dart';

/// O curso no Perfil (H-VEN-04/09, quadros `PropV2CompraEntradaPerfil`,
/// `…JaTem`, `…JaTemMensal` e `…JaTemFalha`): o aviso de pagamento pendente
/// (quando houver) e o cartão com o selo e o que o aluno tem.
class PilaresCourseCard extends StatelessWidget {
  const PilaresCourseCard({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => PilaresCourseCardCubit(
      purchases: context.read<PurchaseRepository>(),
      links: context.read<LinkRepository>(),
    ),
    child: const _CourseCard(),
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final purchase = context.watch<PilaresCourseCardCubit>().state;
    final access = purchase.access;
    String fullDate(DateTime? date) =>
        date == null ? '' : DateFormat.yMMMMd(locale).format(date);
    final price = purchase.prices[PilaresPlan.monthly] ?? l10n.venRefMonthly;
    final grace = access.kind == PilaresAccessKind.monthlyGrace;
    final owns = access.owns;
    final badge = switch (access.kind) {
      PilaresAccessKind.lifetime => (
        l10n.venBadgeLifetime,
        AppColors.successSurface,
        AppColors.successOnSurface,
      ),
      PilaresAccessKind.monthlyActive || PilaresAccessKind.monthlyGrace => (
        l10n.venBadgeMonthly,
        AppColors.successSurface,
        AppColors.successOnSurface,
      ),
      _ => (
        l10n.venBadgeDemo,
        AppColors.waitingSurface,
        AppColors.waitingOnSurface,
      ),
    };
    final line = !owns
        ? l10n.venDemoText
        : access.monthly
        ? l10n.venSubscribedPlay(fullDate(access.since))
        : access.source == PilaresSource.site
        ? l10n.venBoughtSite(fullDate(access.since))
        : l10n.venBoughtPlay(fullDate(access.since));
    final subscription = access.kind == PilaresAccessKind.lifetime
        ? l10n.venLifetimeAccess
        : grace
        ? l10n.venMonthlyPending(price)
        : l10n.venMonthlyRenews(price, fullDate(access.renewsAt));
    final cubit = context.read<PilaresCourseCardCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.betweenCards,
      children: [
        if (grace)
          _GraceNotice(
            text: l10n.venGraceWarning(
              access.graceUntil == null
                  ? ''
                  : DateFormat.MMMMd(locale).format(access.graceUntil!),
            ),
          ),
        DecoratedBox(
          key: PurchaseKeys.courseCard,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppShape.card),
            border: Border.all(color: AppColors.cardOutline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.insideCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: owns ? AppSpacing.sm : AppSpacing.md,
              children: [
                _Header(badge: badge),
                Text(line, key: PurchaseKeys.courseLine, style: _body(context)),
                if (!owns)
                  FilledButton.tonal(
                    key: PurchaseKeys.courseSeeFull,
                    style: _button,
                    onPressed: () =>
                        context.push(D2Paths.offer(origin: 'perfil')),
                    child: Text(l10n.venSeeFull),
                  )
                else ...[
                  const Divider(height: AppSpacing.sm),
                  _Subscription(value: subscription),
                  const Divider(height: AppSpacing.sm),
                  if (access.kind == PilaresAccessKind.monthlyActive)
                    OutlinedButton.icon(
                      key: PurchaseKeys.courseManage,
                      style: _button,
                      onPressed: cubit.openSubscriptions,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l10n.venManage),
                    ),
                  if (grace)
                    FilledButton.icon(
                      key: PurchaseKeys.courseFixPayment,
                      style: _button,
                      onPressed: cubit.openSubscriptions,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l10n.venFixPayment),
                    ),
                  FilledButton.tonal(
                    key: PurchaseKeys.courseDetails,
                    style: _button,
                    onPressed: () => context.push(D2Paths.pilaresAbout),
                    child: Text(l10n.venDetails),
                  ),
                  TextButton.icon(
                    key: PurchaseKeys.courseRestore,
                    style: _button,
                    onPressed: () => context.push(D2Paths.pilaresRestore),
                    icon: const Icon(Icons.history),
                    label: Text(l10n.venRestore),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static final _button = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(
      Size.fromHeight(kButtonHeightCompact),
    ),
  );
}

TextStyle? _body(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium?.copyWith(
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    color: theme.colorScheme.onSurfaceVariant,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.badge});

  final (String, Color, Color) badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (text, background, foreground) = badge;
    return Row(
      spacing: AppSpacing.md,
      children: [
        Icon(
          Icons.menu_book,
          size: AppIconSize.standard,
          color: theme.colorScheme.primary,
        ),
        Expanded(
          child: Text(
            context.l10n.venCourseName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          key: PurchaseKeys.courseBadge,
          constraints: const BoxConstraints(minHeight: 24),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppShape.extraLarge),
          ),
          child: Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ),
      ],
    );
  }
}

class _Subscription extends StatelessWidget {
  const _Subscription({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: PurchaseKeys.courseSubscription,
      spacing: AppSpacing.lg,
      children: [
        Icon(
          Icons.workspace_premium,
          size: AppIconSize.standard,
          color: theme.colorScheme.primary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                context.l10n.venYourSubscription,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
              Text(value, style: _body(context)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GraceNotice extends StatelessWidget {
  const _GraceNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: PurchaseKeys.courseGrace,
    decoration: BoxDecoration(
      color: AppColors.waitingSurface,
      borderRadius: BorderRadius.circular(AppShape.card),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          const Icon(
            Icons.credit_card_off,
            size: AppIconSize.standard,
            color: AppColors.waitingOnSurface,
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: 0,
                color: AppColors.waitingInk,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
