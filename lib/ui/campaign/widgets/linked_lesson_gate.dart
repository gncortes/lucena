import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../account/widgets/account_invite_sheet.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../free_board/view_models/link_lesson_cubit.dart';

/// O link só de aula (`/aula/<id>`, T84) aberto sem conta: a aula só abre
/// com conta, então o convite vem antes. Google ou e-mail terminam na aula
/// (`Routes.afterAccount`), por cima desta tela; "Agora não", voltar do
/// e-mail sem entrar ou voltar da aula leva ao início.
class LinkedLessonGate extends StatefulWidget {
  const LinkedLessonGate({super.key});

  @override
  State<LinkedLessonGate> createState() => _LinkedLessonGateState();
}

class _LinkedLessonGateState extends State<LinkedLessonGate> {
  bool _asking = false;
  bool _answered = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_ask()));
  }

  Future<void> _ask() async {
    if (!mounted) return;
    final cubit = context.read<LinkLessonCubit>();
    final lesson = cubit.lesson;
    if (lesson == null) return _leave();
    _asking = true;
    await cubit.gateOpened();
    if (!mounted) return;
    final accepted = await showAccountInviteSheet(
      context,
      moment: accountInviteBeforeLinkLesson,
      text: context.l10n.accountInviteTextLinkLesson,
      from: Routes.linkedLessonEntry(lesson),
    );
    _asking = false;
    _answered = true;
    await cubit.inviteAnswered(accepted: accepted);
    if (!accepted) _leave();
  }

  void _leave() {
    if (_leaving || !mounted) return;
    _leaving = true;
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    // Voltou do e-mail sem entrar, ou da aula: a tela fica por cima de novo,
    // vai ao início.
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (_answered && !_asking && current) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) _leave();
      });
    }
    return const Scaffold(key: ChallengeKeys.lessonGate);
  }
}
