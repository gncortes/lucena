import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/glossary/glossary_repository.dart';
import '../../../data/repositories/school/lesson_script_repository.dart';
import '../../../data/repositories/lesson_video/lesson_video_repository.dart';
import '../../../data/repositories/lesson_video/video_interruptions_repository.dart';
import '../../../data/repositories/lesson_voice/lesson_voice_repository.dart';
import '../../../data/services/voice_audio_service.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/glossary_term.dart';
import '../../../domain/use_cases/now.dart';
import '../../../routing/routes.dart';
import '../../core/l10n/l10n.dart';
import '../../glossary/widgets/glossary_text.dart';
import '../view_models/lesson_video_cubit.dart';
import 'lesson_video_screen.dart';

/// A Teoria e a Demonstração de uma lição como aula em vídeo (L6): a tela da
/// lição mostra este widget nas etapas `ideia` e `demos`, e a Prática segue
/// na tela atual. O progresso da etapa fica no [LessonVideoCubit]; a etapa
/// da lição (retomada, fim, origem) continua com quem hospeda.
class LessonVideoStage extends StatelessWidget {
  const LessonVideoStage({
    required this.lessonId,
    required this.partId,
    required this.scriptPath,
    required this.stage,
    required this.language,
    required this.title,
    required this.onBack,
    required this.onNextStage,
    this.viktor,
    this.autoplay = true,
    super.key,
  });

  final String lessonId;
  final String partId;
  final String scriptPath;

  /// `ideia` (Teoria) ou `demos` (Demonstração).
  final String stage;
  final String language;
  final Future<String?>? title;
  final Character? viktor;

  /// `false` abre em 0:00 pausada (revisão de lição concluída, E3).
  final bool autoplay;

  /// A seta do topo: sai da lição salvando (E12).
  final VoidCallback onBack;

  /// "Próxima etapa" no fim do vídeo (E9, E10).
  final VoidCallback onNextStage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('video.$lessonId.$partId.$stage'),
      create: (_) => LessonVideoCubit(
        scripts: context.read<LessonScriptRepository>(),
        videos: context.read<LessonVideoRepository>(),
        interruptions: context.read<VideoInterruptionsRepository>(),
        now: context.read<Now>(),
        lessonId: lessonId,
        partId: partId,
        scriptPath: scriptPath,
        stage: stage,
        language: language,
        autoplay: autoplay,
        buttons: {
          'verResposta': context.l10n.lessonShowAnswer,
          'linhaPrincipal': context.l10n.lessonMainLine,
        },
        voice: context.read<LessonVoiceRepository?>(),
        audio: JustAudioVoiceAudioService.create,
      )..start(),
      child: FutureBuilder<(String?, List<GlossaryTerm>)>(
        future: (
          title ?? Future<String?>.value(),
          context.read<GlossaryRepository>().terms(),
        ).wait,
        // Livro do topo e termo sublinhado: pausa o vídeo e abre o Glossário
        // (filtrado pelo termo, com a folha/Wikipédia); na volta, continua
        // só se tocava (Vídeo 17, E6–E8).
        builder: (context, loaded) => LessonVideoScreen(
          title: loaded.data?.$1 ?? '',
          viktor: viktor,
          terms: loaded.data?.$2 ?? const [],
          onBack: onBack,
          onNextStage: onNextStage,
          onGlossary: () => context.read<LessonVideoCubit>().pauseWhile(
            () => context.push(Routes.glossary),
          ),
          onTerm: (term) => context.read<LessonVideoCubit>().pauseWhile(
            () => GlossaryText.open(context, term),
          ),
        ),
      ),
    );
  }
}
