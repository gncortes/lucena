import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/share/share_repository.dart';
import '../../domain/models/challenge_link.dart';
import '../../ui/challenge/view_models/challenge_sheet_cubit.dart';
import '../../ui/core/analytics/analytics_context.dart';

/// A folha "Mandar como desafio" para [link], com o compartilhar e as
/// estatísticas do [context].
ChallengeSheetCubit createChallengeSheetCubit(
  BuildContext context, {
  required ChallengeLink link,
}) => ChallengeSheetCubit(
  context.read<ShareRepository>(),
  link: link,
  analytics: context.analytics,
);

/// Compartilha a imagem [png] (chamada [name]) com o texto [text] pelo
/// repositório do [context], lido já na chamada. Devolve se foi enviada.
Future<bool> Function(Uint8List png, {required String name, String? text})
shareImageAction(BuildContext context) =>
    context.read<ShareRepository>().shareImage;
