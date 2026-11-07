import 'package:lucena/data/repositories/feedback/feedback_draft_repository.dart';
import 'package:lucena/data/repositories/feedback/feedback_repository.dart';
import 'package:lucena/data/repositories/review/review_repository.dart';
import 'package:lucena/data/services/device_service.dart';
import 'package:lucena/data/services/firebase/cloud_store_service.dart';
import 'package:lucena/data/services/review_service.dart';
import 'package:lucena/domain/models/feedback_entry.dart';

/// Guarda o que foi mandado, sem nuvem.
class FakeFeedbackRepository implements FeedbackRepository {
  final sent = <FeedbackEntry>[];
  final levels = <String?>[];

  /// Com `true`, o envio falha (sem espaço, servidor recusou).
  bool fail = false;

  /// Com `true`, não há conta: o envio para com [FeedbackNeedsAccount].
  bool needsAccount = false;

  @override
  Future<bool> send(FeedbackEntry entry, {String? level}) async {
    if (needsAccount) throw const FeedbackNeedsAccount();
    if (fail) throw const CloudStoreException('permission-denied');
    if (FeedbackEntry.clip(entry.text).isEmpty) return false;
    sent.add(entry);
    levels.add(level);
    return true;
  }
}

/// O rascunho do feedback na memória.
class FakeFeedbackDraftRepository implements FeedbackDraftRepository {
  FakeFeedbackDraftRepository({this.draft});

  FeedbackDraft? draft;

  @override
  Future<FeedbackDraft?> load() async => draft;

  @override
  Future<void> save(FeedbackDraft draft) async => this.draft = draft;

  @override
  Future<void> clear() async => draft = null;
}

/// Conta as chamadas; [ask] decide se o pedido sai.
class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({this.ask = false});

  bool ask;
  int firstOpens = 0;
  int surveysSeen = 0;
  int setbacks = 0;
  int storeOpens = 0;

  /// (aulas, vitórias) de cada `maybeAsk`.
  final asks = <(int, int)>[];

  @override
  Future<void> markFirstOpen() async => firstOpens++;

  @override
  void noteSurveySeen() => surveysSeen++;

  @override
  void noteSetback() => setbacks++;

  @override
  Future<bool> maybeAsk({
    required int lessonsCompleted,
    required int endgamesWon,
  }) async {
    asks.add((lessonsCompleted, endgamesWon));
    return ask;
  }

  @override
  Future<int> requests() async => asks.length;

  @override
  Future<void> openStoreListing() async => storeOpens++;
}

class FakeReviewService implements ReviewService {
  FakeReviewService({this.available = true});

  bool available;
  int requests = 0;
  int storeOpens = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;

  @override
  Future<void> openStoreListing() async => storeOpens++;
}

class FakeDeviceService implements DeviceService {
  const FakeDeviceService({this.value = const DeviceModel()});

  final DeviceModel value;

  @override
  Future<DeviceModel> model() async => value;
}
