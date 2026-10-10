import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/wiki/wiki_links_repository.dart';
import '../../../domain/models/wiki_links.dart';

/// As páginas da Wikipedia dos nomes das falas, para as telas sublinharem
/// os nomes que têm página.
class WikiLinksCubit extends Cubit<WikiLinks> {
  WikiLinksCubit(this._repository) : super(WikiLinks.empty);

  final WikiLinksRepository _repository;

  Future<void> load() async {
    final links = await _repository.links();
    if (!isClosed) emit(links);
  }
}
