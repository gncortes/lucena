import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/glossary/glossary_repository.dart';
import '../../../domain/models/glossary_term.dart';
import '../../../domain/use_cases/glossary_search.dart';

/// O que a tela do Glossário mostra.
class GlossaryState {
  const GlossaryState({
    this.loading = true,
    this.terms = const [],
    this.query = '',
    this.online = true,
  });

  final bool loading;

  /// Todos os termos, por nome.
  final List<GlossaryTerm> terms;

  /// O texto da busca.
  final String query;

  /// Se a Wikipédia abre agora (conferido ao abrir um termo).
  final bool online;

  /// Os termos que a busca deixa ver.
  List<GlossaryTerm> get results => GlossarySearch.filter(terms, query);

  /// A busca não achou nada.
  bool get empty => !loading && query.trim().isNotEmpty && results.isEmpty;

  GlossaryTerm? termById(String id) {
    for (final term in terms) {
      if (term.id == id) return term;
    }
    return null;
  }

  GlossaryState copyWith({
    bool? loading,
    List<GlossaryTerm>? terms,
    String? query,
    bool? online,
  }) => GlossaryState(
    loading: loading ?? this.loading,
    terms: terms ?? this.terms,
    query: query ?? this.query,
    online: online ?? this.online,
  );
}

/// A tela do Glossário: lista, busca e se a Wikipédia abre agora.
class GlossaryCubit extends Cubit<GlossaryState> {
  GlossaryCubit(this._glossary, this._connectivity)
    : super(const GlossaryState());

  final GlossaryRepository _glossary;
  final ConnectivityRepository _connectivity;

  /// Carrega os termos, já com a busca [query] (o termo tocado na fala).
  Future<void> load({String query = ''}) async {
    emit(state.copyWith(query: query));
    final terms = await _glossary.terms();
    if (isClosed) return;
    emit(state.copyWith(loading: false, terms: terms));
  }

  void search(String query) => emit(state.copyWith(query: query));

  void clear() => emit(state.copyWith(query: ''));

  /// Confere a conexão antes de mostrar a folha do termo; devolve se abre.
  Future<bool> checkOnline() async {
    final online = await _connectivity.isOnline();
    if (!isClosed) emit(state.copyWith(online: online));
    return online;
  }
}
