import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../../data/repositories/treinador/treinador_preferencias.dart';
import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/treinador/treinador_regras.dart';

/// A casca do Treinador (abas Hoje, Partidas e Seu jogo): a conta ligada, as
/// partidas, o plano e o filtro da lista.
final class TreinadorState {
  const TreinadorState({
    this.carregando = true,
    this.falhou = false,
    this.conta,
    this.partidas = const [],
    this.acesso = false,
    this.filtro = FiltroPartidas.todos,
  });

  final bool carregando;

  /// A leitura das partidas falhou (sem rede na primeira vez, servidor fora).
  final bool falhou;
  final TreinadorConta? conta;

  /// Da mais recente para a mais antiga.
  final List<PartidaTreinador> partidas;
  final bool acesso;
  final FiltroPartidas filtro;

  bool get semConta => !carregando && conta == null;
  PartidaTreinador? get ultima => partidas.isEmpty ? null : partidas.first;
  List<PartidaTreinador> get filtradas => filtro.aplicar(partidas);

  TreinadorState copyWith({
    bool? carregando,
    bool? falhou,
    TreinadorConta? Function()? conta,
    List<PartidaTreinador>? partidas,
    bool? acesso,
    FiltroPartidas? filtro,
  }) => TreinadorState(
    carregando: carregando ?? this.carregando,
    falhou: falhou ?? this.falhou,
    conta: conta == null ? this.conta : conta(),
    partidas: partidas ?? this.partidas,
    acesso: acesso ?? this.acesso,
    filtro: filtro ?? this.filtro,
  );
}

final class TreinadorCubit extends Cubit<TreinadorState> {
  TreinadorCubit({
    required this.repository,
    required this.grants,
    required this.preferencias,
    required this.now,
  }) : super(const TreinadorState());

  final TreinadorRepository repository;
  final CourseGrantsRepository grants;
  final TreinadorPreferencias preferencias;
  final Now now;

  StreamSubscription<TreinadorConta?>? _conta;
  StreamSubscription<List<PartidaTreinador>>? _partidas;
  StreamSubscription<Object?>? _grants;
  bool _contaChegou = false;
  bool _partidasChegaram = false;
  bool _contaFalhou = false;
  bool _partidasFalharam = false;

  Future<void> load() async {
    final filtro = await preferencias.filtro();
    if (isClosed) return;
    emit(
      state.copyWith(
        filtro: filtro,
        acesso: TreinadorRegras.temAcesso(grants.current, now()),
      ),
    );
    _grants ??= grants.changes.listen((g) {
      if (!isClosed) {
        emit(state.copyWith(acesso: TreinadorRegras.temAcesso(g, now())));
      }
    });
    _ouvir();
  }

  void _ouvir() {
    _conta?.cancel();
    _partidas?.cancel();
    _contaChegou = false;
    _partidasChegaram = false;
    _contaFalhou = false;
    _partidasFalharam = false;
    _conta = repository.conta().listen((conta) {
      _contaChegou = true;
      _contaFalhou = false;
      if (isClosed) return;
      emit(
        state.copyWith(
          conta: () => conta,
          carregando: !_pronto && !_falhou,
          falhou: _falhou,
        ),
      );
    }, onError: (_) => _falhar(conta: true));
    _partidas = repository.partidas().listen((lista) {
      _partidasChegaram = true;
      _partidasFalharam = false;
      if (isClosed) return;
      emit(
        state.copyWith(
          partidas: lista,
          carregando: !_pronto && !_falhou,
          falhou: _falhou,
        ),
      );
    }, onError: (_) => _falhar(conta: false));
  }

  bool get _pronto => _contaChegou && _partidasChegaram;

  /// Uma das leituras falhou; a outra, vinda do cache, não apaga o erro.
  bool get _falhou => _contaFalhou || _partidasFalharam;

  void _falhar({required bool conta}) {
    if (conta) {
      _contaFalhou = true;
    } else {
      _partidasFalharam = true;
    }
    if (!isClosed) emit(state.copyWith(carregando: false, falhou: true));
  }

  /// "Tentar de novo" do erro de leitura.
  void tentarDeNovo() {
    emit(state.copyWith(carregando: true, falhou: false));
    _ouvir();
  }

  Future<void> filtrar(FiltroPartidas filtro) async {
    emit(state.copyWith(filtro: filtro));
    await preferencias.salvarFiltro(filtro);
  }

  Future<void> limparFiltros() => filtrar(FiltroPartidas.todos);

  @override
  Future<void> close() async {
    await _conta?.cancel();
    await _partidas?.cancel();
    await _grants?.cancel();
    await super.close();
  }
}
