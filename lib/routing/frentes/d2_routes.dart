import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/account/account_invite_repository.dart';
import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/achievements/achievements_repository.dart';
import '../../data/repositories/rating/rating_repository.dart';
import '../../ui/my_progress/view_models/my_progress_cubit.dart';
import '../../ui/my_progress/widgets/my_progress_screen.dart';
import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/course_preview/course_preview_repository.dart';
import '../../data/repositories/profile/profile_repository.dart';
import '../../data/repositories/purchase/purchase_repository.dart';
import '../../data/repositories/training/course_training_repository.dart';
import '../../ui/course_unlocked/view_models/course_unlocked_cubit.dart';
import '../../ui/course_unlocked/widgets/course_unlocked_screen.dart';
import '../../ui/core/analytics/analytics_context.dart';
import '../../ui/core/motion/rota_que_abre.dart';
import '../../ui/course_preview/view_models/course_preview_cubit.dart';
import '../../ui/course_preview/widgets/course_band_preview_screen.dart';
import '../../ui/course_preview/widgets/course_details_screen.dart';
import '../../ui/course_preview/widgets/course_sale_screen.dart';
import '../../ui/pilares_sale/view_models/pilares_before_home_cubit.dart';
import '../../ui/pilares_sale/view_models/pilares_demo_end_cubit.dart';
import '../../ui/pilares_sale/view_models/pilares_prices_cubit.dart';
import '../../ui/pilares_sale/widgets/pilares_before_home_screen.dart';
import '../../ui/pilares_sale/widgets/pilares_demo_end_screen.dart';
import '../../ui/pilares_sale/widgets/pilares_plan_sale_screen.dart';
import '../../data/repositories/campaign/campaign_repository.dart';
import '../../ui/pilares_sale/widgets/pilares_subscription_ended_screen.dart';
import '../../ui/pilares_sale/view_models/pilares_offer_cubit.dart';
import '../../ui/pilares_sale/view_models/pilares_restore_cubit.dart';
import '../../ui/pilares_sale/widgets/pilares_offer_screen.dart';
import '../../ui/pilares_sale/widgets/pilares_purchase_result_screens.dart';
import '../../ui/pilares_sale/widgets/pilares_restore_screen.dart';
import '../route_names.dart';
import '../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../domain/models/course_grant.dart';
import '../../domain/use_cases/now.dart';
import '../../ui/gift_opening/view_models/gift_opening_cubit.dart';
import '../../ui/gift_opening/widgets/gift_opening_screen.dart';
import '../router.dart' show appRoute;

import '../../domain/models/pilares_access.dart';
import '../../domain/models/training/training_course.dart';
import '../routes.dart';

/// O id da [OrigemQueAbre] de onde a apresentação do Pilares (`/pilares`)
/// cresce na [RotaQueAbre] (H-ANI-04 da Venda).
const pilaresSaleOrigin = 'venda';

/// Telas novas da frente D2 (Venda + Conta + Ajustes, T85). A frente registra as rotas na
/// lista [d2Routes] com `appRoute(name: RouteNames.x, path: D2Paths.x, ...)`,
/// do `router.dart`, e navega por nome. Só esta frente mexe neste arquivo.
abstract final class D2Paths {
  /// Apresentação do Pilares (H-VEN-01); quem já comprou vai ao Sobre o
  /// Pilares.
  static const pilaresPresentation = '/pilares';

  /// A apresentação com a origem do analytics (`?origem=`).
  static String presentation({String? origin}) => Uri(
    path: pilaresPresentation,
    queryParameters: {'origem': ?origin},
  ).toString();

  /// Para quem é, a faixa (H-VEN-01).
  static const pilaresForWhom = '/pilares/for-whom';

  /// Sobre o Pilares, 3 abas (H-VEN-02).
  static const pilaresAbout = '/pilares/about';

  /// Sobre o Pilares; aberto pelo cartão de "Como funciona" (`de=ajuda`), a
  /// seta só fecha a tela.
  static String about({bool fromHelp = false}) => Uri(
    path: pilaresAbout,
    queryParameters: {if (fromHelp) 'de': 'ajuda'},
  ).toString();

  /// Fim da demonstração (H-VEN-04).
  static const pilaresDemoEnd = '/pilares/demo-end';

