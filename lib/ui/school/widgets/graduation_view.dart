import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../domain/models/character.dart';
import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/share/share_button.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../settings/widgets/about_screen.dart';
import '../view_models/lesson_cubit.dart';
import 'lesson_finished.dart';

// Os dois bispos, do catálogo: o primeiro jogo com relógio depois da
// formatura.
const _graduationFen = '8/8/8/4k3/8/7B/2K5/4B3 w - - 0 1';

/// A formatura da escola (T51, A4): o confete, o diploma com o apelido e a
/// data, o Viktor falando com o balão embaixo, o resumo do caminho e, fixas
/// embaixo, as ações (subir a Jornada e o primeiro jogo com relógio). O
/// convite do Lichess fica no fim, discreto.
class GraduationView extends StatefulWidget {
  const GraduationView({required this.state, super.key});

  final LessonState state;

  @override
  State<GraduationView> createState() => _GraduationViewState();
}

class _GraduationViewState extends State<GraduationView> {
  // O cartão que vira imagem ao compartilhar: diploma, caminho e a marca.
  final _card = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = widget.state;
    final viktor = state.viktor;
    final motion = AppMotion.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // O que vai na imagem: com o fundo da tela, para não sair
                    // transparente.
                    RepaintBoundary(
                      key: _card,
                      child: ColoredBox(
                        key: SchoolKeys.graduationCard,
                        color: theme.scaffoldBackgroundColor,
                        // A margem fica dentro: a imagem sai com respiro.
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.lessonGraduationTitle,
                                key: SchoolKeys.graduated,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _Diploma(state: state),
                              if (state.graduationPath.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                _Path(state: state),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              const _Brand(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShareButton(
                            key: SchoolKeys.graduationShare,
                            boundary: _card,
                            label: l10n.graduationShare,
                            fileName: 'lucena-diploma.png',
                            text: l10n.graduationShareText(
                              state.lessonCount,
                              AboutScreen.websiteFor(language).toString(),
                            ),
                          ),
                          if (viktor != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            TeacherSpeech(
                              speechContext: SpeechContext.teaching,
                              teacher: viktor,
                              text: state.speech,
                              emotion: Emotion.happy,
                              avatarSize: 56,
                              bubbleKey: LessonKeys.speech,
                              speaks: true,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          // Jogar contra pessoas: no fim, discreto.
                          const LichessInvite(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Actions(motion: motion),
          ],
        ),
        if (!motion.disabled)
          const Positioned.fill(
            child: IgnorePointer(
              child: Celebration(key: LessonKeys.celebration),
            ),
          ),
      ],
    );
  }
}

/// O caminho até a formatura: cada módulo da escola, feito, e por último a
/// prova final.
class _Path extends StatelessWidget {
  const _Path({required this.state});

  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final texts = state.texts;
    final modules = [
      for (final module in state.graduationPath)
        if (module.id != _finalModule) module,
    ];
    final finalLessons = [
      for (final module in state.graduationPath)
        if (module.id == _finalModule) ...module.lessons,
    ];
    Widget row(IconData icon, Color color, String title, {String? trailing}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
              if (trailing != null)
                Text(
                  trailing,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );
    return Card(
      key: SchoolKeys.graduationSummary,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.graduationPathTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final module in modules)
              row(
                Icons.check_circle_rounded,
                colors.primary,
                texts.moduleTitle(module.id),
                trailing: l10n.graduationModuleLessons(module.lessons.length),
              ),
            for (final lesson in finalLessons)
              row(
                Icons.check_circle_rounded,
                colors.primary,
                l10n.graduationFinalTest(texts.lessonTitle(lesson.id)),
              ),
          ],
        ),
      ),
    );
  }
}

// O módulo da prova final da escola.
const _finalModule = 'graduation';

/// A marca embaixo do cartão: quem vê a imagem nas redes sabe de onde veio.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mascot = theme.brightness == Brightness.dark
        ? 'assets/branding/mascot_dark.png'
        : 'assets/branding/mascot_light.png';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(mascot, width: 24, height: 24),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'Lucena · ${context.l10n.homeTagline}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// O diploma: desenrola de cima para baixo ao entrar.
class _Diploma extends StatelessWidget {
  const _Diploma({required this.state});

  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final nickname = context.select(
      (ProfileCubit cubit) => cubit.state?.nickname ?? '',
    );
    final finishedAt = state.finishedAt;
    final date = finishedAt == null
        ? null
        : DateFormat.yMMMMd(Localizations.localeOf(context).toString())
              .format(finishedAt);
    final card = Container(
      key: SchoolKeys.diploma,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: colors.primary, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppShape.medium),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 48,
              color: colors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.schoolTitle.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 2,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.graduationDiploma,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.graduationAwardedTo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              nickname.isEmpty ? l10n.profileNicknameDefault : nickname,
              key: SchoolKeys.diplomaName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.graduationFor(state.lessonCount),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _SignatureLine(
                    value: date ?? '',
                    label: l10n.graduationDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _SignatureLine(
                    value: state.viktor?.name ?? '',
                    label: l10n.graduationTeacher,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    // Desenrola de cima para baixo.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context).celebrate,
      curve: AppMotion.enter,
      builder: (context, value, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: value,
          child: child,
        ),
      ),
      child: card,
    );
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        // A data inteira, encolhida se precisar.
        OneLine(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        Divider(color: colors.outline, height: AppSpacing.md),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// As ações, fixas embaixo e sempre à vista: subir a Jornada (a principal) e,
/// logo acima, o primeiro jogo com relógio, com o que quer dizer o "+10".
class _Actions extends StatelessWidget {
  const _Actions({required this.motion});

  final MotionDurations motion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.speedrunPaceHelp,
                key: LessonKeys.clockHelp,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                key: LessonKeys.clockGameButton,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.av_timer_outlined),
                label: Text(l10n.lessonPlayWithClock),
                onPressed: () => context.go(
                  Routes.freeBoardAt(
                    _graduationFen,
                    view: 'white',
                    white: '900+10',
                    black: '900+10',
                    opponent: 'maia',
                    level: '1000',
                    user: 'white',
                    goal: 'win',
                    position: 'bishop.twoBishopsVsKing.0001',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                key: LessonKeys.journeyButton,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.hiking_rounded),
                label: Text(l10n.lessonToJourney),
                onPressed: () => context.go(Routes.journey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
