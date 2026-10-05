import 'package:lucena/data/repositories/pace/pace_repository.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/pace.dart';

class FakePaceRepository implements PaceRepository {
  static const sample = PaceTable(
    named: [
      NamedTimeControl(
        id: '1+0',
        time: TimeControl(initial: Duration(minutes: 1)),
      ),
      NamedTimeControl(
        id: '3+2',
        time: TimeControl(
          initial: Duration(minutes: 3),
          increment: Duration(seconds: 2),
        ),
      ),
      NamedTimeControl(
        id: '10+0',
        time: TimeControl(initial: Duration(minutes: 10)),
      ),
    ],
    profiles: {
      PaceCategory.bullet: PaceProfile(temperature: 0.3, thinkScale: 0.45),
      PaceCategory.rapid: PaceProfile(temperature: 0.5, thinkScale: 1),
    },
  );

  @override
  Future<PaceTable> table() async => sample;
}
