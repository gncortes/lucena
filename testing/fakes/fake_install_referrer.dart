import 'package:lucena/data/repositories/deep_link/install_referrer_repository.dart';
import 'package:lucena/data/services/install_referrer_service.dart';

/// Uma Play que devolve o [value] que o teste mandar, contando as leituras.
class FakeInstallReferrerService implements InstallReferrerService {
  FakeInstallReferrerService([this.value]);

  String? value;
  int reads = 0;

  @override
  Future<String?> referrer() async {
    reads++;
    return value;
  }
}

/// O link pendente que o teste mandar, entregue uma vez só.
class FakeInstallReferrerRepository implements InstallReferrerRepository {
  FakeInstallReferrerRepository([this.link]);

  Uri? link;

  @override
  Future<Uri?> pendingLink() async {
    final pending = link;
    link = null;
    return pending;
  }
}
