import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../../routing/route_names.dart';
import '../../../routing/abre_do_cartao.dart';
import '../../core/motion/segmentado_lucena.dart';
import '../../core/motion/rota_que_abre.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../training_goal/widgets/training_goal_card.dart';
import '../../core/widgets/course/course_navigation_bar.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/demo_goals.dart';
import '../../../domain/use_cases/training/training_goal_counts.dart';
import '../../../domain/use_cases/training/needs_opening_profile.dart';
import '../../core/keys/training_profile_keys.dart';

import 'package:flutter/material.dart';

import '../../../domain/models/load_failure.dart';
import 'training_load_error.dart';

import '../../core/theme/canvas_symbols.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/plan_event.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/keys/course_guide_keys.dart';
import '../../core/keys/training_keys.dart';
import '../../core/motion/abas_fade_through.dart';
import '../../core/motion/entrada_de_resultado.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/lista_em_ordem.dart';
import '../../core/motion/shimmer_conteudo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_button.dart';
import '../../core/widgets/course/course_continue_card.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/course/course_part_header.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/course_guide_cubit.dart';
import 'course_guide_copy.dart';
import 'licao_plan_band.dart';
import 'training_guide_tab.dart';
import '../../course_entry/widgets/course_content_states.dart';
import '../../pilares_sale/widgets/pilares_demo_catalog.dart';
import '../../pilares_sale/widgets/pilares_demo_tabs.dart';

class CourseGuideScreen extends StatelessWidget {
  const CourseGuideScreen({
    required this.onBack,
    required this.onPlan,
    required this.onHelp,
    required this.onWelcomeContinue,
    required this.onLesson,
    required this.onChapter,
    required this.goalsBuilder,
    required this.progressBuilder,
    this.onLevelTest,
    this.centerTitle = false,
    this.showHeaderActions = true,
    this.bodyOverride,
    this.titleOverride,
    this.onTabChanged,
    this.planEvent,
    this.now,
    this.onPlanBand,
    this.onDiploma,
    super.key,
  });
  final VoidCallback onBack, onPlan, onHelp, onWelcomeContinue;
  final VoidCallback? onLevelTest;

  /// O plano até um torneio (H-LIC-05): com ele a aba Lição mostra a faixa
  /// do plano; sem ele (sem plano, demo) a faixa não aparece.
  final PlanEvent? planEvent;
  final Now? now;
  final VoidCallback? onPlanBand;
  final VoidCallback? onDiploma;
  final ValueChanged<TrainingLesson> onLesson;
  final ValueChanged<String> onChapter;
  final WidgetBuilder goalsBuilder, progressBuilder;
  final bool centerTitle, showHeaderActions;
  final Widget? bodyOverride;
  final String? titleOverride;
  final ValueChanged<CourseGuideTab>? onTabChanged;

