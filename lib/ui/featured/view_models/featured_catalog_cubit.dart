import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/featured/featured_alerts_repository.dart';
import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../data/repositories/featured/featured_repository.dart';
import '../../../data/repositories/push/push_repository.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/models/load_failure.dart';
import '../../../domain/use_cases/featured_rules.dart';
import '../../../domain/use_cases/now.dart';

/// O que o sino acabou de fazer (o aviso que aparece por alguns segundos).
enum FeaturedBellNotice { turnedOn, turnedOff, permissionDenied }

/// A lista de finais em destaque: torneios em andamento, finais recentes e
/// finais históricos (H-DES-05), sem filtros.
class FeaturedCatalogState {
  final LoadFailure? failure;
  const FeaturedCatalogState({
    this.failure,
    this.ready = false,
    this.catalog = FeaturedCatalog.empty,
    this.ongoing = const [],
    this.recent = const [],
    this.historic = const [],
    this.bellOn = false,
    this.notice,
    this.noticeCount = 0,
  });

  final bool ready;
  final FeaturedCatalog catalog;

  /// Os torneios em andamento, no topo.
  final List<FeaturedTournament> ongoing;

  /// Publicados nos últimos 30 dias.
  final List<FeaturedItem> recent;

  /// O resto do acervo.
  final List<FeaturedItem> historic;

  /// O aviso geral de finais novos (o sino) está ligado.
  final bool bellOn;

  /// O último aviso do sino e quantos já saíram (para o mesmo aviso valer de
  /// novo).
  final FeaturedBellNotice? notice;
  final int noticeCount;

  /// Não há nenhum final no app.
  bool get isEmpty => ready && catalog.finals.isEmpty;

  /// Quantos finais o torneio [id] tem (o cartão do torneio).
  int finalsOf(String id) => [
    for (final each in catalog.finals)
      if (each.tournamentId == id) each,
  ].length;

  FeaturedCatalogState copyWith({bool? bellOn, FeaturedBellNotice? notice}) =>
      FeaturedCatalogState(
        ready: ready,
        catalog: catalog,
        ongoing: ongoing,
        recent: recent,
        historic: historic,
        bellOn: bellOn ?? this.bellOn,
        notice: notice ?? this.notice,
        noticeCount: notice == null ? noticeCount : noticeCount + 1,
      );
}

class FeaturedCatalogCubit extends Cubit<FeaturedCatalogState> {
  /// [country] é o país do perfil: os finais de torneios de lá sobem na
  /// ordem (E1.21); todos continuam na lista.
  FeaturedCatalogCubit({
    required this._featured,
    required this._progress,
    required this._alerts,
    required this._push,
    required this._now,
    this._country,
  }) : super(const FeaturedCatalogState());

  final FeaturedRepository _featured;
  final FeaturedProgressRepository _progress;
  final FeaturedAlertsRepository _alerts;
  final PushRepository _push;
  final Now _now;
  final String? _country;

  Future<void> load() async {
    _retryLoad = () => load();
    try {
      await _load();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) emit(FeaturedCatalogState(failure: LoadFailure.of(error)));
    }
  }

  Future<void> Function()? _retryLoad;
  Future<void> retryLoad() async {
    // O carregando de volta (H-DES-07): "Tentar novamente" recomeça.
    emit(const FeaturedCatalogState());
    await _retryLoad?.call();
  }

  Future<void> _load() async {
    final catalog = await _featured.catalog();
    final played = await _progress.played();
    final bell = await _bellSaved();
    if (isClosed) return;
    final now = _now();
    final items = FeaturedRules.items(
      catalog,
      played,
      now: now,
      country: _country,
    );
    emit(
      FeaturedCatalogState(
        ready: true,
        catalog: catalog,
        ongoing: FeaturedRules.ongoing(catalog, now: now),
        recent: FeaturedRules.recent(items, now),
        historic: FeaturedRules.historic(items, now),
        bellOn: bell,
        notice: state.notice,
        noticeCount: state.noticeCount,
      ),
    );
  }

  /// A preferência salva; sem ler, o sino abre desligado.
  Future<bool> _bellSaved() async {
    try {
      return await _alerts.enabled();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      return false;
    }
  }

  /// O sino: liga ou desliga o aviso geral. Ligar pede a permissão de
  /// notificação do sistema; negada, o sino fica desligado e o aviso oferece
  /// os ajustes.
  Future<void> toggleBell() async {
    if (!state.ready) return;
    if (state.bellOn) {
      emit(state.copyWith(bellOn: false, notice: FeaturedBellNotice.turnedOff));
      await _alerts.setEnabled(value: false);
      return;
    }
    if (_push.available && !await _push.permitted()) {
      if (!await _push.requestPermission()) {
        if (isClosed) return;
        emit(state.copyWith(notice: FeaturedBellNotice.permissionDenied));
        return;
      }
    }
    if (isClosed) return;
    emit(state.copyWith(bellOn: true, notice: FeaturedBellNotice.turnedOn));
    await _alerts.setEnabled(value: true);
  }

  /// Abre os ajustes de notificação do Lucena no sistema.
  Future<void> openSystemSettings() => _push.openSystemSettings();
}
