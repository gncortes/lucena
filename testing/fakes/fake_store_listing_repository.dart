import 'package:lucena/data/repositories/store/store_listing_repository.dart';

/// Conta quantas vezes a página do app na Play foi aberta.
class FakeStoreListingRepository implements StoreListingRepository {
  int opened = 0;

  @override
  Future<void> open() async => opened++;
}
