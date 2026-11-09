import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/links/link_repository.dart';

/// Abre [url] fora do app pelo repositório do [context]. Diz se abriu.
Future<bool> openExternalLink(BuildContext context, Uri url) =>
    context.read<LinkRepository>().open(url);