  /// A tela do quadro do canvas de cada aba da Escola (H-ANI-01): a entrada
  /// em ordem só acontece na primeira vez que a aba aparece na sessão.
  static String? _quadro(CourseGuideTab tab, bool aulaVista) => switch (tab) {
    CourseGuideTab.lesson =>
      aulaVista ? 'PropV1TreinoEscolaAula' : 'PropV1TreinoEscolaAulaBoasVindas',
    CourseGuideTab.goals => 'PropV1TreinoEscolaMetas',
    CourseGuideTab.stats => 'PropV1TreinoEscolaEstatisticas',
    CourseGuideTab.catalog => 'PropV1TreinoEscolaCatalogo',
    CourseGuideTab.guide => null,
  };

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<CourseGuideCubit, CourseGuideState>(
    listenWhen: (before, after) =>
        !before.failed && after.failed && after.training != null,
    listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.trainingExerciseSaveError)),
    ),
    builder: (context, state) {
      final cubit = context.read<CourseGuideCubit>();
      final config = cubit.config;
      final t = context.l10n;
      final training = state.training;
      // The School has no Guide tab (no goal or tournament plan there).
      final tabs = [
        for (final each in CourseGuideTab.values)
          if (each != CourseGuideTab.guide ||
              config.course != TrainingCourse.escola)
            each,
      ];
      final tab = training?.tab ?? CourseGuideTab.lesson;
      final title =
          titleOverride ??
          switch (tab) {
            CourseGuideTab.lesson => courseGuideCopy(context, config.titleKey),
            CourseGuideTab.goals => t.trainingGoalsTitle,
            CourseGuideTab.guide => t.treinoTabGuide,
            CourseGuideTab.stats => t.courseGuideTabProgress,
            CourseGuideTab.catalog => t.courseGuideTabCatalog,
          };
      if (!state.loading && state.failed && training == null) {
        return trainingLoadError(context, state.failure, cubit.load);
      }
      if (!state.loading &&
          !(state.resources?.lessons.any((lesson) => lesson.visible) ??
              false)) {
        return trainingLoadError(context, LoadFailure.unavailable, cubit.load);
      }
      return Scaffold(
        key: CourseGuideKeys.screen,
        appBar: LucenaAppBar(
          centerTitle: centerTitle,
          titleSpacing: 0,
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            key: CourseGuideKeys.back,
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(CanvasSymbols.arrowBack),
          ),
          // O Catálogo da demonstração (H-VEN-11) não tem plano nem ajuda.
          // Na demo, Catálogo e Estatísticas vêm sem as ações (H-VEN-11/12).
          actions:
              showHeaderActions &&
                  !_demoCatalog(context, tab) &&
                  !(tab == CourseGuideTab.stats &&
                      PilaresDemo.isActive(context, config.course))
              ? [
                  IconButton(
                    key: CourseGuideKeys.planAction,
                    onPressed: state.saving ? null : onPlan,
                    tooltip: t.courseGuidePlanAction,
                    icon: const Icon(CanvasSymbols.editCalendar),
                  ),
                  if (config.hasHelp)
                    IconButton(
                      key: CourseGuideKeys.helpAction,
                      onPressed: onHelp,
                      tooltip: t.courseGuideHelpAction,
                      icon: const Icon(CanvasSymbols.info),
                    ),
                ]
              : null,
        ),
        body: SafeArea(
          top: false,
          child: ShimmerConteudo(
            carregando: state.loading,
            esqueleto: const CourseDownloadSkeleton(),
            child: state.loading
                ? const SizedBox.shrink()
                // H-ANI-05: o corpo troca por fade through; a barra de
                // baixo e a app bar ficam.
                : _TabBody(screen: this, state: state, tab: tab),
          ),
        ),
        bottomNavigationBar: CourseNavigationBar(
          tabs: tabs,
          selectedIndex: tabs.indexOf(tab).clamp(0, tabs.length - 1),
          remaining: training == null
              ? 0
              : PilaresDemo.isActive(context, config.course)
              ? DemoGoals.counts(training).remaining
              : trainingGoalCounts(training).remaining,
          onDestinationSelected: state.saving
              ? null
              : (index) async {
                  final tab = tabs[index];
                  if (await cubit.selectTab(tab)) onTabChanged?.call(tab);
                },
        ),
      );
    },
  );
}

class _WelcomeTab extends StatelessWidget {
  const _WelcomeTab({required this.onContinue});
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) {
    final config = context.read<CourseGuideCubit>().config;
    final t = context.l10n;
    return EntradaEmCascata(
      montar: (itens) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          itens[0],
          const SizedBox(height: 12),
          itens[1],
          const SizedBox(height: 12),
          itens[2],
        ],
      ),
      itens: [
        ItemDaCascata.titulo(_WelcomeIntroCard(config: config)),
        ItemDaCascata.texto(_WelcomeTabsCard(config: config)),
        ItemDaCascata.botao(
          FilledButton(
            key: CourseGuideKeys.continueButton,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kButtonHeight),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: onContinue,
            child: Text(t.homeContinue),
          ),
        ),
      ],
    );
  }
}

/// O cartão de abertura da boas-vindas: o título e o texto do curso.
class _WelcomeIntroCard extends StatelessWidget {
  const _WelcomeIntroCard({required this.config});

  final TrainingCourseConfig config;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              courseGuideCopy(context, config.welcomeKeys[0]),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                height: 26 / 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              courseGuideCopy(context, config.welcomeKeys[1]),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// O cartão das abas da boas-vindas: o que cada aba mostra.
class _WelcomeTabsCard extends StatelessWidget {
  const _WelcomeTabsCard({required this.config});