  /// Oferta vitalício/mensal (H-VEN-05).
  static const pilaresOffer = '/pilares/offer';

  /// Compra processando (H-VEN-07).
  static const pilaresPurchaseProcessing = '/pilares/purchase/processing';

  /// Compra concluída (H-VEN-07): o Curso liberado pela compra (H-R5-62).
  static const pilaresPurchaseDone = '/pilares/purchase/done';

  /// O Curso liberado pelo presente (H-R5-62).
  static const pilaresGiftDone = '/pilares/gift/done';

  /// O toque no push do presente (H-R5-63): abre o presente do curso
  /// `curso` dado à conta `uid` (`conta`: o e-mail dela mascarado).
  static const pilaresGiftOpening = '/pilares/gift/opening';
  static String giftOpening({
    required String course,
    String? uid,
    String? account,
  }) => Uri(
    path: pilaresGiftOpening,
    queryParameters: {'curso': course, 'uid': ?uid, 'conta': ?account},
  ).toString();

  /// Compra pendente (H-VEN-08).
  static const pilaresPurchasePending = '/pilares/purchase/pending';

  /// Restaurar compra (H-VEN-09).
  static const pilaresRestore = '/pilares/restore';

  /// "Comprou pelo site?", entrar com a conta da compra (H-VEN-08).
  static const pilaresRestoreSite = '/pilares/restore/site';

  /// Já tem o curso (H-VEN-09).
  static const pilaresOwned = '/pilares/owned';

  /// Assinatura encerrada (H-VEN-10).
  static const pilaresSubscriptionEnded = '/pilares/subscription-ended';

  /// Oferta antes do Início, variante A (H-VEN-15).
  static const pilaresBeforeHome = '/pilares/before-home';

  /// Plano como venda (H-VEN-14).
  static const pilaresPlan = '/pilares/plan';

  /// A venda do plano com a `origem` da oferta vista.
  static String plan({String? origin}) =>
      Uri(path: pilaresPlan, queryParameters: {'origem': ?origin}).toString();

  /// Esqueci a senha (H-CON-08).
  static const accountForgot = '/conta/esqueci-senha';

  /// Aceite dos Termos (H-CON-09).
  static const accountTerms = '/conta/termos';

  /// Convite por link, tela cheia com X (H-CON-18).
  static const accountInvite = '/conta/convite';

  /// Compra exige conta (H-CON-19).
  static const accountRequired = '/conta/exige';

  /// Perfil Lichess / Chess.com (H-CON-20).
  static const accountExternal = '/conta/externo/:site';

  /// "Seu progresso" (H-CON-03): a pílula do Início abre aqui.
  static const progress = '/progress';

  /// A oferta com o plano marcado (o vitalício, sem `plano`) e a origem
  /// do analytics.
  static String offer({
    PilaresPlan plan = PilaresPlan.lifetime,
    String? origin,
    String? code,
  }) => Uri(
    path: pilaresOffer,
    queryParameters: {
      if (plan == PilaresPlan.monthly) 'plano': plan.analytics,
      'origem': ?origin,
      'codigo': ?code,
    },
  ).toString();

  /// O plano da query da oferta (`plano=mensal`).
  static PilaresPlan planOf(String? value) =>
      value == PilaresPlan.monthly.analytics
      ? PilaresPlan.monthly
      : PilaresPlan.lifetime;

  /// "Seu objetivo" do Pilares (H-TRE-06, rota da D4).
  static String get pilaresGoal =>
      '${Routes.training(TrainingCourse.pilares.name)}/goal';
}

PilaresRestoreCubit _restoreCubit(BuildContext context) => PilaresRestoreCubit(
  purchases: context.read<PurchaseRepository>(),
  accounts: context.read<AccountRepository>(),
  analytics: context.analytics,
);

CoursePreviewCubit _previewCubit(BuildContext context, {String? origin}) =>
    CoursePreviewCubit(
      context.read<CoursePreviewRepository>(),
      context.read<CharacterRepository>(),
      analytics: context.analytics,
      origin: origin,
    )..load();

