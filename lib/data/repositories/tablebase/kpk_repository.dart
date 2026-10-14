import '../../../domain/use_cases/kpk_oracle.dart';
import '../../services/asset_service.dart';

/// A tabela de rei e peão contra rei (T70).
abstract class KpkRepository {
  Future<KpkOracle> oracle();
}

/// Lê `assets/tablebase/kpk.bin` uma vez.
class AssetKpkRepository implements KpkRepository {
  AssetKpkRepository(this._assets);

  static const path = 'assets/tablebase/kpk.bin';

  final AssetService _assets;
  KpkOracle? _oracle;

  @override
  Future<KpkOracle> oracle() async =>
      _oracle ??= KpkTableOracle(await _assets.loadBytes(path));
}
