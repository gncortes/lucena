import 'package:lucena/data/repositories/home/home_layout_repository.dart';
import 'package:lucena/domain/models/home_layout.dart';

class FakeHomeLayoutRepository implements HomeLayoutRepository {
  FakeHomeLayoutRepository({this.layout, this.seen = false});

  HomeLayout? layout;
  bool seen;

  @override
  Future<HomeLayout?> load() async => layout;

  @override
  Future<void> save(HomeLayout layout) async => this.layout = layout;

  @override
  Future<bool> noticeSeen() async => seen;

  @override
  Future<void> markNoticeSeen() async => seen = true;
}