  final TrainingCourseConfig config;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              t.courseGuideTabsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final (icon, title, body) in [
              (
                Icons.school_outlined,
                t.courseGuideTabLesson,
                config.welcomeKeys.length > 2
                    ? courseGuideCopy(context, config.welcomeKeys[2])
                    : t.courseGuideTabsLesson,
              ),
              (
                Icons.task_alt,
                t.courseGuideTabGoals,
                config.welcomeKeys.length > 3
                    ? courseGuideCopy(context, config.welcomeKeys[3])
                    : t.courseGuideTabsGoals,
              ),
              (
                Icons.insights,
                t.courseGuideTabProgress,
                config.welcomeKeys.length > 4
                    ? courseGuideCopy(context, config.welcomeKeys[4])
                    : t.courseGuideTabsProgress,
              ),
              (
                Icons.menu_book_outlined,
                t.courseGuideTabCatalog,
                config.welcomeKeys.length > 5
                    ? courseGuideCopy(context, config.welcomeKeys[5])
                    : t.courseGuideTabsCatalog,
              ),
            ])
              Row(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  Expanded(
                    child: Text(
                      t.courseGuideTabIntro(title, body),
                      style: Theme.of(context).textTheme.bodyMedium,
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

class _LessonTab extends StatelessWidget {
  const _LessonTab({
    required this.state,
    required this.onLesson,
    this.onDiploma,
  });
  final CourseGuideState state;
  final ValueChanged<TrainingLesson> onLesson;
  final VoidCallback? onDiploma;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CourseGuideCubit>();
    final lesson = state.nextLesson;
    if (lesson == null) {
      return _CompletedCourse(state: state, onDiploma: onDiploma);
    }
    final t = context.l10n;
    final modules =
        cubit.config.progressKind == TrainingProgressKind.modulesAndPieces;
    final index =
        state.resources!.lessons
            .where(
              (l) =>
                  l.visible &&
                  (modules
                      ? l.groupId == lesson.groupId
                      : l.partId == lesson.partId) &&
                  l.kind != TrainingLessonKind.test,
            )
            .toList()
            .indexOf(lesson) +
        1;
    final partLabel = t.trainingPartLabel(
      courseGuideRoman(
        state.resources!.lessons
                .where((l) => l.visible)
                .map((l) => l.partId)
                .toSet()
                .toList()
                .indexOf(lesson.partId) +
            1,
      ),
    );
    final sectionLabel = modules
        ? t.trainingModuleLabel(
            state.resources!.lessons
                    .where((l) => l.visible)
                    .map((l) => l.groupId)
                    .toSet()
                    .toList()
                    .indexOf(lesson.groupId) +
                1,
          )
        : partLabel;
    final needsProfile = needsOpeningProfile(
      state.training!,
      state.resources!,
      lesson,
    );
    final resumed = state.resumedLesson?.id == lesson.id;
    final resumeStage = state.lessonCheckpoint?.step ?? 0;
    final resumeStageLabel = switch (resumeStage) {
      0 => t.trainingResumeTheory,
      1 => t.trainingResumeDemo,
      _ => t.trainingResumePractice,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        TrainingGoalCard(
          course: cubit.config.course,
          place: TrainingGoalCardPlace.home,
        ),
        OrigemQueAbre(
          id: AbreDoCartao.daAula(lesson.id),
          child: CourseContinueCard(
            key: needsProfile ? TrainingProfileKeys.moment : null,
            label: needsProfile
                ? t.trainingProfileMomentLabel(partLabel)
                : resumed
                ? t.courseGuideResumeLabel(sectionLabel, resumeStageLabel)
                : lesson.kind == TrainingLessonKind.test
                ? sectionLabel
                : t.courseGuideLessonLabel(sectionLabel, index),
            title: needsProfile
                ? t.trainingProfileMomentTitle
                : trainingMasteryLessonTitle(context, lesson),
            summary: needsProfile
                ? t.trainingProfileMomentBody
                : resumed
                ? switch (resumeStage) {
                    0 => t.trainingResumeTheoryBody,
                    1 => t.trainingResumeDemoBody,
                    _ => t.trainingResumePracticeBody,
                  }
                : lesson.summary,
            buttonLabel: needsProfile
                ? t.trainingProfileChoose
                : resumed
                ? t.homeContinue
                : state.training!.completedLessons.isEmpty
                ? t.homeHeroStart
                : t.homeContinue,
            buttonKey: CourseGuideKeys.continueButton,
            onPressed: () => onLesson(lesson),
          ),
        ),
        const SizedBox(height: 12),
        _studyTips(context, cubit),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: CourseGuideKeys.seeCatalog,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(kButtonHeight),
          ),
          onPressed: () => cubit.selectTab(CourseGuideTab.catalog),
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(t.courseGuideSeeCatalog),
        ),
      ],
    );
  }
}

