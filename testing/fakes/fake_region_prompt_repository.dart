import 'package:lucena/data/repositories/alerts/region_prompt_repository.dart';

/// A folha de estado e cidade só na memória: [asked] vira verdadeiro no
/// "Salvar" ou no "Agora não".
class FakeRegionPromptRepository implements RegionPromptRepository {
  FakeRegionPromptRepository({this.asked = false});

  bool asked;

  @override
  Future<bool> pending() async => !asked;

  @override
  Future<void> done() async => asked = true;
}
