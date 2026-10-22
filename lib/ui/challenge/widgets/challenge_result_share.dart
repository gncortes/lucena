import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/share/share_repository.dart';
import '../../../domain/models/challenge_result.dart';
import '../../core/l10n/l10n.dart';
import '../../core/share/share_button.dart';
import '../../settings/view_models/settings_cubit.dart';
import 'challenge_result_card.dart';
import 'challenge_result_ui.dart';

/// "Compartilhar" do fim do desafio: desenha a imagem do resultado fora da
/// tela, tira o PNG e abre a folha nativa do sistema com a imagem e o texto
/// com o link juntos. [opponent] é o nome que aparece na imagem
/// ("Percival · 1400"). Devolve se a pessoa escolheu para onde mandar.
Future<bool> shareChallengeResult(
  BuildContext context, {
  required ChallengeResult result,
  required String opponent,
}) async {
  final share = context.read<ShareRepository>();
  final settings = context.read<SettingsCubit>();
  final text = challengeResultShareText(context.l10n, result);
  final overlay = Overlay.of(context, rootOverlay: true);
  final boundary = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => BlocProvider<SettingsCubit>.value(
      value: settings,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -_offscreen,
            top: 0,
            width: _cardWidth,
            child: Material(
              type: MaterialType.transparency,
              child: RepaintBoundary(
                key: boundary,
                child: ChallengeResultCard(result: result, opponent: opponent),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  overlay.insert(entry);
  try {
    SchedulerBinding.instance.scheduleFrame();
    await SchedulerBinding.instance.endOfFrame;
    final png = await capturePng(boundary);
    if (png == null) return false;
    return await share.shareImage(png, name: 'lucena-desafio.png', text: text);
  } finally {
    entry.remove();
    entry.dispose();
  }
}

/// A largura da imagem e quanto ela fica fora da tela enquanto é tirada.
const _cardWidth = 360.0;
const _offscreen = 4000.0;