/// O curso concluído (ou à espera de publicação): o cartão, o primário e o
/// catálogo.
class _CompletedCourse extends StatelessWidget {
  const _CompletedCourse({required this.state, this.onDiploma});

  final CourseGuideState state;
  final VoidCallback? onDiploma;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CourseGuideCubit>();
    final t = context.l10n;
    if (state.awaitingPublication) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          const TrainingUnpublishedNotice(),
          const SizedBox(height: 12),
          FilledButton(
            key: TrainingKeys.completedPrimary,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kButtonHeight),
            ),
            onPressed: () => cubit.selectTab(CourseGuideTab.goals),
            child: Text(t.trainingViewGoals),
          ),
          const SizedBox(height: 12),
          _studyTips(context, cubit),
        ],
      );
    }
    final school =
        cubit.config.progressKind == TrainingProgressKind.modulesAndPieces;
    final cartao = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 16,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.trainingDayCorrect,
                ),
                Expanded(
                  child: Text(
                    school
                        ? t.trainingEscolaCompletedTitle
                        : t.trainingPilaresCompletedTitle,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Text(
              school
                  ? t.trainingEscolaCompletedBody
                  : t.trainingPilaresCompletedBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
    final primario = FilledButton(
      key: TrainingKeys.completedPrimary,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kButtonHeight),
      ),
      onPressed: school
          ? onDiploma
          : () => cubit.selectTab(CourseGuideTab.goals),
      child: Text(school ? t.schoolGraduationOpen : t.trainingViewGoals),
    );
    final catalogo = OutlinedButton.icon(
      key: TrainingKeys.completedCatalog,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kButtonHeight),
      ),
      icon: const Icon(Icons.menu_book),
      onPressed: () => cubit.selectTab(CourseGuideTab.catalog),
      label: Text(t.trainingViewCatalog),
    );
    if (school) {
      // Escola concluída (H-ANI-25): o resultado se monta em ordem.
      return EntradaDeResultado(
        id: 'escola-concluida',
        titulo: cartao,
        botoes: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [primario, catalogo],
        ),
        montar: (partes) => ListView(
          key: TrainingKeys.completedCourse,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [partes[0], const SizedBox(height: 12), partes[1]],
        ),
      );
    }
    return ListView(
      key: TrainingKeys.completedCourse,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        cartao,
        const SizedBox(height: 12),
        primario,
        const SizedBox(height: 12),
        catalogo,
      ],
    );
  }
}

/// Quem está na demonstração do Pilares vê o Catálogo da Venda (H-VEN-11).
bool _demoCatalog(
  BuildContext context,
  CourseGuideTab tab, [
  TrainingCourse? course,
]) =>
    tab == CourseGuideTab.catalog &&
    PilaresDemo.isActive(
      context,
      course ?? context.read<CourseGuideCubit>().config.course,
    );

class _CatalogTab extends StatefulWidget {
  const _CatalogTab({
    required this.state,
    required this.onChapter,
    required this.onLesson,
    this.onLevelTest,
  });
  final CourseGuideState state;
  final VoidCallback? onLevelTest;
  final ValueChanged<String> onChapter;
  final ValueChanged<TrainingLesson> onLesson;
  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  final expanded = <String>{};

  /// Filtro do catálogo (H-TRE-13): com plano, abre em "Meu plano"; a
  /// escolha do usuário fica salva no estado do treino.
  bool get _onlyPlan => widget.state.training?.catalogOnlyPlan ?? true;

  Set<String>? get _planIds {
    final plan = widget.state.training?.studyPlan;
    if (plan == null || plan.chapterIds.isEmpty) return null;
    return plan.chapterIds.toSet();
  }

