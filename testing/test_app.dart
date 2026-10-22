import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/alerts/region_prompt_repository.dart';
import 'package:lucena/data/repositories/crowd/crowd_repository.dart';
import 'package:lucena/data/repositories/share/share_repository.dart';
import 'package:lucena/data/repositories/survey/survey_repository.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/ui/wiki/view_models/wiki_links_cubit.dart';
import 'package:lucena/ui/core/widgets/web_pages.dart';

import 'fakes/fake_alerts_repository.dart';
import 'fakes/fake_crowd_repository.dart';
import 'fakes/fake_profile_repository.dart';
import 'fakes/fake_push_repository.dart';
import 'fakes/fake_share_repository.dart';
import 'fakes/fake_survey_repository.dart';
import 'fakes/fake_endgame_repositories.dart';
import 'fakes/fake_feedback_repositories.dart';
import 'fakes/fake_school_repositories.dart';

import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/repositories/feedback/feedback_repository.dart';
import 'package:lucena/data/repositories/review/review_repository.dart';
import 'package:lucena/data/repositories/school/school_progress_repository.dart';
import 'package:lucena/data/repositories/would_pay/would_pay_repository.dart';

import 'fakes/fake_voice_repository.dart';
import 'fakes/fake_wiki.dart';

/// Envolve um widget com tema e idiomas do app, para testes de widget.
class TestApp extends StatelessWidget {
  const TestApp({
    required this.child,
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.light,
    this.settingsCubit,
    this.profileCubit,
    this.alertsCubit,
    this.speechCubit,
    this.shareRepository,
    this.wikiLinksCubit,
    this.webPages,
    this.router,
    this.surveyRepository,
    this.regionPromptRepository,
    this.crowdRepository,
    this.wouldPayRepository,
    this.feedbackRepository,
    this.reviewRepository,
    this.schoolProgressRepository,
    this.endgameProgressRepository,
    super.key,
  });

  /// As páginas da Wikipedia dos nomes das falas. Sem ele, nenhuma: os nomes
  /// ficam como texto normal.
  final WikiLinksCubit? wikiLinksCubit;

  /// As páginas da web (a webview não existe nos testes). Sem elas, um falso
  /// com internet.
  final WebPages? webPages;

  final Widget child;
  final Locale locale;
  final ThemeMode themeMode;

  /// View model das telas de Configurações, quando a tela testada precisa dele.
  final SettingsCubit? settingsCubit;

  /// View model do perfil, quando a tela testada precisa dele.
  final ProfileCubit? profileCubit;

  /// Os avisos. Sem ele, um com as chaves de fábrica e o push permitido.
  final AlertsCubit? alertsCubit;

  /// A voz, quando o teste confere o que é falado. Sem ela, uma voz falsa
  /// desligada.
  final SpeechCubit? speechCubit;

  /// O compartilhar, quando o teste confere o que foi enviado. Sem ele, um
  /// falso que só guarda.
  final ShareRepository? shareRepository;

  /// O questionário "Sua opinião" (o convite e a tela). Sem ele, um falso
  /// vazio.
  final SurveyRepository? surveyRepository;

  /// A folha de estado e cidade da lista de finais. Sem ele, nunca pergunta.
  final RegionPromptRepository? regionPromptRepository;
  final CrowdRepository? crowdRepository;

  /// O "Você pagaria?" e o "Enviar feedback" (E1.26). Sem eles, o cartão
  /// nunca aparece e o envio vai para um falso.
  final WouldPayRepository? wouldPayRepository;
  final FeedbackRepository? feedbackRepository;
  final ReviewRepository? reviewRepository;

  /// O progresso que conta as aulas concluídas do convite.
  final SchoolProgressRepository? schoolProgressRepository;
  final EndgameProgressRepository? endgameProgressRepository;

  /// Com rotas: a tela testada navega (o [child] não é usado).
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    final settingsCubit = this.settingsCubit;
    final router = this.router;
    Widget build(AppAccent? accent) => router != null
        ? MaterialApp.router(
            theme: AppTheme.of(Brightness.light, accent: accent),
            darkTheme: AppTheme.of(Brightness.dark, accent: accent),
            themeMode: themeMode,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appSupportedLocales,
            routerConfig: router,
          )
        : MaterialApp(
            theme: AppTheme.of(Brightness.light, accent: accent),
            darkTheme: AppTheme.of(Brightness.dark, accent: accent),
            themeMode: themeMode,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appSupportedLocales,
            home: child,
          );
    // Com as preferências, a cor do app escolhida vale na hora, como no app.
    final app = settingsCubit == null
        ? build(null)
        : BlocBuilder<SettingsCubit, AppSettings?>(
            bloc: settingsCubit,
            builder: (context, settings) => build(settings?.accent),
          );
    final profileCubit = this.profileCubit;
    final providers = [
      if (settingsCubit != null)
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
      // Toda tela pode mostrar o apelido: sem perfil dado, o de fábrica.
      if (profileCubit != null)
        BlocProvider<ProfileCubit>.value(value: profileCubit)
      else
        BlocProvider<ProfileCubit>(
          create: (_) => ProfileCubit(FakeProfileRepository())..load(),
        ),
      if (alertsCubit case final alerts?)
        BlocProvider<AlertsCubit>.value(value: alerts)
      else
        BlocProvider<AlertsCubit>(
          create: (_) => AlertsCubit(
            alerts: FakeAlertsRepository(),
            push: FakePushRepository(allowed: true),
            profile: FakeProfileRepository(),
          )..load(),
        ),
      if (wikiLinksCubit case final wiki?)
        BlocProvider<WikiLinksCubit>.value(value: wiki),
      if (speechCubit case final speech?)
        BlocProvider<SpeechCubit>.value(value: speech)
      else
        BlocProvider<SpeechCubit>(
          create: (_) => SpeechCubit(FakeVoiceRepository())..load(),
        ),
    ];
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ShareRepository>.value(
          value: shareRepository ?? FakeShareRepository(),
        ),
        RepositoryProvider<WebPages>.value(value: webPages ?? FakeWebPages()),
        RepositoryProvider<SurveyRepository>.value(
          value: surveyRepository ?? FakeSurveyRepository(),
        ),
        RepositoryProvider<WouldPayRepository>.value(
          value: wouldPayRepository ?? const NoWouldPayRepository(),
        ),
        RepositoryProvider<FeedbackRepository>.value(
          value: feedbackRepository ?? FakeFeedbackRepository(),
        ),
        RepositoryProvider<ReviewRepository>.value(
          value: reviewRepository ?? FakeReviewRepository(),
        ),
        RepositoryProvider<SchoolProgressRepository>.value(
          value: schoolProgressRepository ?? FakeSchoolProgressRepository(),
        ),
        RepositoryProvider<EndgameProgressRepository>.value(
          value: endgameProgressRepository ?? FakeEndgameProgressRepository(),
        ),
        RepositoryProvider<RegionPromptRepository>.value(
          value: regionPromptRepository ?? const NoRegionPromptRepository(),
        ),
        RepositoryProvider<CrowdRepository>.value(
          value: crowdRepository ?? FakeCrowdRepository(),
        ),
      ],
      child: MultiBlocProvider(providers: providers, child: app),
    );
  }
}
