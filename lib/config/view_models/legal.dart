import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/legal/legal_repository.dart';
import '../../domain/models/legal_document.dart';

/// Os Termos ou a Política embarcados em [language]; nulo sem texto nesse
/// idioma.
Future<LegalDocument?> loadLegalDocument(
  BuildContext context,
  LegalKind kind,
  String language,
) => context.read<LegalRepository>().load(kind, language);
