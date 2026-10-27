import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import 'link_lead_sheet.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../../domain/use_cases/link_lesson_rules.dart';
import '../../free_board/view_models/link_lesson_cubit.dart';

/// O link só de aula (`/aula/<id>`, T84) aberto sem conta: a aula só abre
/// com conta, então a folha da aula gratuita vem antes (a mesma do fim do
/// desafio, com a frase neutra). O cadastro ou o entrar terminam na aula
/// (`Routes.afterAccount`), por cima desta tela; "Agora não", voltar da
/// conta sem entrar ou voltar da aula leva ao início.
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
    await Future.wait([
      cubit.loadInfo(Localizations.localeOf(context).languageCode),
      cubit.gateOpened(),
    ]);
    if (!mounted) return;
    final choice = await showLinkLeadSheet(
      context,
      offer: LinkLessonOffer.none,
      hasAccount: false,
      info: cubit.state.info,
    );
    _asking = false;
    _answered = true;
    await cubit.inviteAnswered(accepted: choice != null);
    if (!mounted) return;
    final entry = Routes.linkedLessonEntry(lesson);
    switch (choice) {
      case null:
        _leave();
      case LinkLeadChoice.signIn:
        unawaited(context.push(Routes.accountEmailFrom(entry, signIn: true)));
      case LinkLeadChoice.create || LinkLeadChoice.lesson:
        unawaited(context.push(Routes.accountEnterFrom(entry)));
    }
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
    // Atrás do convite, o cabeçalho da aula (o título), não um fundo vazio.
    final title = context.select((LinkLessonCubit c) => c.state.info?.title);
    return Scaffold(
      key: ChallengeKeys.lessonGate,
      appBar: LucenaAppBar(
        title: Text(title ?? '', key: ChallengeKeys.lessonGateTitle),
      ),
    );
  }
}
