import '../theme/app_button.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_colors.dart';

import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../lesson_script/widgets/script_page.dart';
import '../../lesson_script/widgets/script_speech.dart';
import '../theme/canvas_symbols.dart';
import 'teacher_speech.dart';

/// The shared CompBalao → CompFalaViktor → board → notation Canvas block.
class TrainingCanvasPage extends StatelessWidget {
  const TrainingCanvasPage({
    required this.pageKey,
    required this.teacher,
    required this.text,
    required this.boardBuilder,
    required this.notation,
    this.onOpen,
    this.headerAction,
    super.key,
  });
  final Key pageKey;
  final Character teacher;
  final String text;
  final Widget Function(double) boardBuilder;
  final Widget notation;
  final VoidCallback? onOpen;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) => ScriptPage(
    pageKey: pageKey,
    canvasLayout: true,
    speechBuilder: (metrics) =>
        ScriptSpeech(texts: [text], metrics: metrics, onOpen: onOpen),
    strip: SizedBox(
      height: ScriptPage.canvasStripHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: TeacherSpeech(
          part: TeacherSpeechPart.header,
          lessonV2: true,
          canvasHeader: true,
          headerAvatar: 40,
          teacher: teacher,
          text: text,
          speechContext: SpeechContext.teaching,
          headerAction: headerAction,
        ),
      ),
    ),
    boardBuilder: boardBuilder,
    list: notation,
  );
}

/// CompRodapeLicao's fixed 96 dp stage variant. Long secondary labels wrap
/// before the primary action; controls remain reachable at 360 dp.
class TrainingCanvasFooter extends StatelessWidget {
  const TrainingCanvasFooter({
    this.leading,
    this.navigation = const [],
    this.primary,
    this.secondary,
    super.key,
  });
  final Widget? leading, primary, secondary;
  final List<Widget> navigation;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 12,
        children: [
          ?leading,
          if (secondary == null) const Spacer(),
          ...navigation,
          if (secondary != null) Flexible(child: secondary!),
          ?primary,
        ],
      ),
    ),
  );

  static Widget button({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, kButtonHeightCompact)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: primary ? 22 : 16),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w500,
          letterSpacing: .1,
        ),
      ),
    );
    final text = Text(label, maxLines: 2, textAlign: TextAlign.center);
    return primary
        ? FilledButton(
            key: key,
            onPressed: onPressed,
            style: style,
            child: text,
          )
        : OutlinedButton(
            key: key,
            onPressed: onPressed,
            style: style,
            child: text,
          );
  }

  static Widget round({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool navigation = false,
  }) => SizedBox.square(
    dimension: navigation ? 48 : 56,
    child: IconButton(
      key: key,
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: AppIconSize.standard, fill: 0),
      style: IconButton.styleFrom(
        backgroundColor: navigation ? null : AppColors.trainingFabSurface,
        foregroundColor: navigation
            ? AppColors.trainingCanvasInk
            : AppColors.trainingAnalysisPrimary,
        disabledForegroundColor: AppColors.trainingDisabledInk,
        elevation: navigation ? 0 : 3,
        shadowColor: AppColors.trainingFabShadow,
      ),
    ),
  );

  static Widget hint({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
  }) => round(
    key: key,
    icon: CanvasSymbols.lightbulb,
    label: label,
    onPressed: onPressed,
  );
}