/// "Seu progresso" (H-CON-03): a rota e a pílula do rating no Início, que
/// abre por transformação de contêiner.
Widget progressDestination(BuildContext context) => BlocProvider(
  create: (context) => MyProgressCubit(
    rating: context.read<RatingRepository>(),
    achievements: context.read<AchievementsRepository>(),
    invite: context.read<AccountInviteRepository>(),
    accounts: context.read<AccountRepository>(),
    characters: context.read<CharacterRepository>(),
  )..load(),
  child: const MyProgressScreen(),
);

final List<RouteBase> d2Routes = [
  // "Seu progresso" (H-CON-03): rating, o convite da conta e as conquistas.
  appRoute(
    name: RouteNames.progress,
    path: D2Paths.progress,
    builder: (context, state) => progressDestination(context),
  ),
  // A apresentação (H-VEN-01): quem tem o curso vai direto ao Sobre o
  // Pilares; `origem` vai à oferta vista e à oferta.
  // H-ANI-04: cresce do cartão marcado com [pilaresSaleOrigin] (a chamada da
  // demo); de outra origem, entra em fade.
  GoRoute(
    name: RouteNames.pilaresPresentation,
    path: D2Paths.pilaresPresentation,
    redirect: (context, state) =>
        context.read<PurchaseRepository>().state.access.owns
        ? D2Paths.pilaresAbout
        : null,
    pageBuilder: (context, state) {
      final origin = state.uri.queryParameters['origem'] ?? 'perfil';
      return RotaQueAbre<void>(
        context: context,
        id: pilaresSaleOrigin,
        venda: true,
        key: state.pageKey,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => _previewCubit(context, origin: origin),
            ),
            BlocProvider(
              create: (context) => PilaresPricesCubit(
                purchases: context.read<PurchaseRepository>(),
              ),
            ),
          ],
          child: CourseSaleScreen(origin: origin),
        ),
      );
    },
  ),
  // Sobre o Pilares (H-VEN-02): o mesmo para demo e comprador.
  appRoute(
    name: RouteNames.pilaresAbout,
    path: D2Paths.pilaresAbout,
    builder: (context, state) => BlocProvider(
      create: _previewCubit,
      child: CourseDetailsScreen(
        fromHelp: state.uri.queryParameters['de'] == 'ajuda',
      ),
    ),
  ),
  appRoute(
    name: RouteNames.pilaresForWhom,
    path: D2Paths.pilaresForWhom,
    builder: (context, state) => BlocProvider(
      create: _previewCubit,
      child: const CourseBandPreviewScreen(),
    ),
  ),
  // A oferta (H-VEN-03): `plano=mensal` marca o mensal; `origem` vai ao
  // analytics; `codigo` é o do link com desconto (H-R5-66).
  appRoute(
    name: RouteNames.pilaresOffer,
    path: D2Paths.pilaresOffer,
    builder: (context, state) => BlocProvider(
      create: (context) => PilaresOfferCubit(
        purchases: context.read<PurchaseRepository>(),
        accounts: context.read<AccountRepository>(),
        analytics: context.analytics,
        plan: D2Paths.planOf(state.uri.queryParameters['plano']),
        origin: state.uri.queryParameters['origem'] ?? 'perfil',
        offerCode: state.uri.queryParameters['codigo'],
      ),
      child: const PilaresOfferScreen(),
    ),
  ),
  appRoute(
    name: RouteNames.pilaresPurchaseDone,
    path: D2Paths.pilaresPurchaseDone,
    builder: (context, state) => _courseUnlocked(CourseUnlockedOrigin.purchase),
  ),
  appRoute(
    name: RouteNames.pilaresGiftDone,
    path: D2Paths.pilaresGiftDone,
    builder: (context, state) => _courseUnlocked(CourseUnlockedOrigin.gift),
  ),
  appRoute(
    name: RouteNames.pilaresGiftOpening,
    path: D2Paths.pilaresGiftOpening,
    builder: (context, state) {
      final query = state.uri.queryParameters;
      final course = query['curso'] ?? pilaresCourseId;
      return BlocProvider(
        create: (context) => GiftOpeningCubit(
          accounts: context.read<AccountRepository>(),
          grants: context.read<CourseGrantsRepository>(),
          course: course,
          uid: query['uid'],
          now: context.read<Now>(),
        )..start(),
        child: GiftOpeningScreen(course: course, account: query['conta']),
      );
    },
  ),
  appRoute(
    name: RouteNames.pilaresPurchasePending,
    path: D2Paths.pilaresPurchasePending,
    builder: (context, state) => const PilaresPurchasePendingScreen(),
  ),
  appRoute(
    name: RouteNames.pilaresRestore,
    path: D2Paths.pilaresRestore,
    // Sem conta, "Restaurar compra" passa antes pela conta (H-VEN-08).
    redirect: (context, state) =>
        context.read<AccountRepository>().current == null
        ? Routes.accountEnterFrom(D2Paths.pilaresRestore)
        : null,
    builder: (context, state) => BlocProvider(
      create: _restoreCubit,
      child: const PilaresRestoreScreen(),
    ),
  ),
  // "Comprou pelo site?" usa o view model da Restaurar que a abriu; aberta
  // sozinha (fechou à força), um novo.
  appRoute(
    name: RouteNames.pilaresRestoreSite,
    path: D2Paths.pilaresRestoreSite,
    builder: (context, state) => switch (state.extra) {
      final PilaresRestoreCubit cubit => BlocProvider.value(
        value: cubit,
        child: const PilaresRestoreSiteScreen(),
      ),
      _ => BlocProvider(
        create: _restoreCubit,
        child: const PilaresRestoreSiteScreen(),
      ),
    },
  ),
  // O fim da demonstração (H-VEN-04): ao concluir a Lista de exercícios do
  // Capítulo 1.
  appRoute(
    name: RouteNames.pilaresDemoEnd,
    path: D2Paths.pilaresDemoEnd,
    builder: (context, state) => MultiBlocProvider(
      providers: [
        BlocProvider(
          // O evento demo_fim e a campanha valem já na abertura da tela.
          lazy: false,
          create: (context) => PilaresDemoEndCubit(
            analytics: context.analytics,
            campaigns: context.read<CampaignRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) =>
              PilaresPricesCubit(purchases: context.read<PurchaseRepository>()),
        ),
      ],
      child: const PilaresDemoEndScreen(),
    ),
  ),
  // A oferta antes do Início (H-VEN-15): tela cheia com X; quantas vezes
  // aparece é do Início (H-INI-14).
  appRoute(
    name: RouteNames.pilaresBeforeHome,
    path: D2Paths.pilaresBeforeHome,
    builder: (context, state) => BlocProvider(
      create: (context) => PilaresBeforeHomeCubit(
        analytics: context.analytics,
        characters: context.read<CharacterRepository>(),
      ),
      child: const PilaresBeforeHomeScreen(),
    ),
  ),
  appRoute(
    name: RouteNames.pilaresPlan,
    path: D2Paths.pilaresPlan,
    redirect: (context, state) =>
        context.read<PurchaseRepository>().state.access.owns
        ? Routes.training(TrainingCourse.pilares.name)
        : null,
    builder: (context, state) => MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (context) => CoursePreviewCubit(
            context.read<CoursePreviewRepository>(),
            context.read<CharacterRepository>(),
            analytics: context.analytics,
            origin: state.uri.queryParameters['origem'] ?? 'home',
            highlight: 'plano',
          )..load(),
        ),
        // O comparativo de custo (SaleCostCompare) lê os preços.
        BlocProvider(
          create: (context) =>
              PilaresPricesCubit(purchases: context.read<PurchaseRepository>()),
        ),
      ],
      child: const PilaresPlanSaleScreen(),
    ),
  ),
  appRoute(
    name: RouteNames.pilaresSubscriptionEnded,
    path: D2Paths.pilaresSubscriptionEnded,
    builder: (context, state) => BlocProvider(
      create: (context) =>
          PilaresPricesCubit(purchases: context.read<PurchaseRepository>()),
      child: const PilaresSubscriptionEndedScreen(),
    ),
  ),
];

Widget _courseUnlocked(CourseUnlockedOrigin origin) => BlocProvider(
  create: (context) => CourseUnlockedCubit(
    characters: context.read<CharacterRepository>(),
    profile: context.read<ProfileRepository>(),
    training: context.read<TrainingRepository>(),
  )..load(),
  child: CourseUnlockedScreen(origin: origin),
);
