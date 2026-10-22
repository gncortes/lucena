import '../../../domain/models/crowd_stat.dart';
import '../../services/firebase/cloud_store_service.dart';

/// O "x% acertaram" do final do dia e dos finais em destaque (E1.24).
abstract class CrowdRepository {
  /// O do dia [day] (`aaaa-mm-dd`). Nulo: não saiu ou sem rede.
  Future<CrowdStat?> daily(String day);

  /// O do final em destaque [id]. Nulo: não saiu ou sem rede.
  Future<CrowdStat?> featured(String id);
}

/// Lê os campos que a função agendada grava em `daily/{dia}` e
/// `featured/{id}`. Sem rede, fica sem número.
class CloudCrowdRepository implements CrowdRepository {
  const CloudCrowdRepository(this._store);

  final CloudStoreService _store;

  @override
  Future<CrowdStat?> daily(String day) => _read('daily', day);

  @override
  Future<CrowdStat?> featured(String id) => _read('featured', id);

  Future<CrowdStat?> _read(String collection, String id) async {
    try {
      return CrowdStat.fromJson(await _store.readPublic(collection, id));
    } on CloudStoreException {
      return null;
    }
  }
}

/// Sem Firebase (F-Droid, testes): nunca há número.
class NoCrowdRepository implements CrowdRepository {
  const NoCrowdRepository();

  @override
  Future<CrowdStat?> daily(String day) async => null;

  @override
  Future<CrowdStat?> featured(String id) async => null;
}