  @override
  void initState() {
    super.initState();
    final first = widget.state.resources!.lessons
        .where((l) => l.visible && l.published)
        .firstOrNull;
    if (first != null) expanded.add(first.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<CourseGuideCubit>().config;
    if (_demoCatalog(context, CourseGuideTab.catalog, config.course)) {
      return PilaresDemoCatalog(
        lessons: widget.state.resources!.lessons,
        completed: widget.state.training!.completedLessons.keys.toSet(),
        nextLessonId: widget.state.nextLesson?.id,
        onLesson: widget.onLesson,
        onChapter: widget.onChapter,
      );
    }
    final planIds = _planIds;
    final filtered = _onlyPlan && planIds != null;
    final data = widget.state.resources!.lessons
        .where(
          (l) =>
              l.visible &&
              l.published &&
              (!filtered || planIds.contains(l.groupId)),
        )
        .toList();
    final completed = widget.state.training!.completedLessons;
    final modules =
        config.progressKind == TrainingProgressKind.modulesAndPieces;
    final groups = {for (final lesson in data) lesson.groupId: lesson.group};
    final linhas = <Widget>[
      _CatalogHeader(
        course: config.course,
        hasPlan: planIds != null,
        onlyPlan: filtered,
        onChanged: (value) => unawaited(
          context.read<CourseGuideCubit>().setCatalogOnlyPlan(value),
        ),
      ),
      for (final (index, group) in groups.entries.indexed) ...[
        if (!modules || expanded.contains(group.key)) ...[
          if (modules)
            Padding(
              key: CourseGuideKeys.module(group.key),
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                '${context.l10n.trainingModuleLabel(index + 1)} · ${group.value}'
                    .toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  height: 20 / 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            KeyedSubtree(
              key: CourseGuideKeys.chapter(group.key),
              child: CoursePartHeader(
                label: context.l10n.trainingChapterLabel(index + 1),
                title: group.value,
                titleWeight: FontWeight.w500,
                padding: EdgeInsets.fromLTRB(4, index == 0 ? 0 : 8, 4, 0),
              ),
            ),
          const SizedBox(height: 8),
          for (final lesson in data.where((l) => l.groupId == group.key))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              // H-ANI-04: a aula aberta pelo item cresce dele.
              child: OrigemQueAbre(
                id: AbreDoCartao.daAula(lesson.id),
                child: CourseItemTile(
                  key: CourseGuideKeys.chapterLesson(lesson.id),
                  state: completed.containsKey(lesson.id)
                      ? CourseItemState.approved
                      : widget.state.nextLesson?.id == lesson.id
                      ? modules
                            ? CourseItemState.next
                            : CourseItemState.started
                      : CourseItemState.open,
                  title: modules
                      ? lesson.title
                      : lesson.kind == TrainingLessonKind.test
                      ? context.l10n.trainingChapterTestTitle
                      : lesson.title,
                  summary: modules ? lesson.summary : null,
                  onTap: () => widget.onLesson(lesson),
                ),
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShape.card),
                side: const BorderSide(color: AppColors.cardOutline),
              ),
              child: ListTile(
                key: CourseGuideKeys.catalogPart(group.key),
                title: Text(
                  '${context.l10n.trainingModuleLabel(index + 1)} · ${group.value}',
                ),
                trailing: const Icon(
                  Icons.expand_more,
                  size: AppIconSize.standard,
                ),
                onTap: () => setState(() => expanded.add(group.key)),
              ),
            ),
          ),
      ],
    ];
    return ListaEmOrdem(
      animar: config.course == TrainingCourse.escola ? null : false,
      itens: linhas,
      montar: (itens) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: itens,
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.course,
    required this.hasPlan,
    required this.onlyPlan,
    required this.onChanged,
  });
  final TrainingCourse course;
  final bool hasPlan;
  final bool onlyPlan;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (hasPlan)
                Expanded(
                  child: SegmentadoLucena<bool>(
                    key: TrainingGoalKeys.catalogFilter,
                    valores: const [true, false],
                    selecionado: onlyPlan,
                    rotulo: (plano) => plano
                        ? Text(
                            t.treinoCatalogFilterPlan,
                            key: TrainingGoalKeys.catalogFilterPlan,
                          )
                        : Text(
                            t.treinoCatalogFilterAll,
                            key: TrainingGoalKeys.catalogFilterAll,
                          ),
                    aoEscolher: onChanged,
                  ),
                )
              else
                const Spacer(),
              IconButton(
                key: TrainingGoalKeys.catalogAbout,
                tooltip: t.treinoAboutPilares,
                icon: const Icon(Icons.article_outlined),
                onPressed: () => showLucenaSheet<void>(
                  context,
                  builder: (sheetContext) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.treinoAboutPilares,
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(t.treinoAboutBody),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasPlan && onlyPlan)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: TrainingGoalKeys.catalogChangePlan,
                onPressed: () => context.pushNamed(
                  RouteNames.trainingPlan,
                  pathParameters: {'course': course.name},
                  queryParameters: const {'replan': '1'},
                ),
                child: Text(t.treinoCatalogChangePlan),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _studyTips(BuildContext context, CourseGuideCubit cubit) {
  final t = context.l10n;
  return Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Text(
            t.courseGuideStudyTips,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final (i, prefix) in cubit.config.tipsKeys.indexed)
            Row(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        courseGuideCopy(context, '${prefix}Title'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        courseGuideCopy(context, '${prefix}Body'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

/// O corpo da aba escolhida, com troca por fade through (H-ANI-05).
class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.screen,
    required this.state,
    required this.tab,
  });

  final CourseGuideScreen screen;
  final CourseGuideState state;
  final CourseGuideTab tab;

  @override
  Widget build(BuildContext context) {
    final config = context.read<CourseGuideCubit>().config;
    final training = state.training;
    return AbasFadeThrough(
      child: KeyedSubtree(
        key: ValueKey(tab),
        child: _TabEntry(
          course: config.course,
          tab: tab,
          aulaVista: training?.onboardingDone == true,
          corpo:
              screen.bodyOverride ??
              switch (tab) {
                CourseGuideTab.lesson =>
                  training?.onboardingDone == true
                      ? _PlanBand(
                          screen: screen,
                          body: _LessonTab(
                            state: state,
                            onLesson: screen.onLesson,
                            onDiploma: screen.onDiploma,
                          ),
                        )
                      : _WelcomeTab(onContinue: screen.onWelcomeContinue),
                CourseGuideTab.goals => screen.goalsBuilder(context),
                CourseGuideTab.guide =>
                  PilaresDemo.isActive(context, config.course)
                      ? const PilaresDemoGuide()
                      : TrainingGuideTab(
                          key: CourseGuideKeys.guideTab,
                          course: config.course,
                        ),
                CourseGuideTab.stats => screen.progressBuilder(context),
                CourseGuideTab.catalog => _CatalogTab(
                  state: state,
                  onChapter: screen.onChapter,
                  onLesson: screen.onLesson,
                  onLevelTest: screen.onLevelTest,
                ),
              },
        ),
      ),
    );
  }
}

/// A faixa do plano até um torneio acima da aba Lição, quando há plano.
class _PlanBand extends StatelessWidget {
  const _PlanBand({required this.screen, required this.body});

  final CourseGuideScreen screen;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final event = screen.planEvent;
    final clock = screen.now;
    final open = screen.onPlanBand ?? screen.onPlan;
    if (event == null || clock == null) return body;
    return Column(
      children: [
        LicaoPlanBand(event: event, now: clock(), onTap: open),
        Expanded(child: body),
      ],
    );
  }
}

/// A entrada em ordem do quadro da aba, só na primeira vez que ela aparece.
class _TabEntry extends StatelessWidget {
  const _TabEntry({
    required this.course,
    required this.tab,
    required this.aulaVista,
    required this.corpo,
  });

  final TrainingCourse course;
  final CourseGuideTab tab;
  final bool aulaVista;
  final Widget corpo;

  @override
  Widget build(BuildContext context) {
    // Nos outros cursos só a aba Aula é da Lição (D1); as demais seguem o
    // Treino.
    final id = course == TrainingCourse.escola
        ? CourseGuideScreen._quadro(tab, aulaVista)
        : tab == CourseGuideTab.lesson
        ? (aulaVista ? 'PropV1TreinoAula' : 'PropV1TreinoAulaBoasVindas')
        : null;
    if (id == null) return corpo;
    return EntradaDaTela(key: ValueKey(id), id: id, child: corpo);
  }
}
